package account

import (
	"github.com/LeonColt/ez"
)

func newErrorActivationNotFound() *ez.Error {
	return &ez.Error{
		Code:    ez.ErrorCodeNotFound,
		Message: "activation was not valid",
	}
}

func newErrorActivationExpire() *ez.Error {
	return &ez.Error{
		Code:    ez.ErrorCodeInvalidArgument,
		Message: "activation token is expire",
	}
}
func newErrorUserNotFound() *ez.Error {
	return &ez.Error{
		Code:    ez.ErrorCodeNotFound,
		Message: "user was not found",
	}
}
