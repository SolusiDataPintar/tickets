package wallet

import (
	"context"
	"encoding/base64"
	"log/slog"
	"strings"

	"github.com/SolusiDataPintar/tickets/internal/vault"
	"github.com/tyler-smith/go-bip39"
)

type Service struct {
	ctx      context.Context
	username string
	entropy  []byte
}

type options struct {
	ctx      context.Context
	username string
	password string
}

type ServiceOption func(*options)

func WithContext(ctx context.Context) ServiceOption {
	return func(so *options) {
		so.ctx = ctx
	}
}

func WithUsername(username string) ServiceOption {
	return func(so *options) {
		so.username = username
	}
}

func NewService(opts ...ServiceOption) (*Service, error) {
	opt := options{
		username: "",
		password: "",
		ctx:      context.Background(),
	}
	for _, v := range opts {
		v(&opt)
	}
	slog.Info("wallet.Service created", slog.String("username", opt.username))
	svc := new(Service)
	svc.ctx = opt.ctx
	svc.username = opt.username
	err := svc.load()
	if err != nil {
		if strings.HasPrefix(err.Error(), "404:") {
			svc.entropy, err = bip39.NewEntropy(256)
			if err != nil {
				return nil, err
			}

			err = svc.save()
			if err != nil {
				return nil, err
			}
			return svc, nil
		}
		return nil, err
	}
	return svc, nil
}

func (ptr *Service) Entropy() []byte { return ptr.entropy }

func (ptr *Service) save() error {
	sentropy := base64.StdEncoding.EncodeToString(ptr.entropy)
	err := vault.NewService().Write(ptr.ctx, "wallet/public/data/"+ptr.username, map[string]any{
		"entropy": sentropy,
	})
	if err != nil {
		return err
	}
	return nil
}

func (ptr *Service) load() error {
	secret, err := vault.NewService().Read(ptr.ctx, "wallet/public/data/"+ptr.username)
	if err != nil {
		return err
	}

	if _, ok := secret["data"]; !ok {
		return newErrorWalletNotFound()
	}

	data, ok := secret["data"].(map[string]interface{})
	if !ok {
		return newErrorWalletNotFound()
	}

	if _, ok := data["entropy"]; !ok {
		return newErrorWalletNotFound()
	}

	sentropy, ok := data["entropy"].(string)
	if !ok {
		return newErrorWalletNotFound()
	}

	entropy, err := base64.StdEncoding.DecodeString(sentropy)
	if err != nil {
		return err
	}
	ptr.entropy = entropy
	return nil
}
