package price

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"sync"
	"time"
)

type ServiceOption func(*ServiceOptions)

type ServiceOptions struct {
	url string
}

type Service struct {
	url             string
	refreshInterval time.Duration
	data            priceDeta
}

func WithUrl(url string) ServiceOption {
	return func(so *ServiceOptions) {
		so.url = url
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
		service.refreshInterval = 5 * time.Minute
		service.data = priceDeta{
			price:  Price{},
			expire: time.Time{},
		}
	})
	if opt.url != "" {
		service.url = opt.url
	}
	return service
}

func (ptr *Service) find(ctx context.Context) (Price, error) {
	err := ptr.refresh(ctx)
	if err != nil {
		return Price{}, err
	}
	return ptr.data.price, nil
}

func (ptr *Service) findOne(ctx context.Context, id, vs string) (PriceOne, error) {
	err := ptr.refresh(ctx)
	if err != nil {
		return PriceOne{}, err
	}

	rawBytes, err := json.Marshal(ptr.data.price)
	if err != nil {
		return PriceOne{}, err
	}

	priceMap := map[string]any{}
	err = json.Unmarshal(rawBytes, &priceMap)
	if err != nil {
		return PriceOne{}, err
	}

	cryptoMap := map[string]any{}
	{
		cryptoAny, ok := priceMap[id]
		if !ok {
			return PriceOne{}, newErrorPriceNotFound()
		}
		cryptoMap, ok = cryptoAny.(map[string]any)
		if !ok {
			return PriceOne{}, newErrorPriceNotFound()
		}
	}

	priceAny, ok := cryptoMap[vs]
	if !ok {
		return PriceOne{}, newErrorPriceNotFound()
	}

	price, ok := priceAny.(float64)
	if !ok {
		return PriceOne{}, newErrorPriceNotFound()
	}

	return PriceOne{
		Id:    id,
		Vs:    vs,
		Price: price,
	}, nil
}

func (ptr *Service) refresh(ctx context.Context) error {
	if !ptr.data.expire.IsZero() && time.Now().Before(ptr.data.expire) {
		return nil
	}
	url := fmt.Sprintf("%s/simple/price?ids=cardano&vs_currencies=IDR", ptr.url)
	response, err := http.Get(url)
	if err != nil {
		return err
	}

	if response.StatusCode != 200 {
		slog.Error("cannot load price", slog.Any("err", err))
		return newErrorPriceNotFound()
	}

	body, err := io.ReadAll(response.Body)
	if err != nil {
		return err
	}

	res := Price{}
	err = json.Unmarshal(body, &res)
	if err != nil {
		return err
	}
	ptr.data.price = res
	ptr.data.expire = time.Now().Add(ptr.refreshInterval)

	return nil
}
