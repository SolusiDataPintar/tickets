package account

import (
	"log/slog"
	"net/url"

	"github.com/LeonColt/echochamber"
	"github.com/SolusiDataPintar/tickets/internal/env"
	"github.com/labstack/echo/v4"
)

// Operations about Auths
type HttpController struct {
	echochamber.MixinController
	cfg env.Config
}

func NewHttpController(parent *echo.Group) *HttpController {
	slog.Info("account.Controller created")
	ctrl := new(HttpController)
	ctrl.cfg = env.LoadConfig()
	group := parent.Group("/account")
	group.POST("", ctrl.create)
	group.POST("/commit", ctrl.commit)
	group.Any("/activation/:email", ctrl.activation)
	return ctrl
}

// CreateAccount godoc
// Post CreateAccount
//
//	@ID			CreateAccount
//	@Summary	Create User Activation
//	@Tags		Account
//	@Accept		json
//	@Product	json
//	@Param		body	body		createActivationRequest	true	"request body to create activations"
//	@Success	200		{object}	[]createActivationResult
//	@Failure	400		{object}	echochamber.HTTPError
//	@Failure	500		{object}	echochamber.HTTPError
//	@Router		/account [post]
func (ptr *HttpController) create(ctx echo.Context) error {
	in := createActivationRequest{}
	if err := ptr.BindAndValidate(ctx, &in); err != nil {
		return ptr.HandleError(ctx, err)
	}

	res := []createActivationResult{}
	for _, v := range in.Emails {
		err := NewService().create(ctx.Request().Context(), v)
		if err != nil {
			res = append(res, createActivationResult{
				Success: false,
				Email:   v,
				Error:   err.Error(),
			})
		} else {
			res = append(res, createActivationResult{
				Success: true,
				Email:   v,
				Error:   "",
			})
		}
	}

	return ptr.OkJSON(ctx, res)
}

// CommitAccounT godoc
// Post CommitAccounT
//
//	@ID			CommitAccounT
//	@Summary	Activate user account so user can sign in
//	@Tags		Account
//	@Accept		json
//	@Product	json
//	@Param		body	body	commit	true	"request body to commit user activation request"
//	@Success	204
//	@Failure	400	{object}	echochamber.HTTPError
//	@Failure	403	{object}	echochamber.HTTPError
//	@Failure	404	{object}	echochamber.HTTPError
//	@Failure	500	{object}	echochamber.HTTPError
//	@Router		/account/commit [post]
func (ptr *HttpController) commit(ctx echo.Context) error {
	in := commit{}
	if err := ptr.BindAndValidate(ctx, &in); err != nil {
		return ptr.HandleError(ctx, err)
	}

	err := NewService().commit(ctx.Request().Context(), in)
	if err != nil {
		return ptr.HandleError(ctx, err)
	} else {
		return ptr.NoContent(ctx)
	}
}

// SendActivationEmail godoc
// Post SendActivationEmail
//
//	@ID			SendActivationEmail
//	@Summary	Send Activation Email
//	@Tags		Account
//	@Accept		json
//	@Product	json
//	@Param		email	path	string	true	"user email"
//	@Success	204
//	@Failure	400	{object}	echochamber.HTTPError
//	@Failure	500	{object}	echochamber.HTTPError
//	@Router		/account/activation/{email} [get]
func (ptr *HttpController) activation(ctx echo.Context) error {
	email, err := url.QueryUnescape(ctx.Param("email"))
	if err != nil {
		return ptr.BadRequestError(ctx, err)
	}
	NewService().sendMail(ctx.Request().Context(), email)
	return ptr.NoContent(ctx)
}
