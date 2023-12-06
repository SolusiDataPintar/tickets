swagger:
	cp cmd/main/main.go ./main.go
	swag init --pd --parseInternal
	rm ./main.go

clean_ui:
	rm -rf internal/http/router/app
	mkdir -p internal/http/router/app
	cd ui; flutter clean;

build_ui:
	rm -rf internal/http/router/app
	mkdir -p internal/http/router/app
ifndef MODE
	cd ui; flutter clean; flutter pub get; flutter packages pub run build_runner build -d; flutter pub run intl_utils:generate; \
	flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=true --web-renderer canvaskit
else
	cd ui; flutter clean; flutter pub get; flutter packages pub run build_runner build -d; flutter pub run intl_utils:generate; \
	flutter build web --$(MODE) --dart-define=FLUTTER_WEB_USE_SKIA=true --web-renderer canvaskit
endif
	cp -r ui/build/web/* internal/http/router/app
