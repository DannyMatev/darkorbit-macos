import Foundation
import Darwin

@main
struct CoreTests {
    static func require(_ condition: @autoclosure () -> Bool, _ label: String) {
        if !condition() { fputs("FAIL: \(label)\n", stderr); exit(1) }
    }
    static func refuses(_ label: String, _ body: () throws -> Void) {
        do { try body(); fputs("FAIL: \(label)\n", stderr); exit(1) }
        catch is AppFailure { }
        catch { fputs("FAIL: unsafe error type\n", stderr); exit(1) }
    }
    static func main() {
        do { try runChecks() }
        catch { fputs("FAIL: a core check could not complete; raw errors withheld.\n", stderr); exit(1) }
    }
    static func runChecks() throws {
        let parent = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
            .appendingPathComponent("build/orbit tests " + UUID().uuidString)
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: parent) }
        let layout = InstallationLayout(root: parent.appendingPathComponent("space in path"))
        let env = RuntimeCore.environment(layout)
        require(env["WINEPREFIX"] == layout.prefix.path, "prefix path")
        require(env["WINEDLLPATH_DXMT"] == layout.path("runtime/dxmt/wine").path, "DXMT precedence")
        require(env["WINEDLLPATH"] == nil, "no generic DLL path")
        require(env["SikarugirAppWine11"] == "1", "engine initialization")
        require(env["WINEDEBUG"] == "-all", "raw diagnostics disabled")
        require(env["WINEPREFIX"]?.contains("\"") == false, "no literal shell quoting")
        require(env["DYLD_INSERT_LIBRARIES"] == nil, "no injected libraries")
        let file = parent.appendingPathComponent("fixture.txt")
        try Data("abc".utf8).write(to: file)
        let digest = try RuntimeCore.sha256(file)
        require(digest == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "SHA-256")
        let link = parent.appendingPathComponent("linked.txt")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: file)
        refuses("hash symlink") { _ = try RuntimeCore.sha256(link) }
        let linkDirectory = parent.appendingPathComponent("linked directory")
        try FileManager.default.createSymbolicLink(at: linkDirectory, withDestinationURL: parent)
        refuses("destination symlink") { try RuntimeCore.preparePrivateDirectory(linkDirectory.appendingPathComponent("nested")) }
        print("Checking private installation lock"); fflush(stdout)
        var first: InstallationLock? = try InstallationLock(layout: layout)
        require(first != nil, "first lock")
        refuses("duplicate operation") { _ = try InstallationLock(layout: layout) }
        first = nil
        let second = try InstallationLock(layout: layout)
        withExtendedLifetime(second) {}
        require(RuntimeCore.isWineCommand("C:\\DarkOrbitFree\\Game\\DarkOrbit.exe"), "Windows executable scope")
        require(RuntimeCore.isWineCommand("/some/runtime/bin/wineserver"), "Wine server scope")
        require(!RuntimeCore.isWineCommand("/Applications/TextEdit.app/TextEdit"), "unrelated app")
        let output = try RuntimeCore.run(URL(fileURLWithPath: "/usr/bin/printf"), ["fixture"], timeout: 2, capture: true)
        require(output.status == 0 && output.output == "fixture", "bounded capture")
        let failure = try RuntimeCore.run(URL(fileURLWithPath: "/usr/bin/false"), [], timeout: 2)
        require(failure.status != 0, "nonzero status preserved")
        print("PASS: core configuration, hashing, destination safety, duplicate lock, process classification and bounded commands")
    }
}
