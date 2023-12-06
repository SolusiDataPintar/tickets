package walletcardano

import (
	"github.com/LeonColt/ez"
)

func newErrorWalletNotFound() *ez.Error {
	return &ez.Error{
		Code:    ez.ErrorCodeNotFound,
		Message: "wallet was not found",
	}
}

func newErrorInvalidSendCredential() *ez.Error {
	return &ez.Error{
		Code:    ez.ErrorCodeNotAuthorized,
		Message: "invalid credential to send cardano assets",
	}
}
