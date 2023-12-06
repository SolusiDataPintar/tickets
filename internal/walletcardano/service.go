package walletcardano

import (
	"context"
	"encoding/base64"
	"errors"
	"fmt"
	"log/slog"
	"strings"

	"github.com/SolusiDataPintar/tickets/internal/auth"
	"github.com/SolusiDataPintar/tickets/internal/env"
	"github.com/SolusiDataPintar/tickets/internal/vault"
	"github.com/SolusiDataPintar/tickets/internal/wallet"
	"github.com/echovl/cardano-go"
	"github.com/echovl/cardano-go/blockfrost"
	"github.com/echovl/cardano-go/crypto"
)

const (
	entropySizeInBits         = 160
	purposeIndex       uint32 = 1852 + 0x80000000
	coinTypeIndex      uint32 = 1815 + 0x80000000
	accountIndex       uint32 = 0x80000000
	externalChainIndex uint32 = 0x0
	stakingChainIndex  uint32 = 0x02
	walleIDAlphabet           = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
)

type Service struct {
	ctx      context.Context
	username string
	addrKeys []crypto.XPrvKey
	stakeKey crypto.XPrvKey
	rootKey  crypto.XPrvKey
	node     cardano.Node
	network  cardano.Network
}

type serviceOptions struct {
	ctx      context.Context
	username string
}

type ServiceOption func(*serviceOptions)

func WithContext(ctx context.Context) ServiceOption {
	return func(so *serviceOptions) {
		so.ctx = ctx
	}
}

func WithUsername(username string) ServiceOption {
	return func(so *serviceOptions) {
		so.username = username
	}
}

func NewService(opts ...ServiceOption) (*Service, error) {
	opt := serviceOptions{
		username: "",
		ctx:      context.Background(),
	}
	for _, v := range opts {
		v(&opt)
	}
	slog.Info("walletcardano.Service created", slog.String("useranme", opt.username))
	svc := new(Service)
	svc.ctx = opt.ctx
	svc.username = opt.username
	svc.network = cardano.Mainnet
	svc.node = blockfrost.NewNode(svc.network, env.LoadConfig().Cardano.Blockfrost)
	err := svc.load()
	if err != nil {
		if strings.HasPrefix(err.Error(), "404:") {
			wsvc, err := wallet.NewService(wallet.WithContext(svc.ctx), wallet.WithUsername(svc.username))
			if err != nil {
				return nil, err
			}

			rootKey := crypto.NewXPrvKeyFromEntropy(wsvc.Entropy(), "")
			accountKey := rootKey.Derive(purposeIndex).Derive(coinTypeIndex).Derive(accountIndex)
			chainKey := accountKey.Derive(externalChainIndex)
			stakeKey := accountKey.Derive(2).Derive(0)
			addr0Key := chainKey.Derive(0)
			svc.rootKey = chainKey
			svc.addrKeys = []crypto.XPrvKey{addr0Key}
			svc.stakeKey = stakeKey

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

func (ptr *Service) AddCardanoAddress() (cardano.Address, error) {
	index := uint32(len(ptr.addrKeys))
	newKey := ptr.rootKey.Derive(index)
	ptr.addrKeys = append(ptr.addrKeys, newKey)
	payment, err := cardano.NewKeyCredential(newKey.PubKey())
	if err != nil {
		return cardano.Address{}, err
	}
	res, err := cardano.NewEnterpriseAddress(ptr.network, payment)
	if err != nil {
		return cardano.Address{}, err
	}

	err = ptr.save()
	if err != nil {
		return cardano.Address{}, err
	}

	return res, nil
}

func (ptr *Service) Addresses() ([]cardano.Address, error) {
	res := make([]cardano.Address, len(ptr.addrKeys))
	for i, key := range ptr.addrKeys {
		payment, err := cardano.NewKeyCredential(key.PubKey())
		if err != nil {
			return nil, err
		}
		enterpriseAddr, err := cardano.NewEnterpriseAddress(ptr.network, payment)
		if err != nil {
			return nil, err
		}
		res[i] = enterpriseAddr
	}
	return res, nil
}

func (ptr *Service) findUtxos() ([]cardano.UTxO, error) {
	addrs, err := ptr.Addresses()
	if err != nil {
		return nil, err
	}
	walletUtxos := []cardano.UTxO{}
	for _, addr := range addrs {
		addrUtxos, err := ptr.node.UTxOs(addr)
		if err != nil {
			return nil, err
		}
		walletUtxos = append(walletUtxos, addrUtxos...)
	}
	return walletUtxos, nil
}

func (ptr *Service) balance() (*cardano.Value, error) {
	balance := cardano.NewValue(0)
	utxos, err := ptr.findUtxos()
	if err != nil {
		return nil, err
	}
	for _, utxo := range utxos {
		balance = balance.Add(utxo.Amount)
		for _, pid := range utxo.Amount.MultiAsset.Keys() {
			balance.MultiAsset = balance.MultiAsset.Set(pid, utxo.Amount.MultiAsset.Get(pid))
		}
	}
	return balance, nil
}

func (ptr *Service) transfer(in sendCardano) (*cardano.Hash32, error) {
	err := auth.NewService().ValidatePassword(ptr.ctx, ptr.username, in.Password)
	if err != nil {
		slog.Error("invalid credential to send cardano assets", slog.Any("err", err))
		return nil, newErrorInvalidSendCredential()
	}

	receiver, err := cardano.NewAddress(in.Receiver)
	if err != nil {
		return nil, err
	}

	pparams, err := ptr.node.ProtocolParams()
	if err != nil {
		return nil, err
	}

	isTransferAsset := len(in.Assets) > 0
	amount := cardano.NewValue(in.Coin)
	if amount.MultiAsset == nil {
		amount.MultiAsset = cardano.NewMultiAsset()
	} else {
		for _, v := range in.Assets {
			policyId, err := cardano.NewHash28(v.PolicyId)
			if err != nil {
				return nil, err
			}
			asset := cardano.NewAssets()
			asset = asset.Set(cardano.NewAssetName(v.AssetName), v.Qty)
			amount.MultiAsset = amount.MultiAsset.Set(cardano.NewPolicyIDFromHash(policyId), asset)
		}
	}

	utxos, err := ptr.findUtxos()
	if err != nil {
		return nil, err
	}

	currentBalance := cardano.NewValue(0)
	{
		balance, err := ptr.balance()
		if err != nil {
			return nil, err
		}
		if isTransferAsset {
			currentBalance = currentBalance.Add(balance)
		} else {
			currentBalance = currentBalance.Add(balance)
			for _, utxo := range utxos {
				if len(utxo.Amount.MultiAsset.Keys()) > 0 {
					currentBalance = currentBalance.Sub(utxo.Amount)
				}
			}
		}
	}

	if cmp := currentBalance.Cmp(amount); cmp == -1 || cmp == 2 {
		return nil, fmt.Errorf("not enough balance, %v > %v", amount, currentBalance)
	}

	// Find utxos that cover the amount to transfer
	pickedUtxos := []cardano.UTxO{}
	pickedUtxosAmount := cardano.NewValue(0)
	for _, utxo := range utxos {
		if isTransferAsset {
			if len(utxo.Amount.MultiAsset.Keys()) > 0 {
				for _, v := range in.Assets {
					policyIdHash, err := cardano.NewHash28(v.PolicyId)
					if err != nil {
						return nil, err
					}
					as := utxo.Amount.MultiAsset.Get(cardano.NewPolicyIDFromHash(policyIdHash))
					if as == nil {
						break
					}
					for _, av := range as.Keys() {
						if av == cardano.NewAssetName(v.AssetName) {
							pickedUtxos = append(pickedUtxos, utxo)
							pickedUtxosAmount = pickedUtxosAmount.Add(utxo.Amount)
						}
					}
				}
			} else {
				if pickedUtxosAmount.Cmp(amount) == 1 {
					continue
				}
				pickedUtxos = append(pickedUtxos, utxo)
				pickedUtxosAmount = pickedUtxosAmount.Add(utxo.Amount)
			}
		} else {
			if len(utxo.Amount.MultiAsset.Keys()) > 0 {
				continue
			}
			if pickedUtxosAmount.Cmp(amount) == 1 {
				break
			}
			pickedUtxos = append(pickedUtxos, utxo)
			pickedUtxosAmount = pickedUtxosAmount.Add(utxo.Amount)
		}
	}

	txBuilder := cardano.NewTxBuilder(pparams)

	keys := make(map[int]crypto.XPrvKey)
	for i, utxo := range pickedUtxos {
		for _, key := range ptr.addrKeys {
			payment, err := cardano.NewKeyCredential(key.PubKey())
			if err != nil {
				return nil, err
			}
			addr, err := cardano.NewEnterpriseAddress(ptr.network, payment)
			if err != nil {
				return nil, err
			}
			if addr.Bech32() == utxo.Spender.Bech32() {
				keys[i] = key
			}
		}
	}

	if len(keys) != len(pickedUtxos) {
		return nil, errors.New("not enough keys")
	}

	inputAmount := cardano.NewValue(0)
	for _, utxo := range pickedUtxos {
		txBuilder.AddInputs(&cardano.TxInput{TxHash: utxo.TxHash, Index: utxo.Index, Amount: utxo.Amount})
		inputAmount = inputAmount.Add(utxo.Amount)
	}
	txBuilder.AddOutputs(&cardano.TxOutput{Address: receiver, Amount: amount})

	tip, err := ptr.node.Tip()
	if err != nil {
		return nil, err
	}
	txBuilder.SetTTL(tip.Slot + 1200)
	for _, key := range keys {
		txBuilder.Sign(key.PrvKey())
	}
	changeAddress := pickedUtxos[0].Spender
	txBuilder.AddChangeIfNeeded(changeAddress)
	tx, err := txBuilder.Build()
	if err != nil {
		return nil, err
	}
	return ptr.node.SubmitTx(tx)
}

func (ptr *Service) save() error {
	addrKeys := []string{}
	for _, v := range ptr.addrKeys {
		addrKeys = append(addrKeys, base64.StdEncoding.EncodeToString(v))
	}

	err := vault.NewService().Write(ptr.ctx, "cardano/wallet/data/"+ptr.username, map[string]any{
		"addrKeys": addrKeys,
		"stakeKey": base64.StdEncoding.EncodeToString(ptr.stakeKey),
		"rootKey":  base64.StdEncoding.EncodeToString(ptr.rootKey),
		"network":  ptr.network.String(),
	})
	if err != nil {
		return err
	}
	return nil
}

func (ptr *Service) load() error {
	secret, err := vault.NewService().Read(ptr.ctx, "cardano/wallet/data/"+ptr.username)
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

	{ //load addrKeys
		if _, ok := data["addrKeys"]; !ok {
			return errors.New("wallet has no key addrKeys")
		}

		rawData, ok := data["addrKeys"].([]any)
		if !ok {
			return errors.New("wallet key addrKeys is not a []any")
		}

		keys := []crypto.XPrvKey{}
		for k, v := range rawData {
			dataStr, ok := v.(string)
			if !ok {
				return fmt.Errorf("wallet key addrKeys at index %d is not a string", k)
			}
			key, err := base64.StdEncoding.DecodeString(dataStr)
			if err != nil {
				return err
			}
			keys = append(keys, crypto.XPrvKey(key))
		}

		ptr.addrKeys = keys
	}

	{ //load stakeKey
		if _, ok := data["stakeKey"]; !ok {
			return errors.New("wallet has no key stakeKey")
		}

		rawData, ok := data["stakeKey"].(string)
		if !ok {
			return errors.New("wallet key stakeKey is not a string")
		}

		key, err := base64.StdEncoding.DecodeString(rawData)
		if err != nil {
			return err
		}

		ptr.stakeKey = crypto.XPrvKey(key)
	}

	{ //load rootKey
		if _, ok := data["rootKey"]; !ok {
			return errors.New("wallet has no key rootKey")
		}

		rawData, ok := data["rootKey"].(string)
		if !ok {
			return errors.New("wallet key rootKey is not a string")
		}

		key, err := base64.StdEncoding.DecodeString(rawData)
		if err != nil {
			return err
		}

		ptr.rootKey = crypto.XPrvKey(key)
	}

	{ //load network
		if _, ok := data["network"]; !ok {
			return errors.New("wallet has no key network")
		}

		rawData, ok := data["network"].(string)
		if !ok {
			return errors.New("wallet key network is not a string")
		}

		if rawData == cardano.Testnet.String() {
			ptr.network = cardano.Testnet
		} else {
			ptr.network = cardano.Mainnet
		}
	}
	return nil
}
