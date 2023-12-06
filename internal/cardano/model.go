package cardano

import (
	"encoding/json"

	"github.com/cardano-community/koios-go-client/v3"
	"github.com/shopspring/decimal"
)

type PaymentAddress struct {
	Bech32 string `json:"bech32"`
	Cred   string `json:"cred"`
}

type Asset struct {
	AssetName   string          `json:"assetName"`
	Fingerprint string          `json:"fingerprint"`
	PolicyID    string          `json:"policyId"`
	Quantity    decimal.Decimal `json:"quantity"`
}

func ParseAsset(in koios.Asset) Asset {
	return Asset{
		AssetName:   in.AssetName.String(),
		Fingerprint: in.Fingerprint.String(),
		PolicyID:    in.PolicyID.String(),
		Quantity:    in.Quantity,
	}
}

func ParseAssetList(in []koios.Asset) []Asset {
	res := []Asset{}
	for _, v := range in {
		res = append(res, ParseAsset(v))
	}
	return res
}

type UTxO struct {
	TxHash          string          `json:"txHash"`
	TxIndex         int             `json:"txIndex"`
	PaymentAddr     *PaymentAddress `json:"paymentAddress"`
	StakeAddress    *string         `json:"stakeAddress"`
	Value           decimal.Decimal `json:"value"`
	DatumHash       string          `json:"datumHash"`
	InlineDatum     any             `json:"inlineDatum"`
	ReferenceScript any             `json:"referenceScript"`
	AssetList       []Asset         `json:"assets"`
}

func ParseUTxo(in koios.UTxO) UTxO {
	var pa *PaymentAddress
	if in.PaymentAddr != nil {
		pa = &PaymentAddress{
			Bech32: in.PaymentAddr.Bech32.String(),
			Cred:   in.PaymentAddr.Cred.String(),
		}
	}
	var sa *string
	if in.StakeAddress != nil {
		ssa := in.StakeAddress.String()
		sa = &ssa
	}
	return UTxO{
		TxHash:          in.TxHash.String(),
		TxIndex:         in.TxIndex,
		PaymentAddr:     pa,
		StakeAddress:    sa,
		Value:           in.Value,
		DatumHash:       in.DatumHash.String(),
		InlineDatum:     in.InlineDatum,
		ReferenceScript: in.ReferenceScript,
		AssetList:       ParseAssetList(in.AssetList),
	}
}

func ParseUTxoList(in []koios.UTxO) []UTxO {
	res := []UTxO{}
	for _, v := range in {
		res = append(res, ParseUTxo(v))
	}
	return res
}

type AssetInfo struct {
	PolicyId          string           `json:"policyId"`
	AssetId           string           `json:"assetId"`
	AssetName         string           `json:"assetName"`
	Fingerprint       string           `json:"fingerprint"`
	MintingTxHash     string           `json:"mintingTxHash"`
	TotalSupply       decimal.Decimal  `json:"totalSupply"`
	MintCnt           int              `json:"mintCnt"`
	BurnCnt           int              `json:"burnCnt"`
	CreationTime      koios.Timestamp  `json:"creationTime"`
	MintingTxMetadata *json.RawMessage `json:"mintingTxMetaData"`
}

func ParseAssetInfo(in koios.AssetInfo) AssetInfo {
	return AssetInfo{
		PolicyId:          in.PolicyID.String(),
		AssetId:           in.AssetName.String(),
		AssetName:         in.AssetNameASCII,
		Fingerprint:       in.Fingerprint.String(),
		MintingTxHash:     in.MintingTxHash.String(),
		TotalSupply:       in.TotalSupply,
		MintCnt:           in.MintCnt,
		BurnCnt:           in.BurnCnt,
		CreationTime:      in.CreationTime,
		MintingTxMetadata: in.MintingTxMetadata,
	}
}
