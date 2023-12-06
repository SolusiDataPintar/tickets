package account

import (
	"bytes"
	"context"
	"crypto/sha256"
	"crypto/tls"
	"embed"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	htmltemplate "html/template"
	"log/slog"
	"os"
	"sync"
	texttemplate "text/template"
	"time"

	"github.com/Nerzal/gocloak/v13"
	"github.com/SolusiDataPintar/tickets/internal/cache"
	"github.com/SolusiDataPintar/tickets/internal/common"
	"github.com/SolusiDataPintar/tickets/internal/env"
	"github.com/SolusiDataPintar/tickets/internal/wallet"
	"gopkg.in/gomail.v2"
)

//go:embed mail_template.html
var f embed.FS

const timeFormat = "02 Jan 2006 15:04:05 MST"

type ServiceOption func(*ServiceOptions)

type ServiceOptions struct {
	url                string
	realm              string
	adminUsername      string
	adminPassword      string
	linkUrlTemplate    string
	activationDuration *time.Duration
}

type Service struct {
	realm              string
	adminUsername      string
	adminPassword      string
	activationDuration time.Duration
	linkUrlTemplate    string
	loc                *time.Location
	client             *gocloak.GoCloak
	secret             []byte
}

func WithUrl(url string) ServiceOption {
	return func(so *ServiceOptions) {
		so.url = url
	}
}

func WithRealm(realm string) ServiceOption {
	return func(so *ServiceOptions) {
		so.realm = realm
	}
}

func WithAdminUsername(adminUsername string) ServiceOption {
	return func(so *ServiceOptions) {
		so.adminUsername = adminUsername
	}
}

func WithAdminPassword(adminPassword string) ServiceOption {
	return func(so *ServiceOptions) {
		so.adminPassword = adminPassword
	}
}

func WithActivationDuration(activationDuration time.Duration) ServiceOption {
	return func(so *ServiceOptions) {
		so.activationDuration = &activationDuration
	}
}

func WithLinkUrlTemplate(linkUrlTemplate string) ServiceOption {
	return func(so *ServiceOptions) {
		so.linkUrlTemplate = linkUrlTemplate
	}
}

var (
	service     *Service
	serviceOnce sync.Once
)

func NewService(opts ...ServiceOption) *Service {
	opt := ServiceOptions{}
	for _, v := range opts {
		v(&opt)
	}
	serviceOnce.Do(func() {
		slog.Info("activation.Service Created")
		service = new(Service)
		if opt.activationDuration == nil {
			slog.Error("activation duration must not be")
			os.Exit(1)
		}
		loc, err := time.LoadLocation("Asia/Jakarta")
		if err != nil {
			slog.Error("error load time location Asia/Jakarta", slog.Any("err", err))
			os.Exit(1)
		}
		service.secret, err = common.GenerateRandomBytes(32)
		if err != nil {
			slog.Error("error generating random secret", slog.Any("err", err))
			os.Exit(1)
		}
		service.loc = loc
	})
	if opt.url != "" {
		service.client = gocloak.NewClient(opt.url)
	}
	if opt.realm != "" {
		service.realm = opt.realm
	}
	if opt.adminUsername != "" {
		service.adminUsername = opt.adminUsername
	}
	if opt.adminPassword != "" {
		service.adminPassword = opt.adminPassword
	}
	if opt.activationDuration != nil {
		service.activationDuration = *opt.activationDuration
	}
	if opt.linkUrlTemplate != "" {
		service.linkUrlTemplate = opt.linkUrlTemplate
	}
	return service
}

func (ptr *Service) create(ctx context.Context, email string) error {
	exists, err := ptr.isUserExistsByEmail(ctx, email)
	if err != nil {
		return err
	}

	if !exists {
		token, err := ptr.client.LoginAdmin(ctx, ptr.adminUsername, ptr.adminPassword, ptr.realm)
		if err != nil {
			return err
		}

		user := gocloak.User{
			Email:    &email,
			Enabled:  gocloak.BoolP(true),
			Username: &email,
		}

		uid, err := ptr.client.CreateUser(ctx, token.AccessToken, ptr.realm, user)
		if err != nil {
			return err
		}

		wallet.NewService(wallet.WithContext(ctx), wallet.WithUsername(uid))
	}

	return nil
}

func (ptr *Service) sendMail(ctx context.Context, email string) {
	exists, err := ptr.isUserExistsByEmail(ctx, email)
	if err != nil {
		slog.Error("error check if user exists by email", slog.Any("err", err))
		return
	}

	if !exists {
		return
	}

	expiration := time.Now().Add(ptr.activationDuration)
	token, err := common.GenerateRandomString(128)
	if err != nil {
		slog.Error("error generate random string", slog.Any("err", err))
		return
	}

	hasher := sha256.New()
	_, err = hasher.Write([]byte(token))
	if err != nil {
		slog.Error("error hash token", slog.Any("err", err))
		return
	}
	hash := hex.EncodeToString(hasher.Sum(nil))

	data := activation{
		Email:     email,
		Expire:    expiration,
		CreatedAt: time.Now(),
	}
	dataJson, err := json.Marshal(data)
	if err != nil {
		slog.Error("error marshal activation data", slog.Any("err", err))
		return
	}
	cache.Client.Set(ctx, hash, base64.URLEncoding.EncodeToString(dataJson), ptr.activationDuration)

	link := ""
	{
		linkData := map[string]any{"token": token}
		linkTmpl, err := texttemplate.New(email + "-link").Parse(ptr.linkUrlTemplate)
		if err != nil {
			slog.Error("error parsing link template", slog.Any("err", err))
			return
		}

		var linkBuff bytes.Buffer
		err = linkTmpl.Execute(&linkBuff, linkData)
		if err != nil {
			slog.Error("error execute link template", slog.Any("err", err))
			return
		}

		link = linkBuff.String()
	}

	expirationStr := expiration.In(ptr.loc).Format(timeFormat)

	mailBody := ""
	{
		mailData := map[string]any{
			"activationUrl": link,
			"walletUrl":     "https://" + env.LoadConfig().Host,
			"expiration":    expirationStr,
		}
		mailRawTemplate, err := f.ReadFile("mail_template.html")
		if err != nil {
			slog.Error("error read email template", slog.Any("err", err))
			return
		}
		mailTmpl, err := htmltemplate.New(email + "-body").Parse(string(mailRawTemplate))
		if err != nil {
			slog.Error("error parsing email template", slog.Any("err", err))
			return
		}

		var mailBuff bytes.Buffer
		err = mailTmpl.Execute(&mailBuff, mailData)
		if err != nil {
			slog.Error("error execute email template", slog.Any("err", err))
			return
		}

		mailBody = mailBuff.String()
	}

	m := gomail.NewMessage()
	m.SetHeader("From", env.LoadConfig().Mail.Username)
	m.SetHeader("To", email)
	m.SetHeader("Subject", "Aktifasi Akun")
	m.SetBody("text/html", mailBody)
	d := gomail.NewDialer(env.LoadConfig().Mail.Host, env.LoadConfig().Mail.Port, env.LoadConfig().Mail.Username, env.LoadConfig().Mail.Password)
	d.TLSConfig = &tls.Config{InsecureSkipVerify: true}
	if err := d.DialAndSend(m); err != nil {
		slog.Error("error send email", slog.Any("err", err))
	}
}

func (ptr *Service) findOneByToken(ctx context.Context, token string) (activation, error) {
	hasher := sha256.New()
	_, err := hasher.Write([]byte(token))
	if err != nil {
		return activation{}, err
	}
	res := cache.Client.GetDel(ctx, hex.EncodeToString(hasher.Sum(nil)))
	if res.Err() != nil {
		if cache.IsNotFound(err) {
			return activation{}, newErrorActivationNotFound()
		}
		return activation{}, err
	}

	act := activation{}
	dataByte, err := base64.URLEncoding.DecodeString(res.Val())
	if err != nil {
		return activation{}, err
	}
	err = json.Unmarshal(dataByte, &act)
	if err != nil {
		return activation{}, err
	}
	return act, nil
}

func (ptr *Service) isUserExistsByEmail(ctx context.Context, email string) (bool, error) {
	usr, err := ptr.getUserByEmail(ctx, email)
	if err != nil {
		return false, err
	}

	return usr != nil, nil
}

func (ptr *Service) getUserByEmail(ctx context.Context, email string) (*gocloak.User, error) {
	token, err := ptr.client.LoginAdmin(ctx, ptr.adminUsername, ptr.adminPassword, ptr.realm)
	if err != nil {
		return nil, err
	}

	usrs, err := ptr.client.GetUsers(ctx, token.AccessToken, ptr.realm, gocloak.GetUsersParams{Email: &email})
	if err != nil {
		return nil, err
	}

	if len(usrs) > 0 {
		return usrs[0], nil
	} else {
		return nil, nil
	}
}

func (ptr *Service) commit(ctx context.Context, in commit) error {
	act, err := ptr.findOneByToken(ctx, in.Token)
	if err != nil {
		return err
	}

	if time.Now().After(act.Expire) {
		return newErrorActivationExpire()
	}

	usr, err := ptr.getUserByEmail(ctx, act.Email)
	if err != nil {
		return err
	}

	if usr == nil {
		return newErrorUserNotFound()
	}

	token, err := ptr.client.LoginAdmin(ctx, ptr.adminUsername, ptr.adminPassword, ptr.realm)
	if err != nil {
		return err
	}

	err = ptr.client.SetPassword(ctx, token.AccessToken, *usr.ID, ptr.realm, in.Password, false)
	if err != nil {
		return err
	}

	_, err = wallet.NewService(wallet.WithUsername(*usr.ID))
	if err != nil {
		return err
	}

	if usr.EmailVerified == nil || !*usr.EmailVerified {
		err = ptr.client.SendVerifyEmail(ctx, token.AccessToken, *usr.ID, ptr.realm)
		if err != nil {
			slog.Error("send verify email failed", slog.Any("err", err))
		}
	}

	return nil
}
