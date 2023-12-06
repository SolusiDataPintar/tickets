package env

import (
	"log/slog"
	"os"
	"sync"
	"time"

	"github.com/caarlos0/env/v9"
)

type Config struct {
	Debug             bool          `env:"DEBUG" envDefault:"false"`
	Redis             string        `env:"REDIS"`
	Host              string        `env:"HOST"`
	AssetCodeDuration time.Duration `env:"ASSET_CODE_DURATION" envDefault:"5m"`
	PriceSource       PriceSource   `envPrefix:"PRICE_SOURCE_"`
	Auth              Auth          `envPrefix:"AUTH_"`
	Vault             Vault         `envPrefix:"VAULT_"`
	Cardano           Cardano       `envPrefix:"CARDANO_"`
	Mail              Mail          `envPrefix:"MAIL_"`
}

type PriceSource struct {
	Url string `env:"URL"`
}

type Vault struct {
	Addr    string        `env:"ADDR"`
	Token   string        `env:"TOKEN"`
	Timeout time.Duration `env:"TIMEOUT" envDefault:"30s"`
}

type Auth struct {
	Url                string        `env:"URL"`
	Realm              string        `env:"REALM"`
	ClientId           string        `env:"CLIENT_ID"`
	ClientSecret       string        `env:"CLIENT_SECRET"`
	ActivationDuration time.Duration `env:"ACTIVATION_DURATION" envDefault:"12h"`
	LinkUrlTemplate    string        `env:"Link_URL_TEMPLATE"`
	Admin              AuthAdmin     `envPrefix:"ADMIN_"`
}

type AuthAdmin struct {
	Username string `env:"USERNAME"`
	Password string `env:"PASSWORD"`
}

type Cardano struct {
	Blockfrost string `env:"BLOCKFROST"`
}

type Mail struct {
	Host     string `env:"HOST"`
	Port     int    `env:"PORT"`
	Username string `env:"USERNAME"`
	Password string `env:"PASSWORD"`
}

var (
	cfg  Config
	once sync.Once
)

func LoadConfig() Config {
	once.Do(func() {
		cfg = Config{}
		if err := env.Parse(&cfg); err != nil {
			slog.Error("unable to load environment variable", slog.Any("err", err))
			os.Exit(1)
		}
		if err := validate(cfg); err != nil {
			slog.Error("invalid environment variables", slog.Any("err", err))
			os.Exit(1)
		}
	})
	return cfg
}

func validate(cfg Config) error {
	return nil
}
