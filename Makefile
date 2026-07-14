# Copyright (c) 2026 FanXeon@Poemcoder with Codex
.PHONY: build release test format lint app install setup preflight verify authorize uninstall source-release doctor scan capture learn-buttons debug-buttons run-mapped mapping-status mapping-restore check clean

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

preflight:
	./scripts/preflight.sh

verify:
	./scripts/verify-install.sh

authorize:
	./scripts/authorize.sh

uninstall:
	./scripts/uninstall.sh

source-release:
	./scripts/source-release.sh

doctor: release
	./scripts/bridge.sh doctor

scan: release
	./scripts/bridge.sh scan --scan-seconds 15

capture:
	./scripts/capture.sh --scan-seconds 30

learn-buttons:
	./scripts/learn-buttons.sh --name "小米蓝牙语音遥控器"

debug-buttons:
	./scripts/debug-buttons.sh --name "小米蓝牙语音遥控器"

run-mapped:
	./scripts/run-with-mapping.sh --name "小米蓝牙语音遥控器"

mapping-status:
	./scripts/remote-mapping.sh status

mapping-restore:
	./scripts/remote-mapping.sh restore

check:
	xcrun swift-format lint --strict --recursive Sources Tests Package.swift
	swift test
	zsh Tests/Shell/RemoteMappingTests.sh
	zsh Tests/Shell/KeyboardIsolationTests.sh
	swift build -c release
	plutil -lint Resources/Info.plist
	git diff --check

clean:
	swift package clean
