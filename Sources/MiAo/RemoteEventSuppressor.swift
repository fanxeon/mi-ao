// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import ApplicationServices
import Foundation

private func miAoSuppressionEventTap(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let suppressor = Unmanaged<RemoteEventSuppressor>.fromOpaque(userInfo).takeUnretainedValue()
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        suppressor.reenableTap()
        return Unmanaged.passUnretained(event)
    }
    guard type == .keyDown || type == .keyUp else { return Unmanaged.passUnretained(event) }

    let isDown = type == .keyDown
    if suppressor.consume(isDown: isDown, now: ProcessInfo.processInfo.systemUptime) {
        return nil
    }
    usleep(4_000)
    if suppressor.consume(isDown: isDown, now: ProcessInfo.processInfo.systemUptime) {
        return nil
    }
    return Unmanaged.passUnretained(event)
}

final class RemoteEventSuppressor {
    private struct Token {
        let isDown: Bool
        let createdAt: TimeInterval
    }

    private let lock = NSLock()
    private var tokens: [Token] = []
    private var eventTap: CFMachPort?
    private var eventRunLoop: CFRunLoop?
    private var eventThread: Thread?

    func start() throws {
        let ready = DispatchSemaphore(value: 0)
        var startError: String?
        let thread = Thread { [weak self] in
            guard let self else {
                startError = "事件过滤器初始化对象已释放"
                ready.signal()
                return
            }
            let mask =
                CGEventMask(1 << CGEventType.keyDown.rawValue)
                | CGEventMask(1 << CGEventType.keyUp.rawValue)
            guard
                let tap = CGEvent.tapCreate(
                    tap: .cgSessionEventTap,
                    place: .headInsertEventTap,
                    options: .defaultTap,
                    eventsOfInterest: mask,
                    callback: miAoSuppressionEventTap,
                    userInfo: Unmanaged.passUnretained(self).toOpaque()
                )
            else {
                startError = "无法建立键盘事件过滤器；请检查辅助功能权限"
                ready.signal()
                return
            }
            self.eventTap = tap
            self.eventRunLoop = CFRunLoopGetCurrent()
            let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            ready.signal()
            CFRunLoopRun()
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        thread.name = "com.fanx.miao.remote-event-suppressor"
        eventThread = thread
        thread.start()

        guard ready.wait(timeout: .now() + 2) == .success else {
            throw BridgeError.configuration("键盘事件过滤器启动超时")
        }
        if let startError { throw BridgeError.configuration(startError) }
    }

    func stop() {
        lock.lock()
        tokens.removeAll()
        lock.unlock()
        if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: false) }
        if let eventRunLoop { CFRunLoopStop(eventRunLoop) }
        eventTap = nil
        eventRunLoop = nil
        eventThread = nil
    }

    func record(isDown: Bool, at: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        lock.lock()
        tokens.removeAll { at - $0.createdAt > 0.12 }
        tokens.append(Token(isDown: isDown, createdAt: at))
        lock.unlock()
    }

    func consume(isDown: Bool, now: TimeInterval) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        tokens.removeAll { now - $0.createdAt > 0.12 }
        guard let index = tokens.firstIndex(where: { $0.isDown == isDown }) else { return false }
        tokens.remove(at: index)
        return true
    }

    fileprivate func reenableTap() {
        if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: true) }
    }
}
