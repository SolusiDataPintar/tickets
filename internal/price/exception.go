package price

import (
	"github.com/LeonColt/ez"
)

func newErrorPriceNotFound() *ez.Error {
	return &ez.Error{
		Code:    ez.ErrorCodeNotFound,
		Message: "price is not found",
	}
}
