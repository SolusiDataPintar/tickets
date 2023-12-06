package walletcardano

import (
	chainsmartcardano "github.com/SolusiDataPintar/tickets/internal/cardano"
	"github.com/cardano-community/koios-go-client/v3"
	"github.com/echovl/cardano-go"
)

type addressInfo struct {
	Address       string                   `json:"address"`
	Balance       int64                    `json:"balance"`
	StakeAddress  string                   `json:"stakeAddress"`
	ScriptAddress bool                     `json:"scriptAddress"`
	UTxOs         []chainsmartcardano.UTxO `json:"utxoSets"`
}

func parseAddressInfo(in koios.AddressInfo) addressInfo {
	return addressInfo{
		Address:       string(in.Address),
		Balance:       in.Balance.IntPart(),
		StakeAddress:  string(in.StakeAddress),
		ScriptAddress: in.ScriptAddress,
		UTxOs:         chainsmartcardano.ParseUTxoList(in.UTxOs),
	}
}

type sendCardano struct {
	Password string `json:"password"`
	Receiver string `json:"receiver"`
	cardanoBalance
}

type balance struct {
	Cardano cardanoBalance `json:"cardano"`
}

type cardanoAsset struct {
	PolicyId  string         `json:"policyId"`
	AssetName string         `json:"assetName"`
	Qty       cardano.BigNum `json:"qty"`
}

type cardanoBalance struct {
	Coin   cardano.Coin   `json:"coin"`
	Assets []cardanoAsset `json:"assets"`
}
