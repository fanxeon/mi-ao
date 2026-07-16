// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation

enum MiAoRuntimeNotifications {
    static let buttonConfigurationChanged = Notification.Name(
        "com.poemcoder.mi-ao.button-configuration-changed"
    )
    static let buttonActivity = Notification.Name("com.poemcoder.mi-ao.button-activity")

    static func postButtonConfigurationChanged() {
        DistributedNotificationCenter.default().postNotificationName(
            buttonConfigurationChanged,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    static func postButtonActivity(button: RemoteButton, isPressed: Bool) {
        DistributedNotificationCenter.default().postNotificationName(
            buttonActivity,
            object: nil,
            userInfo: ["button": button.rawValue, "phase": isPressed ? "down" : "up"],
            deliverImmediately: true
        )
    }
}
