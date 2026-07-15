// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation
import Testing

@testable import MiAo

@Test func loginItemControllerRegistersAndUnregistersFromRealState() throws {
    let service = FakeLoginItemService(state: .disabled)
    let controller = LoginItemController(service: service)

    #expect(try controller.setEnabled(true) == .enabled)
    #expect(service.registerCount == 1)
    #expect(try controller.setEnabled(false) == .disabled)
    #expect(service.unregisterCount == 1)
}

@Test func loginItemControllerOpensSettingsWhenApprovalIsRequired() throws {
    let service = FakeLoginItemService(state: .requiresApproval)
    let controller = LoginItemController(service: service)

    #expect(try controller.setEnabled(true) == .requiresApproval)
    #expect(service.openSettingsCount == 1)
    #expect(service.registerCount == 0)
}

private final class FakeLoginItemService: LoginItemService {
    var state: LoginItemState
    private(set) var registerCount = 0
    private(set) var unregisterCount = 0
    private(set) var openSettingsCount = 0

    init(state: LoginItemState) {
        self.state = state
    }

    func register() throws {
        registerCount += 1
        state = .enabled
    }

    func unregister() throws {
        unregisterCount += 1
        state = .disabled
    }

    func openSystemSettings() {
        openSettingsCount += 1
    }
}
