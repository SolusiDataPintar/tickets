package account

import "time"

type createActivationRequest struct {
	Emails []string `json:"emails" form:"emails" query:"emails" xml:"email" validate:"required,dive,email"`
}

type createActivationResult struct {
	Success bool   `json:"success"`
	Email   string `json:"email"`
	Error   string `json:"error"`
}

type commit struct {
	Token     string `json:"token" form:"token" validate:"required"`
	FirstName string `json:"firstName" form:"firstName" validate:"required"`
	LastName  string `json:"lastName" form:"lastName" validate:"required"`
	Password  string `json:"password" form:"password" validate:"required"`
}

type activation struct {
	Email     string    `json:"email"`
	Expire    time.Time `json:"expire"`
	CreatedAt time.Time `json:"createdAt"`
}
