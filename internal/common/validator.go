package common

import (
	"github.com/go-playground/validator/v10"
)

func NewValidator() *Validator {
	val := validator.New()
	return &Validator{
		validator: val,
	}
}

type Validator struct {
	validator *validator.Validate
}

func (validator *Validator) Validate(i interface{}) error {
	return validator.validator.Struct(i)
}
