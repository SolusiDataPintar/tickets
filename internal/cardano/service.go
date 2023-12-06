package cardano

import (
	"context"
	"encoding/json"
	"log/slog"
	"os"
	"sync"

	"github.com/SolusiDataPintar/tickets/internal/cache"
	"github.com/cardano-community/koios-go-client/v3"
)

type Service struct{ client *koios.Client }

var (
	svc     *Service
	svcOnce sync.Once
)

func NewService() *Service {
	svcOnce.Do(func() {
		slog.Info("cardano.Service Created")
		svc = new(Service)
		svc.open()
	})
	return svc
}

func (ptr *Service) open() {
	api, err := koios.New()
	if err != nil {
		slog.Error("error creating koios client", slog.Any("err", err))
		os.Exit(1)
	}
	ptr.client = api
}

func (ptr *Service) GetClient() *koios.Client { return ptr.client }

func (ptr *Service) GetAddressInfo(ctx context.Context, addr string) (koios.AddressInfo, error) {
	res, err := ptr.client.GetAddressInfo(ctx, koios.Address(addr), nil)
	if err != nil {
		return koios.AddressInfo{}, err
	}

	if res.Data != nil {
		return *res.Data, nil
	} else {
		return koios.AddressInfo{}, nil
	}
}

func (ptr *Service) GetAssetInfo(ctx context.Context, policyId, assetId string) (AssetInfo, error) {
	cacheId := "cardano-asset-" + policyId + "-" + assetId
	data, err := cache.Client.Get(ctx, cacheId).Bytes()
	if err != nil {
		if cache.IsNotFound(err) {
			res, err := ptr.client.GetAssetInfo(ctx, koios.PolicyID(policyId), koios.AssetName(assetId), nil)
			if err != nil {
				return AssetInfo{}, err
			}
			if res.Error != nil {
				return AssetInfo{}, res.Error
			}
			if res.Data == nil {
				return AssetInfo{}, newErrorAssetNotFound(policyId, assetId)
			}
			newDataBytes, err := json.Marshal(res.Data)
			if err != nil {
				slog.Error("error marshall data", slog.Any("err", err))
			} else {
				err = cache.Client.Set(ctx, cacheId, newDataBytes, 0).Err()
				if err != nil {
					slog.Error("error caching cardano asset", slog.String("policyId", policyId), slog.String("assetId", assetId), slog.Any("err", err))
				}
			}
			return ParseAssetInfo(*res.Data), nil
		} else {
			return AssetInfo{}, nil
		}
	}
	var assetInfo koios.AssetInfo
	err = json.Unmarshal(data, &assetInfo)
	if err != nil {
		return AssetInfo{}, nil
	}
	return ParseAssetInfo(assetInfo), nil
}
