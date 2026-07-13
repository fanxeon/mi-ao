.PHONY: build release test format lint app install setup doctor scan check clean

build:
	swift build

release:
	swift build -c release

test:
	swift test

format:
	xcrun swift-format format --in-place --recursive Sources Tests Package.swift

lint:
	xcrun swift-format lint --strict --recursive Sources Tests Package.swift

app:
	./scripts/build-app.sh

install:
	./scripts/install-app.sh

setup:
	./scripts/setup.sh

doctor: release
	.build/release/xiaomi-voice-bridge doctor

scan: release
	.build/release/xiaomi-voice-bridge scan --scan-seconds 15

check:
	xcrun swift-format lint --strict --recursive Sources Tests Package.swift
	swift test
	swift build -c release
	plutil -lint Resources/Info.plist
	git diff --check

clean:
	swift package clean
