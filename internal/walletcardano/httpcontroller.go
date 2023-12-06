package walletcardano

import (
	"log/slog"

	"github.com/LeonColt/echochamber"
	"github.com/SolusiDataPintar/tickets/internal/cardano"
	"github.com/SolusiDataPintar/tickets/internal/ctxutil"
	"github.com/labstack/echo/v4"
)

// Operations about Auths
type HttpController struct {
	echochamber.MixinController
	Group *echo.Group
}

func NewHttpController(parent *echo.Group) *HttpController {
	slog.Info("walletcardano.HttpController Created")
	ctrl := new(HttpController)
	ctrl.Group = parent.Group("/cardano")
	ctrl.Group.GET("/balance", ctrl.balance)
	ctrl.Group.GET("/address/add", ctrl.addAddress)
	ctrl.Group.GET("/address", ctrl.addresses)
	ctrl.Group.GET("/address/info/:address", ctrl.addressInfo)
	ctrl.Group.GET("/asset/:policyId/:assetId", ctrl.asset)
	ctrl.Group.POST("/send", ctrl.send)
	return ctrl
}

// GetBalance godoc
//
//	@ID			GetBalance
//	@Sumarry	Get wallet balance
//	@Tags		WalletCardano
//	@Security	ApiKeyAuth
//	@Accept		json
//	@Product	json
//	@Success	200	{object}	balance
//	@Failure	400	{object}	echochamber.HTTPError
//	@Failure	401	{object}	echochamber.HTTPError
//	@Failure	403	{object}	echochamber.HTTPError
//	@Failure	404	{object}	echochamber.HTTPError
//	@Failure	500	{object}	echochamber.HTTPError
//	@Router		/wallet/balance [get]
func (ptr *HttpController) balance(ctx echo.Context) error {
	auth, err := ctxutil.Authentication(ctx.Request().Context())
	if err != nil {
		return ptr.HandleError(ctx, err)
	}

	svc, err := NewService(WithContext(ctx.Request().Context()), WithUsername(auth.Subject))
	if err != nil {
		return ptr.HandleError(ctx, err)
	}
	res, err := svc.balance()
	if err != nil {
		return ptr.HandleError(ctx, err)
	}

	cardano := cardanoBalance{}
	{
		cardano.Coin = res.Coin
		cardano.Assets = []cardanoAsset{}
		for _, policyId := range res.MultiAsset.Keys() {
			for _, assetId := range res.MultiAsset.Get(policyId).Keys() {
				cardano.Assets = append(cardano.Assets, cardanoAsset{
					PolicyId:  policyId.String(),
					AssetName: assetId.String(),
					Qty:       res.MultiAsset.Get(policyId).Get(assetId),
				})
			}
		}
	}

	return ptr.OkJSON(ctx, balance{
		Cardano: cardano,
	})
}

// GetAddress godoc
//
//	@ID			GetAddress
//	@Sumarry	Get wallet address
//	@Tags		WalletCardano
//	@Security	ApiKeyAuth
//	@Accept		json
//	@Product	json
//	@Success	200	{string}	wallet	address
//	@Failure	400	{object}	echochamber.HTTPError
//	@Failure	401	{object}	echochamber.HTTPError
//	@Failure	403	{object}	echochamber.HTTPError
//	@Failure	404	{object}	echochamber.HTTPError
//	@Failure	500	{object}	echochamber.HTTPError
//	@Router		/wallet/cardano/address/add [get]
func (ptr *HttpController) addAddress(ctx echo.Context) error {
	auth, err := ctxutil.Authentication(ctx.Request().Context())
	if err != nil {
		return ptr.HandleError(ctx, err)
	}

	svc, err := NewService(WithContext(ctx.Request().Context()), WithUsername(auth.Subject))
	if err != nil {
		return ptr.HandleError(ctx, err)
	}
	address, err := svc.AddCardanoAddress()
	if err != nil {
		return ptr.HandleError(ctx, err)
	}
	return ptr.OkTextPlain(ctx, address.String())
}

// GetAddressQRCode godoc
//
//	@ID			GetAddressQRCode
//	@Sumarry	Get wallet address QR Code
//	@Tags		WalletCardano
//	@Security	ApiKeyAuth
//	@Accept		json
//	@Product	png
//	@Success	200	{object}	[]string
//	@Failure	400	{object}	echochamber.HTTPError
//	@Failure	401	{object}	echochamber.HTTPError
//	@Failure	403	{object}	echochamber.HTTPError
//	@Failure	404	{object}	echochamber.HTTPError
//	@Failure	500	{object}	echochamber.HTTPError
//	@Router		/wallet/cardano/address [get]
func (ptr *HttpController) addresses(ctx echo.Context) error {
	auth, err := ctxutil.Authentication(ctx.Request().Context())
	if err != nil {
		return ptr.HandleError(ctx, err)
	}

	svc, err := NewService(WithContext(ctx.Request().Context()), WithUsername(auth.Subject))
	if err != nil {
		return ptr.HandleError(ctx, err)
	}
	addresses, err := svc.Addresses()
	if err != nil {
		return ptr.HandleError(ctx, err)
	}

	res := make([]string, len(addresses))
	for i, addr := range addresses {
		res[i] = addr.String()
	}

	return ptr.OkJSON(ctx, res)
}

// GetAssetInfo godoc
//
//	@ID			GetAssetInfo
//	@Sumarry	Get asset information
//	@Tags		WalletCardano
//	@Security	ApiKeyAuth
//	@Accept		json
//	@Product	json
//	@Param		policyId	path		string	true	"asset policy id"
//	@Param		assetId		path		string	true	"asset id"
//	@Success	200			{object}	addressInfo
//	@Failure	400			{object}	echochamber.HTTPError
//	@Failure	401			{object}	echochamber.HTTPError
//	@Failure	403			{object}	echochamber.HTTPError
//	@Failure	404			{object}	echochamber.HTTPError
//	@Failure	500			{object}	echochamber.HTTPError
//	@Router		/wallet/cardano/asset/{policyId}/{assetId} [get]
func (ptr *HttpController) asset(ctx echo.Context) error {
	res, err := cardano.NewService().GetAssetInfo(ctx.Request().Context(), ctx.Param("policyId"), ctx.Param("assetId"))
	if err != nil {
		return ptr.HandleError(ctx, err)
	}
	return ptr.OkJSON(ctx, res)
}

// GetAddress godoc
//
//	@ID			GetAddressInfo
//	@Sumarry	Get wallet address information
//	@Tags		WalletCardano
//	@Security	ApiKeyAuth
//	@Accept		json
//	@Product	json
//	@Param		addr	path		string	true	"cardano address"
//	@Success	200		{object}	addressInfo
//	@Failure	400		{object}	echochamber.HTTPError
//	@Failure	401		{object}	echochamber.HTTPError
//	@Failure	403		{object}	echochamber.HTTPError
//	@Failure	404		{object}	echochamber.HTTPError
//	@Failure	500		{object}	echochamber.HTTPError
//	@Router		/wallet/cardano/address/info/{addr} [get]
func (ptr *HttpController) addressInfo(ctx echo.Context) error {
	res, err := cardano.NewService().GetAddressInfo(ctx.Request().Context(), ctx.Param("address"))
	if err != nil {
		return ptr.HandleError(ctx, err)
	}
	return ptr.OkJSON(ctx, parseAddressInfo(res))
}

// Send godoc
//
//	@ID			Send
//	@Sumarry	Set Asset to an address
//	@Tags		WalletCardano
//	@Security	ApiKeyAuth
//	@Accept		json
//	@Product	json
//	@Param		body	body		sendCardano	true	"redeem request"
//	@Success	200		{object}	addressInfo
//	@Failure	400		{object}	echochamber.HTTPError
//	@Failure	401		{object}	echochamber.HTTPError
//	@Failure	403		{object}	echochamber.HTTPError
//	@Failure	404		{object}	echochamber.HTTPError
//	@Failure	500		{object}	echochamber.HTTPError
//	@Router		/wallet/cardano/send [post]
func (ptr *HttpController) send(ctx echo.Context) error {
	auth, err := ctxutil.Authentication(ctx.Request().Context())
	if err != nil {
		return ptr.HandleError(ctx, err)
	}

	if auth.Subject == "da75c8d1-f08b-4bdf-9234-0e73641ccf94" {
		return ptr.Forbidden(ctx)
	}

	in := sendCardano{}
	if err := ptr.BindAndValidate(ctx, &in); err != nil {
		return ptr.HandleError(ctx, err)
	}

	svc, err := NewService(WithUsername(auth.Subject))
	if err != nil {
		return ptr.HandleError(ctx, err)
	}

	trxHash, err := svc.transfer(in)
	if err != nil {
		return ptr.HandleError(ctx, err)
	}
	return ptr.OkTextPlain(ctx, trxHash.String())
}
