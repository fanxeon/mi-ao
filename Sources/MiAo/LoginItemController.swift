// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation
import ServiceManagement

enum LoginItemState: Equatable {
    case disabled
    case enabled
    case requiresApproval
    case unavailable

    var detail: String {
        switch self {
        case .disabled:
            return "可选 · 登录后不会自动启动，仍可手动打开米遥"
        case .enabled:
            return "可选 · 已由 macOS 注册为登录时启动项目"
        case .requiresApproval:
            return "可选 · 已请求，需要在“登录项与扩展”中允许"
        case .unavailable:
            return "可选 · 当前 App 无法注册，请重新安装或检查签名"
        }
    }
}

protocol LoginItemService {
    var state: LoginItemState { get }
    func register() throws
    func unregister() throws
    func openSystemSettings()
}

struct SystemLoginItemService: LoginItemService {
    private var service: SMAppService { .mainApp }

    var state: LoginItemState {
        switch service.status {
        case .notRegistered: return .disabled
        case .enabled: return .enabled
        case .requiresApproval: return .requiresApproval
        case .notFound: return .unavailable
        @unknown default: return .unavailable
        }
    }

    func register() throws {
        try service.register()
    }

    func unregister() throws {
        try service.unregister()
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}

struct LoginItemController {
    private let service: LoginItemService

    init(service: LoginItemService = SystemLoginItemService()) {
        self.service = service
    }

    var state: LoginItemState {
        service.state
    }

    @discardableResult
    func setEnabled(_ enabled: Bool) throws -> LoginItemState {
        let current = service.state
        if enabled {
            switch current {
            case .disabled:
                try service.register()
                if service.state == .requiresApproval {
                    service.openSystemSettings()
                }
            case .requiresApproval:
                service.openSystemSettings()
            case .enabled, .unavailable:
                break
            }
        } else if current != .disabled {
            try service.unregister()
        }
        return service.state
    }

    func openSystemSettings() {
        service.openSystemSettings()
    }
}
