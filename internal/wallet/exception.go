package wallet

import (
	"github.com/LeonColt/ez"
)

func newErrorWalletNotFound() *ez.Error {
	return &ez.Error{
		Code:    ez.ErrorCodeNotFound,
		Message: "wallet was not found",
	}
}
