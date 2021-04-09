.PHONY: generate, watch, build, push, start, stop, run

generate:
	pub run build_runner build --delete-conflicting-outputs

watch:
	pub run build_runner watch --delete-conflicting-outputs

build:
	docker build -t wooglife/api .

push: build
	docker push wooglife/api

start: build
	docker run --rm -p 8080:8080 --name woog -d wooglife/api

run: build
	docker run --rm -p 8080:8080 --name woog -it wooglife/api

stop:
	docker kill woog
