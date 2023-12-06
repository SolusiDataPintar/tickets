package router

import (
	"context"
	"embed"
	"io/fs"
	"log/slog"
	"net/http"
	"os"

	"github.com/SolusiDataPintar/tickets/internal/account"
	"github.com/SolusiDataPintar/tickets/internal/ctxutil"
	"github.com/SolusiDataPintar/tickets/internal/price"
	"github.com/SolusiDataPintar/tickets/internal/walletcardano"
	"github.com/labstack/echo/v4"
)

//go:embed app
var uiApp embed.FS

//go:embed activation
var uiActivation embed.FS

func getFileSystem(fSys embed.FS, name string) http.FileSystem {
	fsys, err := fs.Sub(fSys, name)
	if err != nil {
		slog.Error("error load activation page asset", slog.Any("err", err))
		os.Exit(1)
	}
	return http.FS(fsys)
}

type Router struct {
	account       *account.HttpController
	price         *price.HttpController
	walletCardano *walletcardano.HttpController
}

func NewRouter(ctx context.Context, host string, e *echo.Echo) *Router {
	{ //handling app
		uiAppHandler := http.FileServer(getFileSystem(uiApp, "app"))
		e.GET("/", echo.WrapHandler(uiAppHandler))
		e.GET("/*", echo.WrapHandler(uiAppHandler))
	}

	{ //handling activation
		uiActivationHandler := http.FileServer(getFileSystem(uiActivation, "activation"))
		e.GET("/activation", echo.WrapHandler(http.StripPrefix("/activation", uiActivationHandler)))
		e.GET("/activation/*", echo.WrapHandler(http.StripPrefix("/activation", uiActivationHandler)))
	}

	apiGroup := e.Group("/api")
	walletGroup := apiGroup.Group("/wallet")
	walletGroup.Use(ctxutil.ApplyAuthentication(nil))
	return &Router{
		account:       account.NewHttpController(apiGroup),
		price:         price.NewHttpController(apiGroup),
		walletCardano: walletcardano.NewHttpController(walletGroup),
	}
}
