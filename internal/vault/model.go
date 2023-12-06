package vault

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"sync"

	"github.com/hashicorp/vault-client-go"
	vaultapi "github.com/hashicorp/vault/api"
	"github.com/mitchellh/mapstructure"
)

type Config struct {
	Redis     string `json:"redis"`
	SentryDsn string `json:"sentryDsn"`
}

type MetaConfig[T any] struct {
	lock      sync.Mutex
	loaded    bool
	readCount int
	key       string
	value     T
}

func CreateMetaConfig[T any](key string, value T) MetaConfig[T] {
	return MetaConfig[T]{
		loaded:    false,
		readCount: 0,
		key:       key,
		value:     value,
	}
}

func (ptr *MetaConfig[T]) Exists(ctx context.Context, client *vaultapi.Client, mountPath string) (bool, error) {
	res, err := client.Logical().ReadWithContext(ctx, fmt.Sprintf("%s/data/%s", mountPath, ptr.key))
	if err != nil {
		return false, err
	}
	if res == nil {
		return false, nil
	} else {
		return true, nil
	}
}

func (ptr *MetaConfig[T]) ShouldReload(cacheCycle int) bool {
	ptr.lock.Lock()
	defer ptr.lock.Unlock()
	return !ptr.loaded || ptr.readCount >= cacheCycle
}

func (ptr *MetaConfig[T]) Reload(ctx context.Context, client *vaultapi.Client, mountPath string) error {
	ptr.lock.Lock()
	defer ptr.lock.Unlock()
	res, err := client.KVv2(mountPath).Get(ctx, ptr.key)
	if err != nil {
		return err
	}

	var cfg T
	err = mapstructure.Decode(res.Data, &cfg)
	if err != nil {
		return err
	}
	ptr.value = cfg
	ptr.loaded = true
	return nil
}

func (ptr *MetaConfig[T]) ReloadCheckCycle(ctx context.Context, client *vaultapi.Client, mountPath string, cacheCycle int) error {
	if ptr.ShouldReload(cacheCycle) {
		return ptr.Reload(ctx, client, mountPath)
	}
	return nil
}

func (ptr *MetaConfig[T]) Get() T {
	ptr.lock.Lock()
	defer ptr.lock.Unlock()
	ptr.readCount++
	return ptr.value
}

func (ptr *MetaConfig[T]) GetPtr() *T {
	ptr.lock.Lock()
	defer ptr.lock.Unlock()
	ptr.readCount++
	return &ptr.value
}

func (ptr *MetaConfig[T]) Key() string {
	return ptr.key
}

type Secret[T any] struct {
	Data T `json:"data"`
}

func ParseSecret[T any](r io.ReadCloser) (*vault.Response[Secret[T]], error) {
	var buf bytes.Buffer
	_, err := buf.ReadFrom(r)
	if err != nil && err != io.EOF {
		return nil, err
	}
	if buf.Len() == 0 {
		return nil, fmt.Errorf("no secret available")
	}

	var res vault.Response[Secret[T]]
	err = json.Unmarshal(buf.Bytes(), &res)
	if err != nil {
		return nil, err
	}
	return &res, nil
}

func ReadRaw(ctx context.Context, client *vault.Client, path string) (io.ReadCloser, error) {
	res, err := client.ReadRaw(ctx, path)
	if err != nil {
		return nil, err
	}

	if res == nil {
		return nil, fmt.Errorf("unable to make request to vault")
	}

	if res.StatusCode == 404 {
		defer res.Body.Close()
		return nil, parseNotFound(res.Body)
	}

	if res.StatusCode != 200 {
		defer res.Body.Close()
		return nil, parseInvalid(res.Body)
	}

	return res.Body, nil
}

func parseNotFound(r io.Reader) error {
	var buf bytes.Buffer
	_, err := buf.ReadFrom(r)
	if err != nil {
		return err
	}
	return fmt.Errorf("secret from vault was not found: %s", buf.String())
}

func parseInvalid(r io.Reader) error {
	var buf bytes.Buffer
	_, err := buf.ReadFrom(r)
	if err != nil {
		return err
	}
	return fmt.Errorf("invalid response from vault: %s", buf.String())
}
