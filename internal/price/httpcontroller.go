package price

import (
	"log/slog"

	"github.com/LeonColt/echochamber"
	"github.com/labstack/echo/v4"
)

type HttpController struct{ echochamber.MixinController }

func NewHttpController(parent *echo.Group) *HttpController {
	slog.Info("price.HttpController Created")
	ctrl := new(HttpController)
	group := parent.Group("/price")
	group.GET("", ctrl.find)
	group.GET("/:id/:vs", ctrl.findOne)
	return ctrl
}

// FindPrice godoc
//
//	@ID			FindPrice
//	@Sumarry	Get Price List
//	@Tags		Price
//	@Security	ApiKeyAuth
//	@Accept		json
//	@Product	json
//	@Success	200	{object}	Price
//	@Failure	500	{object}	echochamber.HTTPError
//	@Router		/price [get]
func (ptr *HttpController) find(ctx echo.Context) error {
	res, err := NewService().find(ctx.Request().Context())
	if err != nil {
		return ptr.HandleError(ctx, err)
	}
	return ptr.OkJSON(ctx, res)
}

// FindOnePrice godoc
//
//	@ID			FindOnePrice
//	@Sumarry	Find One Price
//	@Tags		Price
//	@Security	ApiKeyAuth
//	@Accept		json
//	@Product	json
//	@Param		policyId	path		string	true	"cardano nft policy id"
//	@Param		PriceId		path		string	true	"cardano nft Price id"
//	@Success	200			{object}	PriceOne
//	@Failure	404			{object}	echochamber.HTTPError
//	@Failure	500			{object}	echochamber.HTTPError
//	@Router		/price/{id}/{vs} [get]
func (ptr *HttpController) findOne(ctx echo.Context) error {
	id := ctx.Param("id")
	vs := ctx.Param("vs")

	res, err := NewService().findOne(ctx.Request().Context(), id, vs)
	if err != nil {
		return ptr.HandleError(ctx, err)
	}
	return ptr.OkJSON(ctx, res)
}
