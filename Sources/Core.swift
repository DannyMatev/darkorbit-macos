import Foundation
import CryptoKit
import Darwin

struct InstallationLayout {
    let root: URL
    var engine: URL { path("runtime/wswine.bundle") }
    var prefix: URL { path("state/prefix") }
    var game: URL { prefix.appendingPathComponent("drive_c/DarkOrbitFree/Game") }
    func path(_ relative: String) -> URL { root.appendingPathComponent(relative) }
}

enum AppFailure: Error, LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let text) = self { return text }; return nil }
}

struct CommandResult {
    let status: Int32
    let output: String
}

// The operating system releases this advisory lock even if the app exits.
final class InstallationLock {
    private var descriptor: Int32 = -1
    init(layout: InstallationLayout) throws {
        try RuntimeCore.preparePrivateDirectory(layout.root)
        let lockURL = layout.path(".operation.lock")
        descriptor = open(lockURL.path, O_CREAT | O_RDWR | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard descriptor >= 0 else { throw AppFailure.message("The installation lock could not be opened. Existing files were preserved.") }
        var info = stat()
        guard fstat(descriptor, &info) == 0, (info.st_mode & S_IFMT) == S_IFREG,
              info.st_uid == getuid(), info.st_nlink == 1,
              flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            close(descriptor); descriptor = -1
            throw AppFailure.message("Another operation is using this installation, or its lock is unsafe. Finish that operation and try again.")
        }
    }
    deinit { if descriptor >= 0 { flock(descriptor, LOCK_UN); close(descriptor) } }
}

enum RuntimeCore {
    static var defaultLayout: InstallationLayout {
        InstallationLayout(root: FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/DarkOrbitCommunity", isDirectory: true))
    }
    static func environment(_ layout: InstallationLayout) -> [String: String] {
        var env = [String: String]()
        for key in ["HOME", "USER", "LOGNAME", "TMPDIR"] {
            if let value = ProcessInfo.processInfo.environment[key] { env[key] = value }
        }
        env["PATH"] = layout.engine.appendingPathComponent("bin").path + ":/usr/bin:/bin:/usr/sbin:/sbin"
        env["LANG"] = "en_US.UTF-8"
        env["LC_ALL"] = "en_US.UTF-8"
        env["WINEPREFIX"] = layout.prefix.path
        env["WINEARCH"] = "win64"
        env["WINESERVER"] = layout.engine.appendingPathComponent("bin/wineserver").path
        env["WINELOADER"] = layout.engine.appendingPathComponent("bin/wine").path
        env["WINEDEBUG"] = "-all"
        env["SikarugirAppWine11"] = "1"
        env["WINEDLLPATH_DXMT"] = layout.path("runtime/dxmt/wine").path
        env["WINEDLLOVERRIDES"] = "d3d11,dxgi,d3d10core,winemetal=b;winemenubuilder.exe="
        env["DYLD_FALLBACK_LIBRARY_PATH"] = [
            layout.path("runtime/support").path,
            layout.path("runtime/support/GStreamer.framework/Libraries").path,
            layout.engine.appendingPathComponent("lib/wine/x86_64-unix").path,
            layout.path("runtime/dxmt/wine/x86_64-unix").path,
            "/usr/lib"
        ].joined(separator: ":")
        return env
    }

    static func sha256(_ file: URL) throws -> String {
        let fd = open(file.path, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
        guard fd >= 0 else { throw AppFailure.message("A required file could not be read safely.") }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        defer { try? handle.close() }
        var before = stat()
        guard fstat(fd, &before) == 0, (before.st_mode & S_IFMT) == S_IFREG else {
            throw AppFailure.message("A required input is not a regular file.")
        }
        var hash = SHA256()
        do {
            while let data = try handle.read(upToCount: 1024 * 1024), !data.isEmpty { hash.update(data: data) }
        } catch { throw AppFailure.message("A required file could not be read completely.") }
        var after = stat()
        guard fstat(fd, &after) == 0, before.st_size == after.st_size,
              before.st_mtimespec.tv_sec == after.st_mtimespec.tv_sec,
              before.st_mtimespec.tv_nsec == after.st_mtimespec.tv_nsec else {
            throw AppFailure.message("A file changed while it was being checked. Finish the download and try again.")
        }
        return hash.finalize().map { String(format: "%02x", $0) }.joined()
    }

    static func preparePrivateDirectory(_ url: URL) throws {
        guard url.isFileURL, url.path.hasPrefix("/"), url.path != "/", url.path != NSHomeDirectory(),
              url.standardized.path == url.path else {
            throw AppFailure.message("The installation destination is not a valid local directory.")
        }
        var cursor = URL(fileURLWithPath: "/", isDirectory: true)
        for component in url.pathComponents.dropFirst() {
            cursor.appendPathComponent(component, isDirectory: true)
            var value = stat()
            if lstat(cursor.path, &value) == 0 {
                guard (value.st_mode & S_IFMT) == S_IFDIR else {
                    throw AppFailure.message("The installation destination contains a link or a non-directory. Existing files were preserved.")
                }
            } else {
                guard errno == ENOENT, mkdir(cursor.path, 0o700) == 0 else {
                    throw AppFailure.message("The installation directory could not be created.")
                }
            }
        }
        var value = stat()
        guard lstat(url.path, &value) == 0, value.st_uid == getuid(), (value.st_mode & 0o077) == 0 else {
            throw AppFailure.message("The installation directory must belong to you and must not be writable by other users.")
        }
    }

    static func run(_ executable: URL, _ arguments: [String],
                    environment: [String: String]? = nil, directory: URL? = nil,
                    timeout: TimeInterval = 60, capture: Bool = false) throws -> CommandResult {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.environment = environment ?? ["PATH": "/usr/bin:/bin:/usr/sbin:/sbin", "LC_ALL": "C"]
        process.currentDirectoryURL = directory
        process.standardInput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        // An unlinked regular file cannot hold up EOF when Wine spawns helpers.
        var tempFD: Int32 = -1
        var output: FileHandle? = nil
        if capture {
            var template = Array((NSTemporaryDirectory() + "orbit-output-XXXXXX").utf8CString)
            tempFD = mkstemp(&template)
            guard tempFD >= 0 else { throw AppFailure.message("A temporary diagnostic buffer could not be created.") }
            template.withUnsafeBufferPointer { pointer in _ = unlink(pointer.baseAddress!) }
            _ = fcntl(tempFD, F_SETFD, FD_CLOEXEC)
            output = FileHandle(fileDescriptor: tempFD, closeOnDealloc: true)
        }
        defer { try? output?.close() }
        process.standardOutput = output ?? FileHandle.nullDevice
        do { try process.run() }
        catch { throw AppFailure.message("A required program could not start. Check the installation and macOS security prompts.") }
        let deadline = ProcessInfo.processInfo.systemUptime + timeout
        while process.isRunning {
            var oversized = false
            if capture {
                var info = stat()
                oversized = fstat(tempFD, &info) != 0 || info.st_size > 2 * 1024 * 1024
            }
            if ProcessInfo.processInfo.systemUptime > deadline || oversized {
                // Only the Process instance this call created is stopped.
                if process.isRunning { process.terminate() }
                let grace = ProcessInfo.processInfo.systemUptime + 3
                while process.isRunning && ProcessInfo.processInfo.systemUptime < grace { Thread.sleep(forTimeInterval: 0.1) }
                // Do not use numeric PID-based SIGKILL or terminate descendants.
                throw AppFailure.message("An operation exceeded its limit. Any remaining Wine windows were preserved. Close them normally before retrying.")
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        process.waitUntilExit()
        var text = ""
        if let output = output {
            do {
                try output.seek(toOffset: 0)
                let data = try output.read(upToCount: 2 * 1024 * 1024 + 1) ?? Data()
                guard data.count <= 2 * 1024 * 1024 else { throw AppFailure.message("Diagnostic output exceeded its limit.") }
                text = String(decoding: data, as: UTF8.self)
            } catch let safe as AppFailure { throw safe }
            catch { throw AppFailure.message("A diagnostic result could not be read.") }
        }
        return CommandResult(status: process.terminationStatus, output: text)
    }

    static func isWineCommand(_ command: String) -> Bool {
        let normalized = command.replacingOccurrences(of: "\\", with: "/").lowercased()
        let name = normalized.split(separator: "/").last.map(String.init) ?? ""
        return Set(["wine", "wine64", "wine-preloader", "wine64-preloader", "wineloader", "wineserver",
                    "darkorbit.exe", "darkorbitlauncher.exe", "darkorbitlauncher.exe-temp.exe",
                    "vuplex webview.vuplex", "vuplex webview_real.vuplex"]).contains(name)
    }
    static func activeWineCount() throws -> Int {
        let snapshot = try run(URL(fileURLWithPath: "/bin/ps"), ["-ww", "-axo", "comm="], timeout: 5, capture: true)
        guard snapshot.status == 0 else { throw AppFailure.message("Running applications could not be checked safely. No game was started or stopped.") }
        let commands = snapshot.output.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        guard !commands.isEmpty else { throw AppFailure.message("The process check was empty. No game was started or stopped.") }
        return commands.filter(isWineCommand).count
    }
    static func ensureQuiet() throws {
        guard try activeWineCount() == 0 else {
            throw AppFailure.message("A Wine application or DarkOrbit is still open. Close it normally before continuing. No running application has been stopped.")
        }
    }

    static func checkHost() throws {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        guard version.majorVersion > 14 || (version.majorVersion == 14 && version.minorVersion >= 6) else {
            throw AppFailure.message("This setup requires macOS 14.6 or later. Only the configurations in the compatibility guide have been tested.")
        }
        let rosetta = try run(URL(fileURLWithPath: "/usr/bin/arch"), ["-x86_64", "/usr/bin/true"], timeout: 10)
        guard rosetta.status == 0 else {
            throw AppFailure.message("Rosetta is required for the Windows runtime. Install it using Apple's supported process, then try again.")
        }
    }

    static func launch(_ layout: InstallationLayout, status: @escaping (String) -> Void) throws {
        let lock = try InstallationLock(layout: layout)
        defer { withExtendedLifetime(lock) {} }
        try checkHost()
        try ensureQuiet()
        status("Checking the installation...")
        try Installer.verify(at: layout)
        let baselineMatches = try Installer.gameCompatibility(at: layout)
        if !baselineMatches {
            status("The official game has changed since setup. Compatibility with this version has not been verified.")
        }
        let launcher = layout.game.appendingPathComponent("DarkorbitLauncher.exe")
        let process = Process()
        process.executableURL = layout.engine.appendingPathComponent("bin/wine")
        process.arguments = [launcher.path]
        process.currentDirectoryURL = layout.game
        process.environment = environment(layout)
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { throw AppFailure.message("The official launcher could not start. Check macOS security prompts and use Verify Installation.") }
        status(baselineMatches
            ? "The official launcher is open. Keep this app open while playing. Close the game normally when finished."
            : "The official launcher is open with an updated game version. Compatibility has not been verified. Keep this app open while playing.")
        process.waitUntilExit()
        // The updater can exit after spawning a replacement. The server remains
        // alive while its Windows clients are connected to this dedicated prefix.
        let waiter = Process()
        waiter.executableURL = layout.engine.appendingPathComponent("bin/wineserver")
        waiter.arguments = ["-w"]
        waiter.environment = environment(layout)
        waiter.standardInput = FileHandle.nullDevice
        waiter.standardOutput = FileHandle.nullDevice
        waiter.standardError = FileHandle.nullDevice
        do { try waiter.run() } catch { throw AppFailure.message("The game may still be running. Close it normally before another operation.") }
        waiter.waitUntilExit()
        guard waiter.terminationStatus == 0 else { throw AppFailure.message("The game's shutdown could not be confirmed. Close any remaining game windows normally.") }
        // Independently fail closed if any Wine session remains. This deliberately
        // avoids guessing ownership of another Wine application's processes.
        try ensureQuiet()
        if process.terminationStatus != 0 {
            throw AppFailure.message("The official launcher exited with an error. No game output was retained. Check the installation and the official game's status.")
        }
        status("The game session has ended. You can play again or close this app.")
    }

    private static func recognizedReceipt(_ file: URL) -> Bool {
        let fd = open(file.path, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
        guard fd >= 0 else { return false }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        defer { try? handle.close() }
        var info = stat()
        guard fstat(fd, &info) == 0, (info.st_mode & S_IFMT) == S_IFREG,
              info.st_uid == getuid(), info.st_nlink == 1, info.st_size < 65536 else { return false }
        guard let data = try? handle.read(upToCount: 65536),
              let value = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
        return value["format"] as? String == "darkorbit-macos-local-install-v1"
    }

    static func trashInstallation(_ layout: InstallationLayout) throws {
        let lock = try InstallationLock(layout: layout)
        defer { withExtendedLifetime(lock) {} }
        try ensureQuiet()
        // Require our own receipt before moving a folder. Never accept an arbitrary
        // directory as an installation and never permanently delete user data.
        let receipt = layout.path("installation.json")
        let incomplete = layout.path("installation-incomplete.json")
        let names = (try? FileManager.default.contentsOfDirectory(atPath: layout.root.path)) ?? []
        let emptySetup = Set(names).isSubset(of: [".operation.lock"])
        guard emptySetup || recognizedReceipt(receipt) || recognizedReceipt(incomplete) else {
            throw AppFailure.message("No recognized installation was found. Existing files were preserved.")
        }
        do { try FileManager.default.trashItem(at: layout.root, resultingItemURL: nil) }
        catch { throw AppFailure.message("The installation could not be moved to Trash. Close its windows and try again. Existing files were preserved.") }
    }
}
