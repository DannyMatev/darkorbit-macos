import Foundation
import Darwin

@main
struct InstallerTests {
    static let fm = FileManager.default
    static var checks = 0

    static func require(_ condition: @autoclosure () throws -> Bool, _ label: String) throws {
        guard try condition() else { throw AppFailure.message("Fixture failed: " + label) }
        checks += 1
    }

    static func expectFailure(_ phrase: String, _ operation: () throws -> Void) throws {
        do {
            try operation()
            throw AppFailure.message("Fixture unexpectedly succeeded: " + phrase)
        } catch let AppFailure.message(message) {
            try require(message.contains(phrase), "expected rejection reason: " + phrase + " (received: " + message + ")")
            try require(!message.contains(NSHomeDirectory()) && !message.contains("installer fixtures "), "sanitized error")
        }
    }

    static func directory(_ parent: URL, _ name: String) throws -> URL {
        let url = parent.appendingPathComponent(name)
        try fm.createDirectory(at: url, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        return url
    }

    static func selectedFiles(_ root: URL) throws -> [URL] {
        try Installer.requiredInputNames.map { name in
            let file = root.appendingPathComponent(name)
            try Data("synthetic setup fixture\n".utf8).write(to: file)
            return file
        }
    }

    static func install(_ layout: InstallationLayout, _ inputs: [URL], cancelled: @escaping () -> Bool = { false }) throws {
        try Installer.install(at: layout, inputs: inputs, progress: { _ in }, cancelled: cancelled)
    }

    static func main() {
        do { try runTests() }
        catch let AppFailure.message(message) {
            print("Installer fixtures failed: " + message)
            exit(1)
        } catch {
            print("Installer fixtures failed: a fixture file operation could not finish.")
            exit(1)
        }
    }

    static func runTests() throws {
        // These fixtures contain no accepted archive, so none can execute Wine or tar.
        let templateName = "Template-1.0.21.tar.xz"
        let templateHash = "bbe996e4e4375318485953d0c7818b7b4b0a4dc1f13303bcc584f99f7602f78d"
        func placeholder(_ name: String = templateName, _ hash: String = templateHash,
                         _ path: String = "Contents/drive_c", _ target: String = "SharedSupport/prefix/drive_c") -> Bool {
            Installer.permitsUnusedTemplatePlaceholder(archiveName: name, archiveHash: hash,
                                                       relativePath: path, linkTarget: target)
        }
        try require(placeholder(), "only the known unused template placeholder is allowed")
        try require(!placeholder("OtherTemplate.tar.xz"), "another archive name has no exception")
        try require(!placeholder(templateName, String(repeating: "0", count: 64)), "another archive hash has no exception")
        try require(!placeholder(templateName, templateHash, "Contents/Frameworks/drive_c"), "runtime location has no exception")
        try require(!placeholder(templateName, templateHash, "Contents/drive_c", "../../outside"), "escaping placeholder target rejected")
        try require(!placeholder(templateName, templateHash, "Contents/drive_c", "/SharedSupport/prefix/drive_c"), "absolute placeholder target rejected")
        try RuntimeCore.checkHost()
        try RuntimeCore.ensureQuiet()
        let root = URL(fileURLWithPath: "/private/tmp", isDirectory: true)
            .appendingPathComponent("installer fixtures " + UUID().uuidString, isDirectory: true)
        try fm.createDirectory(at: root, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        defer { try? fm.removeItem(at: root) }
        let selection = try directory(root, "selected downloads")
        let files = try selectedFiles(selection)
        let originals = try files.map { try Data(contentsOf: $0) }

        let rejected = InstallationLayout(root: try directory(root, "wrong digest"))
        try expectFailure("does not match the supported official version") { try install(rejected, files) }
        for (index, file) in files.enumerated() {
            try require(try Data(contentsOf: file) == originals[index], "original input preserved")
        }
        try require(!fm.fileExists(atPath: rejected.path("runtime").path), "bad input creates no runtime")
        try require(!fm.fileExists(atPath: rejected.path("state").path), "bad input creates no prefix")
        try require(!fm.fileExists(atPath: rejected.path("installation.json").path), "bad input creates no completed receipt")
        let marker = try Data(contentsOf: rejected.path("installation-incomplete.json"))
        try expectFailure("Setup needs the four required files") { try install(rejected, []) }
        try require(try Data(contentsOf: rejected.path("installation-incomplete.json")) == marker, "resume preserves incomplete receipt")
        let stages = try fm.contentsOfDirectory(atPath: rejected.root.path).filter { $0.hasPrefix(".install-stage-") }
        try require(stages.count == 1, "resume reuses one private stage")

        let linkedSelection = try directory(root, "linked downloads")
        var linkedFiles = try selectedFiles(linkedSelection)
        try fm.removeItem(at: linkedFiles[0])
        try fm.createSymbolicLink(at: linkedFiles[0], withDestinationURL: files[0])
        let linked = InstallationLayout(root: try directory(root, "linked input"))
        try expectFailure("could not be opened") { try install(linked, linkedFiles) }
        try require(try Data(contentsOf: files[0]) == originals[0], "linked source preserved")
        linkedFiles.removeAll()

        let duplicate = InstallationLayout(root: try directory(root, "duplicate input"))
        try expectFailure("Select the four required files") { try install(duplicate, [files[0], files[0], files[2], files[3]]) }

        let cancelled = InstallationLayout(root: try directory(root, "cancelled setup"))
        try expectFailure("cancelled at a safe stopping point") { try install(cancelled, files, cancelled: { true }) }
        try require(try fm.contentsOfDirectory(atPath: cancelled.root.path).isEmpty, "early cancellation creates no marker")

        let occupied = InstallationLayout(root: try directory(root, "occupied setup"))
        let userFile = occupied.path("keep.txt")
        try Data("preserve this file".utf8).write(to: userFile)
        try expectFailure("contains unrecognized files") { try install(occupied, files) }
        try require(try String(contentsOf: userFile, encoding: .utf8) == "preserve this file", "unrecognized files preserved")

        let publicRoot = InstallationLayout(root: try directory(root, "public permissions"))
        guard chmod(publicRoot.root.path, 0o755) == 0 else { throw AppFailure.message("Fixture permissions could not be set") }
        try expectFailure("must be private") { try install(publicRoot, files) }
        try require(try fm.contentsOfDirectory(atPath: publicRoot.root.path).isEmpty, "nonprivate root preserved")

        let alias = root.appendingPathComponent("linked setup")
        try fm.createSymbolicLink(at: alias, withDestinationURL: cancelled.root)
        try expectFailure("contains a link") { try install(InstallationLayout(root: alias), files) }

        let malformed = InstallationLayout(root: try directory(root, "invalid receipt"))
        try Data("{}".utf8).write(to: malformed.path("installation.json"))
        try expectFailure("could not be verified") { try Installer.verify(at: malformed) }
        try require(try String(contentsOf: malformed.path("installation.json"), encoding: .utf8) == "{}", "invalid receipt preserved")

        let drift = InstallationLayout(root: try directory(root, "configuration drift"))
        var altered = try JSONSerialization.jsonObject(with: marker) as! [String: Any]
        altered["configurationRevision"] = "different-configuration"
        try JSONSerialization.data(withJSONObject: altered).write(to: drift.path("installation-incomplete.json"))
        try expectFailure("not recognized") { try install(drift, files) }
        try require(!fm.fileExists(atPath: drift.path("runtime").path), "configuration drift does not create a runtime")

        try RuntimeCore.ensureQuiet()
        print("Installer rejection checks passed: \(checks). No accepted archives, Wine, or game were executed.")
    }
}
