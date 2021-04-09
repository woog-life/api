.PHONY: generate, watch, build, push

generate:
	pub run build_runner build --delete-conflicting-outputs

watch:
	pub run build_runner watch --delete-conflicting-outputs

build:
	docker build -t wooglife/api .

push:
	docker push wooglife/api

