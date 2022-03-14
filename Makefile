.PHONY: generate, watch, build, push, start, stop, run

generate:
	dart run build_runner build --delete-conflicting-outputs

watch:
	dart run build_runner watch --delete-conflicting-outputs
