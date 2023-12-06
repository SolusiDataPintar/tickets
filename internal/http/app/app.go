package app

import (
	"context"
	"log/slog"
	"net/http"
	"os"
	"time"

	"github.com/LeonColt/echochamber"
	"github.com/SolusiDataPintar/tickets/internal/common"
	"github.com/SolusiDataPintar/tickets/internal/http/router"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

type App struct {
	Engine *echo.Echo
	Router *router.Router
}

func NewApp(logLevel slog.Level) *App {
	app := new(App)
	e := echo.New()
	e.Pre(middleware.RemoveTrailingSlash())
	if logLevel == slog.LevelDebug {
		e.Use(middleware.RequestLoggerWithConfig(middleware.RequestLoggerConfig{
			LogURI:    true,
			LogStatus: true,
			LogValuesFunc: func(c echo.Context, v middleware.RequestLoggerValues) error {
				slog.Info("http request", slog.String("uri", v.URI), slog.Int("status", v.Status))
				return nil
			},
		}))
	}
	e.Use(middleware.CORSWithConfig(middleware.CORSConfig{
		AllowOrigins: []string{"*"},
		AllowHeaders: []string{echo.HeaderOrigin, echo.HeaderContentType, echo.HeaderAccept, echo.HeaderAuthorization},
		AllowMethods: []string{echo.GET, echo.HEAD, echo.PUT, echo.PATCH, echo.POST, echo.DELETE},
	}))
	e.Validator = common.NewValidator()
	rateConfig := middleware.RateLimiterConfig{
		Skipper: middleware.DefaultSkipper,
		Store: middleware.NewRateLimiterMemoryStoreWithConfig(
			middleware.RateLimiterMemoryStoreConfig{Rate: 100, Burst: 50, ExpiresIn: 3 * time.Minute},
		),
		IdentifierExtractor: func(ctx echo.Context) (string, error) {
			id := ctx.RealIP()
			return id, nil
		},
		ErrorHandler: func(context echo.Context, err error) error {
			return context.JSON(http.StatusInternalServerError, echochamber.HTTPError{
				Code:    500,
				Message: "Internal Server Error",
			})
		},
		DenyHandler: func(context echo.Context, identifier string, err error) error {
			return context.JSON(http.StatusTooManyRequests, echochamber.HTTPError{
				Code:    429,
				Message: "too many request.",
			})
		},
	}
	e.Use(middleware.RateLimiterWithConfig(rateConfig))
	app.Engine = e
	return app
}

func (app *App) Start(ctx context.Context, host string) {
	app.Router = router.NewRouter(ctx, host, app.Engine)
	err := app.Engine.Start(":8080")
	if err != nil {
		slog.Error("an error occurred", slog.Any("err", err))
		os.Exit(1)
	}
}
