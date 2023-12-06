package cache

import (
	"log/slog"
	"os"

	"github.com/go-redis/redis/v8"
)

var (
	Client *redis.Client
)

func OpenConnection(dsn string) {
	connOpt, err := redis.ParseURL(dsn)
	if err != nil {
		slog.Error("error parsing redis url", slog.Any("err", err))
		os.Exit(1)
	}
	Client = redis.NewClient(connOpt)
}

func HasConnection() bool {
	return Client != nil
}

func IsNotFound(err error) bool {
	return err == redis.Nil
}

func CloseConnection() {
	err := Client.Close()
	if err != nil {
		slog.Error("error closing redis", slog.Any("err", err))
	}
}
