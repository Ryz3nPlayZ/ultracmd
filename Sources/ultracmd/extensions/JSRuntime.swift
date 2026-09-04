import AppKit
import Foundation
import JavaScriptCore

/// One JavaScriptCore execution context per running extension command.
/// All JS evaluation is confined to a serial queue; async native operations
/// (fetch, shell, dialogs) hop out to worker/main threads and resolve their
/// JS promises back on the JS queue.
final class JSRuntime {

    struct Bridge {
        var onRender: (String) -> Void = { _ in }
        var onLog: (String) -> Void = { _ in }
        var onClose: () -> Void = {}
        var onHUD: (String) -> Void = { _ in }
        var onToastShow: (_ id: String, _ style: String, _ title: String, _ message: String) -> Void = { _, _, _, _ in }
        var onToastHide: (String) -> Void = { _ in }
        var onLaunchCommand: (_ name: String, _ argumentsJSON: String) -> Void = { _, _ in }
        var onOpenExtensionPreferences: () -> Void = {}
    }

    let bridge: Bridge
    private let queue = DispatchQueue(label: "ultracmd.js", qos: .userInitiated)
    private var context: JSContext?
    private var nextTokenValue = 0
    private let tokenLock = NSLock()
    /// Native method table, confined to the JS queue. JSC maps each JS
    /// argument to one block parameter, so blocks take (String, [Any]):
    /// method name + argument array.
    private var handlers: [String: ([Any]) -> Any?] = [:]
    private var timers: [Int: DispatchSourceTimer] = [:]
    private let timersLock = NSLock()
    private var storageURL: URL?
    private var storage: [String: String] = [:]
    private var storageDirty = false

    init(bridge: Bridge) {
        self.bridge = bridge
    }

    /// Lock-guarded (NOT queue.sync): bridge blocks run on the JS queue itself,
    /// so a sync hop to the same serial queue would deadlock.
    private func nextToken() -> Int {
        tokenLock.lock()
        nextTokenValue += 1
        let token = nextTokenValue
        tokenLock.unlock()
        return token
    }

    // MARK: Lifecycle

    /// Evaluate shim + user script (already transformed from ESM), then boot.
    func run(script: String, bootOptionsJSON: String, storageFile: URL?) {
        queue.async { [self] in
            guard context == nil else { return }
            let vm = JSVirtualMachine()
            let ctx = JSContext(virtualMachine: vm)!
            context = ctx
            ctx.exceptionHandler = { [weak self] _, exception in
                var message = exception?.toString() ?? "unknown JS exception"
                if let stack = exception?.objectForKeyedSubscript("stack").toString() {
                    message += "\n" + stack.prefix(600)
                }
                self?.bridge.onLog("[exception] \(message)")
            }

            storageURL = storageFile
            if let storageFile,
               let data = try? Data(contentsOf: storageFile),
               let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
                storage = decoded
            }

            installBridge(ctx)
            installPromisePlumbing(ctx)
            ctx.evaluateScript(ShimJS.source)
            evaluateUserScript(ctx, script: script)
            ctx.evaluateScript("__ultracmdBoot(\"\(bootOptionsJSON.maskedForJS)\")")
            flushStorage()
        }
    }

    private func evaluateUserScript(_ ctx: JSContext, script: String) {
        let moduleWrapper = """
        (function () {
          const module = { exports: {} };
          const exports = module.exports;
          globalThis.__moduleExports = module.exports;
          try {
        \(script)
          } catch (e) { globalThis.__native.log('script error: ' + (e && e.stack || e)); }
          globalThis.__moduleExports = module.exports;
        })();
        """
        ctx.evaluateScript(moduleWrapper)
    }

    private func installPromisePlumbing(_ ctx: JSContext) {
        ctx.evaluateScript("""
        globalThis.__native = new Proxy({}, {
          get: function (_target, prop) {
            const name = String(prop);
            return function () {
              const args = Array.prototype.slice.call(arguments);
              return globalThis.__nativeCall(name, args);
            };
          }
        });
        globalThis.__pendingResolvers = {};
        globalThis.__makePending = function (token) {
          return new Promise(function (resolve, reject) {
            globalThis.__pendingResolvers[token] = { resolve: resolve, reject: reject };
          });
        };
        globalThis.__nativeResolve = function (token, json, isError) {
          const rec = globalThis.__pendingResolvers[token];
          if (!rec) return;
          delete globalThis.__pendingResolvers[token];
          let value = null;
          if (json !== null && json !== undefined) { try { value = JSON.parse(json); } catch (e) { value = json; } }
          if (isError) rec.reject(value); else rec.resolve(value);
        };
        """ )
    }

    /// Dispatch an event into the shim (`perform`, `query`, `selection`, `submitForm`).
    func dispatch(_ event: String, _ a: String?, _ b: String?) {
        queue.async { [self] in
            guard let ctx = context else { return }
            var args: [Any] = [event]
            if let a { args.append(a) }
            if let b { args.append(b) }
            ctx.globalObject.invokeMethod("__dispatch", withArguments: args)
            flushStorage()
        }
    }

    deinit {
        timersLock.lock()
        let items = Array(timers.values)
        timers.removeAll()
        timersLock.unlock()
        for item in items { item.cancel() }
        flushStorageSync()
    }

    // MARK: Storage

    private func flushStorage() {
        guard storageDirty, let url = storageURL else { return }
        storageDirty = false
        if let data = try? JSONEncoder().encode(storage) {
            try? data.write(to: url, options: .atomic)
        }
    }

    private func flushStorageSync() {
        guard storageDirty, let url = storageURL, let data = try? JSONEncoder().encode(storage) else { return }
        try? data.write(to: url, options: .atomic)
    }

    // MARK: Bridge installation
    // Split into one small method per native function: a single ~250-line
    // function full of @convention(block) closures trips a swift-frontend
    // type-checker crash (ConstraintSystem::applySolution).

    private func installBridge(_ ctx: JSContext) {
        let native = JSValue(newObjectIn: ctx)
        installUIBridge(native: native)
        installOpenBridge(native: native)
        installClipboardBridge(native: native)
        installStorageBridge(native: native)
        installFileBridge(native: native)
        installEnvironmentBridge(native: native)
        installTimerBridge(native: native)
        installAsyncBridge(ctx: ctx, native: native)

        let handlers = self.handlers
        let callBlock: @convention(block) (String, [Any]) -> Any? = { [weak self] name, args in
            guard let self else { return nil }
            guard let handler = handlers[name] ?? self.handlers[name] else {
                self.bridge.onLog("[bridge] unknown method \(name)")
                return nil
            }
            return handler(args)
        }
        ctx.setObject(callBlock, forKeyedSubscript: "__nativeCall" as NSString)
        _ = native
    }

    private func setMethod(_ native: JSValue?, _ name: String, _ block: @escaping ([Any]) -> Any?) {
        _ = native
        handlers[name] = block
    }

    private func installUIBridge(native: JSValue?) {
        let bridge = self.bridge
        setMethod(native, "log") { args in
            bridge.onLog(args.compactMap { $0 as? String }.joined(separator: " "))
            return nil
        }
        setMethod(native, "render") { args in
            if let json = args.first as? String { bridge.onRender(json) }
            return nil
        }
        setMethod(native, "closeMainWindow") { _ in
            DispatchQueue.main.async { bridge.onClose() }
            return nil
        }
        setMethod(native, "showHUD") { args in
            let text = args.first as? String ?? ""
            DispatchQueue.main.async { bridge.onHUD(text) }
            return nil
        }
        setMethod(native, "showToast") { args in
            let style = args.count > 0 ? (args[0] as? String ?? "regular") : "regular"
            let title = args.count > 1 ? (args[1] as? String ?? "") : ""
            let message = args.count > 2 ? (args[2] as? String ?? "") : ""
            let id = UUID().uuidString
            DispatchQueue.main.async { bridge.onToastShow(id, style, title, message) }
            return ["id": id, "style": style, "title": title, "message": message]
        }
        setMethod(native, "hideToast") { args in
            if let id = args.first as? String {
                DispatchQueue.main.async { bridge.onToastHide(id) }
            }
            return nil
        }
        setMethod(native, "launchCommand") { args in
            let name = args.first as? String ?? ""
            let argumentsJSON = args.count > 1 ? (args[1] as? String ?? "{}") : "{}"
            DispatchQueue.main.async { bridge.onLaunchCommand(name, argumentsJSON) }
            return nil
        }
        setMethod(native, "openExtensionPreferences") { _ in
            DispatchQueue.main.async { bridge.onOpenExtensionPreferences() }
            return nil
        }
    }

    private func installOpenBridge(native: JSValue?) {
        setMethod(native, "open") { args in
            Self.openTarget(target: args.first as? String ?? "",
                            app: args.count > 1 ? (args[1] as? String) : nil)
            return true
        }
    }

    private static func openTarget(target: String, app: String?) {
        DispatchQueue.main.async {
            if let app {
                let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app)
                    ?? URL(fileURLWithPath: app)
                NSWorkspace.shared.open(
                    [URL(string: target) ?? URL(fileURLWithPath: target)],
                    withApplicationAt: appURL,
                    configuration: NSWorkspace.OpenConfiguration()
                )
            } else if let url = URL(string: target), url.scheme != nil, url.scheme != "file" {
                NSWorkspace.shared.open(url)
            } else {
                NSWorkspace.shared.open(URL(fileURLWithPath: target))
            }
        }
    }

    private func installClipboardBridge(native: JSValue?) {
        setMethod(native, "clipboardWrite") { args in
            let text = args.first as? String ?? ""
            DispatchQueue.main.async {
                ClipboardHistoryManager.shared.suppressCaptureOnce()
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(text, forType: .string)
            }
            return nil
        }
        setMethod(native, "getSelectedText") { _ in
            AccessibilityHelper.selectedText()
        }
    }

    private func installStorageBridge(native: JSValue?) {
        setMethod(native, "storageGet") { [self] args in
            guard let key = args.first as? String else { return nil }
            return storage[key]
        }
        setMethod(native, "storageSet") { [self] args in
            guard args.count >= 2, let key = args[0] as? String, let value = args[1] as? String else { return nil }
            storage[key] = value
            storageDirty = true
            return nil
        }
        setMethod(native, "storageRemove") { [self] args in
            if let key = args.first as? String {
                storage[key] = nil
                storageDirty = true
            }
            return nil
        }
    }

    private func installFileBridge(native: JSValue?) {
        setMethod(native, "readFile") { args in
            guard let path = args.first as? String else { return nil }
            return try? String(contentsOfFile: path, encoding: .utf8)
        }
        setMethod(native, "writeFile") { args in
            guard args.count >= 2, let path = args[0] as? String, let data = args[1] as? String else {
                return ["ok": false, "error": "bad arguments"]
            }
            do {
                let dir = (path as NSString).deletingLastPathComponent
                try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
                try data.write(toFile: path, atomically: true, encoding: .utf8)
                return ["ok": true]
            } catch {
                return ["ok": false, "error": error.localizedDescription]
            }
        }
        setMethod(native, "fileExists") { args in
            (args.first as? String).map { FileManager.default.fileExists(atPath: $0) } ?? false
        }
        setMethod(native, "mkdir") { args in
            if let path = args.first as? String {
                try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
            }
            return nil
        }
    }

    private func installEnvironmentBridge(native: JSValue?) {
        setMethod(native, "homedir") { _ in NSHomeDirectory() }
        setMethod(native, "tmpdir") { _ in NSTemporaryDirectory() }
        setMethod(native, "getEnv") { _ in
            let env = ProcessInfo.processInfo.environment
            guard let data = try? JSONSerialization.data(withJSONObject: env),
                  let json = String(data: data, encoding: .utf8) else { return "{}" }
            return json
        }
    }

    private func installTimerBridge(native: JSValue?) {
        setMethod(native, "setTimeout") { [self] args in
            let ms = args.first as? Double ?? 0
            return scheduleTimer(ms: ms, repeating: false)
        }
        setMethod(native, "setInterval") { [self] args in
            let ms = max((args.first as? Double ?? 1), 1)
            return scheduleTimer(ms: ms, repeating: true)
        }
        setMethod(native, "clearTimeout") { [self] args in
            cancelTimer(Self.intArg(args, 0, default: -1))
            return nil
        }
        setMethod(native, "clearInterval") { [self] args in
            cancelTimer(Self.intArg(args, 0, default: -1))
            return nil
        }
    }

    private static func intArg(_ args: [Any], _ index: Int, default def: Int) -> Int {
        guard index < args.count else { return def }
        if let n = args[index] as? Int { return n }
        if let n = args[index] as? Int32 { return Int(n) }
        if let n = args[index] as? Double { return Int(n) }
        if let n = args[index] as? NSNumber { return n.intValue }
        return def
    }

    private func installAsyncBridge(ctx: JSContext, native: JSValue?) {
        installAsync(ctx: ctx, native: native, name: "fetchAsync", work: Self.workFetch)
        installAsync(ctx: ctx, native: native, name: "runShell") { args, resolve in
            let command = args[0] as? String ?? ""
            let timeout = args.count > 1 ? Self.intArg(args, 1, default: 10_000) : 10_000
            DispatchQueue.global(qos: .userInitiated).async {
                let result = ShellRunner.run(command: command, timeoutMs: timeout)
                resolve(["stdout": result.stdout, "stderr": result.stderr, "code": result.code])
            }
        }
        installAsync(ctx: ctx, native: native, name: "confirmAlert") { args, resolve in
            let title = args.first as? String ?? "Are you sure?"
            let message = args.count > 1 ? (args[1] as? String ?? "") : ""
            let ok = args.count > 2 ? (args[2] as? String ?? "OK") : "OK"
            let cancel = args.count > 3 ? (args[3] as? String ?? "Cancel") : "Cancel"
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = title
                alert.informativeText = message
                alert.addButton(withTitle: ok)
                alert.addButton(withTitle: cancel)
                let confirmed = alert.runModal() == .alertFirstButtonReturn
                resolve(confirmed)
            }
        }
        installAsync(ctx: ctx, native: native, name: "clipboardRead") { _, resolve in
            DispatchQueue.main.async {
                let text = NSPasteboard.general.string(forType: .string) ?? ""
                resolve(["text": text])
            }
        }
    }

    private static func workFetch(_ args: [Any], _ resolve: @escaping (Any) -> Void) {
        let url = args[0] as? String ?? ""
        let method = (args.count > 1 ? args[1] as? String : nil) ?? "GET"
        let headers = args.count > 2 ? (args[2] as? String) : nil
        let body = args.count > 3 ? (args[3] as? String) : nil
        guard let requestURL = URL(string: url) else {
            resolve(["status": 0, "headers": [:] as [String: String], "body": "invalid URL"])
            return
        }
        var request = URLRequest(url: requestURL)
        request.httpMethod = method.uppercased()
        request.timeoutInterval = 30
        if let headers,
           let headerDict = try? JSONSerialization.jsonObject(with: Data(headers.utf8)) as? [String: String] {
            for (k, v) in headerDict { request.setValue(v, forHTTPHeaderField: k) }
        }
        if let body, !body.isEmpty {
            request.httpBody = Data(body.utf8)
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }
        let completion: (Data?, URLResponse?, Error?) -> Void = { data, response, error in
            let result: [String: Any]
            if let error {
                result = ["status": 0, "headers": [:] as [String: String], "body": error.localizedDescription]
            } else {
                let http = response as? HTTPURLResponse
                result = [
                    "status": http?.statusCode ?? 0,
                    "headers": http?.allHeaderFields ?? [:] as [String: String],
                    "body": String(data: data ?? Data(), encoding: .utf8) ?? "",
                ]
            }
            resolve(result)
        }
        URLSession.shared.dataTask(with: request, completionHandler: completion).resume()
    }

    /// Registers a native method that returns a JS Promise. Work runs off the
    /// JS queue; the resolver hops back onto it.
    private func installAsync(
        ctx: JSContext,
        native: JSValue?,
        name: String,
        work: @escaping ([Any], @escaping (Any) -> Void) -> Void
    ) {
        _ = native
        let block: ([Any]) -> Any? = { [weak self] args in
            guard let self else { return nil }
            let token = self.nextToken()
            let promise: JSValue
            if let created = ctx.evaluateScript("globalThis.__makePending(\(token))") {
                promise = created
            } else {
                promise = JSValue(undefinedIn: ctx)
            }
            work(args) { [weak self] value in
                guard let self else { return }
                self.queue.async {
                    let json = Self.encodeForResolve(value)
                    ctx.globalObject.invokeMethod("__nativeResolve", withArguments: [token, json, false])
                }
            }
            return promise
        }
        handlers[name] = block
    }

    private static func encodeForResolve(_ value: Any) -> Any {
        let valid = JSONSerialization.isValidJSONObject(value)
            || value is String || value is Bool || value is NSNumber
        guard valid,
              let data = try? JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed]),
              let json = String(data: data, encoding: .utf8) else {
            return NSNull()
        }
        return json
    }

    // MARK: Timers

    private func scheduleTimer(ms: Double, repeating: Bool) -> Int {
        let token = nextToken()
        let interval = max(ms / 1000.0, 0.001)
        let timer = DispatchSource.makeTimerSource(queue: queue)
        if repeating {
            timer.schedule(deadline: .now() + interval, repeating: interval)
        } else {
            timer.schedule(deadline: .now() + interval)
        }
        timer.setEventHandler { [weak self] in
            guard let self, let ctx = self.context else { return }
            ctx.globalObject.invokeMethod("__dispatch", withArguments: ["timer", token])
            self.flushStorage()
        }
        timersLock.lock()
        timers[token] = timer
        timersLock.unlock()
        timer.resume()
        return token
    }

    private func cancelTimer(_ token: Int) {
        guard token >= 0 else { return }
        timersLock.lock()
        let timer = timers.removeValue(forKey: token)
        timersLock.unlock()
        timer?.cancel()
    }
}

extension String {
    /// Escape for safe embedding inside a JS double-quoted string.
    var maskedForJS: String {
        replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
    }
}

/// Shell execution with timeout for extension `useBash`/`runShell`.
enum ShellRunner {
    struct Result {
        var stdout: String
        var stderr: String
        var code: Int
    }

    static func run(command: String, timeoutMs: Int) -> Result {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        process.environment = ProcessInfo.processInfo.environment

        do {
            try process.run()
        } catch {
            return Result(stdout: "", stderr: "failed to launch: \(error.localizedDescription)", code: 127)
        }

        let deadline = Date().addingTimeInterval(TimeInterval(timeoutMs) / 1000.0)
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.02)
        }
        if process.isRunning {
            process.terminate()
            Thread.sleep(forTimeInterval: 0.1)
            if process.isRunning { kill(process.processIdentifier, SIGKILL) }
            _ = outPipe.fileHandleForReading.readDataToEndOfFile()
            let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
                ?? "timed out after \(timeoutMs)ms"
            return Result(stdout: "", stderr: err, code: 124)
        }

        let out = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return Result(stdout: out, stderr: err, code: Int(process.terminationStatus))
    }
}
