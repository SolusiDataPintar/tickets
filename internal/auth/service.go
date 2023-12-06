package auth

import (
	"context"
	"log/slog"
	"sync"

	"github.com/Nerzal/gocloak/v13"
	"github.com/golang-jwt/jwt/v4"
)

type ServiceOptions struct {
	url           string
	realm         string
	clientId      string
	clientSecret  string
	adminUsername string
	adminPassword string
}

type ServiceOption func(*ServiceOptions)

type Service struct {
	client        *gocloak.GoCloak
	realm         string
	clientId      string
	clientSecret  string
	adminUsername string
	adminPassword string
}

var (
	service     *Service
	serviceOnce sync.Once
)

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

func WithClientId(clientId string) ServiceOption {
	return func(so *ServiceOptions) {
		so.clientId = clientId
	}
}

func WithClientSecret(clientSecret string) ServiceOption {
	return func(so *ServiceOptions) {
		so.clientSecret = clientSecret
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

func NewService(opts ...ServiceOption) *Service {
	opt := ServiceOptions{
		url:           "",
		realm:         "",
		adminUsername: "",
		adminPassword: "",
	}
	for _, v := range opts {
		v(&opt)
	}
	serviceOnce.Do(func() {
		slog.Info("auth.Service Created")
		service = new(Service)
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
	if opt.clientId != "" {
		service.clientId = opt.clientId
	}
	if opt.clientSecret != "" {
		service.clientSecret = opt.clientSecret
	}
	return service
}

func (ptr *Service) ValidateSession(ctx context.Context, accessToken string) (jwt.RegisteredClaims, error) {
	claim := jwt.RegisteredClaims{}
	_, err := ptr.client.DecodeAccessTokenCustomClaims(ctx, accessToken, ptr.realm, &claim)
	return claim, err
}

func (ptr *Service) ValidatePassword(ctx context.Context, uid, password string) error {
	token, err := ptr.client.LoginAdmin(ctx, ptr.adminUsername, ptr.adminPassword, ptr.realm)
	if err != nil {
		return err
	}

	usr, err := ptr.client.GetUserByID(ctx, token.AccessToken, ptr.realm, uid)
	if err != nil {
		return err
	}

	_, err = ptr.client.Login(ctx, ptr.clientId, ptr.clientSecret, ptr.realm, *usr.Username, password)
	return err
}
