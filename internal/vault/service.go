package vault

import (
	"context"
	"log/slog"
	"os"
	"sync"
	"time"

	"github.com/hashicorp/vault-client-go"
	"github.com/hashicorp/vault-client-go/schema"
)

type Service struct {
	client *vault.Client
	config *Config
}

var (
	svc     *Service
	svcOnce sync.Once
)

func NewService() *Service {
	svcOnce.Do(func() {
		slog.Info("vault.Service created")
		svc = new(Service)
	})
	return svc
}

func (ptr *Service) Open(address, token string, timeout time.Duration) {
	c, err := vault.New(
		vault.WithAddress(address),
		vault.WithRequestTimeout(timeout),
	)
	if err != nil {
		slog.Error("unable to connect to vault", slog.Any("err", err))
		os.Exit(1)
	}
	if err := c.SetToken(token); err != nil {
		slog.Error("unable to authenticate to vault", slog.Any("err", err))
		os.Exit(1)
	}
	ptr.client = c
}

func (ptr *Service) WriteSecret(ctx context.Context, path string, data map[string]interface{}) error {
	_, err := ptr.client.Secrets.KvV2Write(ctx, path, schema.KvV2WriteRequest{
		Data: data,
	})
	if err != nil {
		return err
	}
	return nil
}

func (ptr *Service) ReadSecret(ctx context.Context, path string) (map[string]interface{}, error) {
	res, err := ptr.client.Secrets.KvV2Read(ctx, path)
	if err != nil {
		return map[string]interface{}{}, err
	}
	return res.Data.Data, nil
}

func (ptr *Service) Write(ctx context.Context, path string, data map[string]any) error {
	_, err := ptr.client.Write(ctx, path, map[string]any{
		"data": data,
	})
	return err
}

func (ptr *Service) Read(ctx context.Context, path string) (map[string]interface{}, error) {
	res, err := ptr.client.Read(ctx, path)
	if err != nil {
		return map[string]interface{}{}, err
	}
	return res.Data, nil
}

func (ptr *Service) GetConfig(ctx context.Context) (*Config, error) {
	if ptr.config != nil {
		return ptr.config, nil
	}
	if ptr.config == nil {
		res, err := ReadRaw(ctx, ptr.client, "chainsmart/data/backendconfig")
		if err != nil {
			return nil, err
		}
		defer res.Close()

		secret, err := ParseSecret[Config](res)
		if err != nil {
			return nil, err
		}
		ptr.config = &secret.Data.Data
	}
	return ptr.config, nil
}
