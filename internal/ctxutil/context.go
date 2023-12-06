package ctxutil

import (
	"context"
	"net/http"
	"strings"

	"github.com/LeonColt/echochamber"
	"github.com/LeonColt/ez"
	"github.com/SolusiDataPintar/tickets/internal/auth"
	"github.com/golang-jwt/jwt/v4"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

type ctxKey int

const (
	_ ctxKey = iota
	ctxKeyAuthentication
	ctxKeyIpAddress
)

func ApplyAuthentication(skipper middleware.Skipper) echo.MiddlewareFunc {
	return middleware.KeyAuthWithConfig(middleware.KeyAuthConfig{
		Skipper:    skipper,
		KeyLookup:  "header:Authorization,cookie:accessToken",
		AuthScheme: "Bearer",
		Validator: func(accessToken string, c echo.Context) (bool, error) {
			//fmt.Println(accessToken)
			token, err := auth.NewService().ValidateSession(c.Request().Context(), strings.TrimSpace(accessToken))
			if err != nil {
				return false, ez.New(ez.ErrorCodeUnauthenticated, "invalid session")
			}
			ctx := context.WithValue(c.Request().Context(), ctxKeyAuthentication, token)
			c.SetRequest(c.Request().WithContext(ctx))
			return true, nil
		},
		ErrorHandler: func(err error, c echo.Context) error {
			return c.JSON(http.StatusUnauthorized, echochamber.HTTPError{
				Code:    http.StatusUnauthorized,
				Message: err.Error(),
			})
		},
	})
}

func Authentication(ctx context.Context) (jwt.RegisteredClaims, error) {
	anyToken := ctx.Value(ctxKeyAuthentication)
	if anyToken == nil {
		return jwt.RegisteredClaims{}, ez.New(ez.ErrorCodeUnauthenticated, "invalid session")
	}

	if token, ok := anyToken.(jwt.RegisteredClaims); ok {
		return token, nil
	} else {
		return jwt.RegisteredClaims{}, ez.New(ez.ErrorCodeUnauthenticated, "invalid session")
	}
}

func WithIpAddress(ctx context.Context, ipAddress string) context.Context {
	return context.WithValue(ctx, ctxKeyIpAddress, ipAddress)
}

func IpAddress(ctx context.Context) string {
	ipAddress := ctx.Value(ctxKeyIpAddress)
	if ipAddress == nil {
		return ""
	}
	if v, ok := ipAddress.(string); ok {
		return v
	} else {
		return ""
	}
}
