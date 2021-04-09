.PHONY: generate, watch, build, push, start, stop, run

generate:
	pub run build_runner build --delete-conflicting-outputs

watch:
	pub run build_runner watch --delete-conflicting-outputs
