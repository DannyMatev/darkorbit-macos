import Foundation
import Darwin

// Only these exact upstream payloads are accepted. This is not a general archive tool.
enum Installer {
    private struct Input {
        let name: String
        let sha256: String
        let archiveRoot: String?
    }

    private static let inputs = [
        Input(name: "WS12WineSikarugir11.0_1.tar.xz", sha256: "67e29fb3d74f363af39c69ba11f9b13a79812c5db07cf4748672658e4a200a0e", archiveRoot: "wswine.bundle"),
        Input(name: "Template-1.0.21.tar.xz", sha256: "bbe996e4e4375318485953d0c7818b7b4b0a4dc1f13303bcc584f99f7602f78d", archiveRoot: "Template-1.0.21.app"),
        Input(name: "DarkOrbit_Version1.1.113.zip", sha256: "25dbc9ba125b35ef08beb3d239076a89b48667377d225775a9703323f7586073", archiveRoot: "DarkOrbit_Version1.1.113"),
        Input(name: "windowsdesktop-runtime-6.0.36-win-x64.exe", sha256: "0d20debb26fc8b2bc84f25fbd9d4596a6364af8517ebf012e8b871127b798941", archiveRoot: nil)
    ]
    static var requiredInputNames: [String] { inputs.map(\.name) }
    private static let fm = FileManager.default
    private static let receiptFormat = "darkorbit-macos-local-install-v1"
    private static let configurationRevision = "sikarugir11-dxmt-win64-v1"
    private static let environmentPlan = [
        "PATH": "$INSTALL_ROOT/runtime/wswine.bundle/bin:/usr/bin:/bin:/usr/sbin:/sbin",
        "LANG": "en_US.UTF-8", "LC_ALL": "en_US.UTF-8",
        "WINEPREFIX": "$INSTALL_ROOT/state/prefix", "WINEARCH": "win64",
        "WINESERVER": "$INSTALL_ROOT/runtime/wswine.bundle/bin/wineserver",
        "WINELOADER": "$INSTALL_ROOT/runtime/wswine.bundle/bin/wine", "WINEDEBUG": "-all",
        "SikarugirAppWine11": "1", "WINEDLLPATH_DXMT": "$INSTALL_ROOT/runtime/dxmt/wine",
        "WINEDLLOVERRIDES": "d3d11,dxgi,d3d10core,winemetal=b;winemenubuilder.exe=",
        "DYLD_FALLBACK_LIBRARY_PATH": "$INSTALL_ROOT/runtime/support:$INSTALL_ROOT/runtime/support/GStreamer.framework/Libraries:$INSTALL_ROOT/runtime/wswine.bundle/lib/wine/x86_64-unix:$INSTALL_ROOT/runtime/dxmt/wine/x86_64-unix:/usr/lib"
    ]
    private static let components = ["wswine.bundle", "support", "dxmt"]
    private static let gameFiles = [
        "DarkorbitLauncher.exe", "DarkorbitLauncher.dll", "DarkorbitLauncher.runtimeconfig.json",
        "DarkorbitLauncher.deps.json", "DarkOrbit.exe", "UnityPlayer.dll", "GameAssembly.dll",
        "main.hash", "update.ini", "DarkOrbit_Data/Plugins/x86/VuplexWebViewChromium/Vuplex WebView.vuplex",
        "DarkOrbit_Data/Plugins/x86/VuplexWebViewChromium/libcef.dll"
    ]
    private static let requiredRuntimeFiles = [
        "wswine.bundle/bin/wine", "wswine.bundle/bin/wineserver",
        "wswine.bundle/lib/wine/x86_64-unix/ntdll.so",
        "dxmt/wine/i386-windows/d3d11.dll", "dxmt/wine/i386-windows/dxgi.dll",
        "dxmt/wine/i386-windows/winemetal.dll", "dxmt/wine/x86_64-windows/d3d11.dll",
        "dxmt/wine/x86_64-windows/dxgi.dll", "dxmt/wine/x86_64-windows/winemetal.dll",
        "dxmt/wine/x86_64-unix/winemetal.so"
    ]

    private struct Receipt: Codable {
        let format: String
        let configurationRevision: String
        let environmentPlan: [String: String]
        let stage: String
        let startedAt: String
        var phase: String
        var completedAt: String?
        var architectureProbes: [String]?
        var dotnetVersion: String?
    }

    private struct Entry: Codable, Equatable {
        let kind: String
        let size: Int64?
        let executableBits: UInt16?
        let sha256: String?
        let target: String?
    }

    private struct RuntimeManifest: Codable, Equatable {
        let format: String
        let inputHashes: [String: String]
        let entries: [String: Entry]
    }

    private struct GameBaseline: Codable {
        let format: String
        let version: String
        let files: [String: String]
    }

    static func install(at layout: InstallationLayout, inputs selected: [URL],
                        progress: @escaping (String) -> Void,
                        cancelled: @escaping () -> Bool) throws {
        do {
            try installChecked(at: layout, selected: selected, progress: progress, cancelled: cancelled)
        } catch let error as AppFailure {
            throw error
        } catch {
            throw AppFailure.message("Setup stopped because a file or system check failed. Existing files were preserved. Retry setup after resolving the problem. This app did not save command output.")
        }
    }

    static func verify(at layout: InstallationLayout) throws {
        do {
            try validateRoot(layout.root)
            let receipt: Receipt = try readJSON(layout.path("installation.json"))
            guard receipt.format == receiptFormat, receipt.configurationRevision == configurationRevision,
                  receipt.environmentPlan == environmentPlan, receipt.phase == "complete",
                  receipt.architectureProbes == ["AMD64", "x86"], receipt.dotnetVersion == "6.0.36" else {
                throw AppFailure.message("Setup has not completed. Use Set Up to finish it.")
            }
            try verifyConfiguration(layout)
            try verifyRuntime(layout)
            try verifyPrefix(layout)
            try requireGameFiles(layout.game)
            _ = try baseline(layout)
            try requireDotnet(layout)
        } catch let error as AppFailure {
            throw error
        } catch {
            throw AppFailure.message("The installation could not be verified. Existing files were preserved.")
        }
    }

    // Official updates are retained. A changed baseline is a warning, not a rollback.
    static func gameCompatibility(at layout: InstallationLayout) throws -> Bool {
        do {
            try validateRoot(layout.root)
            let expected = try baseline(layout)
            try requireGameFiles(layout.game)
            for relative in gameFiles {
                if try RuntimeCore.sha256(layout.game.appendingPathComponent(relative)) != expected.files[relative] {
                    return false
                }
            }
            return true
        } catch let error as AppFailure {
            throw error
        } catch {
            throw AppFailure.message("Game version compatibility could not be checked. Existing game files were preserved.")
        }
    }

    private static func installChecked(at layout: InstallationLayout, selected: [URL],
                                       progress: @escaping (String) -> Void,
                                       cancelled: @escaping () -> Bool) throws {
        try validateRoot(layout.root)
        if exists(layout.path("installation.json")) {
            progress("Checking the existing installation")
            try verify(at: layout)
            progress("The existing installation is ready. Official game updates were preserved.")
            return
        }
        try checkCancellation(cancelled)
        try verifyConfiguration(layout)
        try RuntimeCore.checkHost()
        try RuntimeCore.ensureQuiet()
        let incomplete = layout.path("installation-incomplete.json")
        var receipt: Receipt
        if exists(incomplete) {
            receipt = try readJSON(incomplete)
            guard receipt.format == receiptFormat, receipt.configurationRevision == configurationRevision,
                  receipt.environmentPlan == environmentPlan, validStageName(receipt.stage), receipt.completedAt == nil else {
                throw AppFailure.message("The incomplete setup record is not recognized. Existing files were preserved.")
            }
        } else {
            let names = try fm.contentsOfDirectory(atPath: layout.root.path)
            guard Set(names).isSubset(of: [".operation.lock"]) else {
                throw AppFailure.message("The setup folder contains unrecognized files. Choose a new empty setup folder; nothing was replaced.")
            }
            receipt = Receipt(format: receiptFormat, configurationRevision: configurationRevision,
                              environmentPlan: environmentPlan, stage: ".install-stage-" + UUID().uuidString,
                              startedAt: timestamp(), phase: "inputs")
            try writeJSON(receipt, to: incomplete)
        }
        let stage = layout.path(receipt.stage)
        try createDirectory(stage)
        try requirePrivateDirectory(stage)
        let inputDirectory = stage.appendingPathComponent("inputs")
        try createDirectory(inputDirectory)
        let staged = try prepareInputs(selected, at: inputDirectory, progress: progress, cancelled: cancelled)
        try checkCancellation(cancelled)
        receipt.phase = "runtime"
        try writeJSON(receipt, to: incomplete)
        try prepareRuntime(layout, stage: stage, staged: staged, progress: progress, cancelled: cancelled)
        try checkCancellation(cancelled)
        receipt.phase = "prefix"
        try writeJSON(receipt, to: incomplete)
        progress("Preparing the Windows compatibility environment")
        try preparePrefix(layout, cancelled: cancelled)
        try checkCancellation(cancelled)
        receipt.phase = "game"
        try writeJSON(receipt, to: incomplete)
        try prepareGame(layout, stage: stage, staged: staged, progress: progress, cancelled: cancelled)
        try checkCancellation(cancelled)
        receipt.phase = "dotnet"
        try writeJSON(receipt, to: incomplete)
        progress("Installing and checking the official launcher's Windows components")
        try prepareDotnet(layout, installer: staged[inputs[3].name]!, cancelled: cancelled)
        try RuntimeCore.ensureQuiet()
        try checkCancellation(cancelled)
        receipt.phase = "complete"
        receipt.completedAt = timestamp()
        receipt.architectureProbes = ["AMD64", "x86"]
        receipt.dotnetVersion = "6.0.36"
        // Completion is published last; an interrupted installation is never ready.
        try writeJSON(receipt, to: layout.path("installation.json"), replace: false)
        try verify(at: layout)
        try removeRegularFile(incomplete)
        // This exact installer-created private stage contains no prefix or account data.
        try requirePrivateDirectory(stage)
        try fm.removeItem(at: stage)
        progress("Setup is complete. You can launch the official game.")
    }

    private static func prepareInputs(_ selected: [URL], at directory: URL,
                                      progress: (String) -> Void, cancelled: () -> Bool) throws -> [String: URL] {
        let names = selected.map(\.lastPathComponent)
        guard selected.isEmpty || (selected.count == inputs.count && Set(names) == Set(requiredInputNames)) else {
            throw AppFailure.message("Select the four required files with their original filenames. No files were extracted or executed.")
        }
        var result: [String: URL] = [:]
        for input in inputs {
            try checkCancellation(cancelled)
            let destination = directory.appendingPathComponent(input.name)
            if !exists(destination) {
                guard let source = selected.first(where: { $0.lastPathComponent == input.name }) else {
                    throw AppFailure.message("Setup needs the four required files. Select them to continue; existing setup progress will be preserved.")
                }
                progress("Copying " + input.name)
                let partial = directory.appendingPathComponent(".copy-" + UUID().uuidString)
                do {
                    try copyPrivate(source, to: partial, cancelled: cancelled)
                    try publish(partial, to: destination)
                } catch {
                    // A partial input is always our own regular file, never installation state.
                    try? removeRegularFile(partial)
                    throw error
                }
            }
            try requireRegularFile(destination, owner: true)
            let attributes = try metadata(destination)
            guard attributes.st_mode & 0o222 == 0 else {
                throw AppFailure.message("A private setup input is unexpectedly writable. Existing files were preserved.")
            }
            progress("Verifying " + input.name)
            guard try RuntimeCore.sha256(destination) == input.sha256 else {
                // Removing only the rejected private copy permits selecting a corrected download.
                try removeRegularFile(destination)
                throw AppFailure.message("A selected file does not match the supported official version. Download the exact listed version and retry. The original download was not changed.")
            }
            result[input.name] = destination
        }
        return result
    }

    private static func prepareRuntime(_ layout: InstallationLayout, stage: URL, staged: [String: URL],
                                       progress: (String) -> Void, cancelled: () -> Bool) throws {
        let target = layout.path("runtime")
        if components.allSatisfy({ exists(target.appendingPathComponent($0)) }) && exists(layout.path("runtime-manifest.json")) {
            progress("Checking the installed compatibility components")
            try verifyRuntime(layout)
            return
        }
        try checkCancellation(cancelled)
        progress("Preparing the compatibility components")
        let extraction = stage.appendingPathComponent("extract-" + UUID().uuidString)
        try createDirectory(extraction)
        let engine = try extract(inputs[0], from: staged[inputs[0].name]!, into: extraction.appendingPathComponent("engine"))
        try checkCancellation(cancelled)
        let template = try extract(inputs[1], from: staged[inputs[1].name]!, into: extraction.appendingPathComponent("template"))
        let candidate = extraction.appendingPathComponent("runtime")
        try createDirectory(candidate)
        try publish(engine, to: candidate.appendingPathComponent("wswine.bundle"))
        let support = candidate.appendingPathComponent("support")
        try createDirectory(support)
        let frameworks = template.appendingPathComponent("Contents/Frameworks")
        try requireDirectory(frameworks)
        for file in try fm.contentsOfDirectory(at: frameworks, includingPropertiesForKeys: nil) {
            if ["renderer", "SikarugirSdk.framework"].contains(file.lastPathComponent) { continue }
            try fm.copyItem(at: file, to: support.appendingPathComponent(file.lastPathComponent))
        }
        try fm.copyItem(at: frameworks.appendingPathComponent("renderer/dxmt"), to: candidate.appendingPathComponent("dxmt"))
        let expected = RuntimeManifest(format: receiptFormat, inputHashes: pinMap(), entries: try tree(candidate))
        try validateRuntimeShape(candidate, manifest: expected)
        let manifestURL = layout.path("runtime-manifest.json")
        if exists(manifestURL) {
            let saved: RuntimeManifest = try readJSON(manifestURL)
            guard saved == expected else {
                throw AppFailure.message("The saved runtime record differs from the supported components. Existing files were preserved.")
            }
        } else {
            guard try !exists(target) || fm.contentsOfDirectory(atPath: target.path).isEmpty else {
                throw AppFailure.message("Existing runtime files have no trusted setup record. Nothing was replaced.")
            }
            try writeJSON(expected, to: manifestURL, replace: false)
        }
        try createDirectory(target)
        for name in components {
            try checkCancellation(cancelled)
            let source = candidate.appendingPathComponent(name)
            let destination = target.appendingPathComponent(name)
            if exists(destination) {
                guard try tree(source) == tree(destination) else {
                    throw AppFailure.message("Existing compatibility components differ from the supported version. Nothing was replaced.")
                }
            } else {
                try publish(source, to: destination)
            }
        }
        try verifyRuntime(layout)
    }

    private static func preparePrefix(_ layout: InstallationLayout, cancelled: () -> Bool) throws {
        try createDirectory(layout.prefix.deletingLastPathComponent())
        if exists(layout.prefix) {
            try verifyPrefix(layout)
        } else {
            try checkCancellation(cancelled)
            try RuntimeCore.ensureQuiet()
            let result = try RuntimeCore.run(layout.engine.appendingPathComponent("bin/wine"), ["wineboot.exe", "--init"],
                                             environment: RuntimeCore.environment(layout), directory: layout.root, timeout: 300)
            guard result.status == 0 else { throw AppFailure.message("The Windows environment could not be initialized. Existing files were preserved.") }
            try waitServer(layout)
            try verifyPrefix(layout)
        }
        for (directory, expected) in [("system32", "AMD64"), ("syswow64", "x86")] {
            try checkCancellation(cancelled)
            try RuntimeCore.ensureQuiet()
            let result = try RuntimeCore.run(layout.engine.appendingPathComponent("bin/wine"),
                                             ["C:\\windows\\" + directory + "\\cmd.exe", "/d", "/c", "echo %PROCESSOR_ARCHITECTURE%"],
                                             environment: RuntimeCore.environment(layout), directory: layout.root, timeout: 60, capture: true)
            try waitServer(layout)
            guard result.status == 0, result.output.trimmingCharacters(in: .whitespacesAndNewlines) == expected else {
                throw AppFailure.message("Both Windows application architectures could not be confirmed. No game was started.")
            }
        }
    }

    private static func prepareGame(_ layout: InstallationLayout, stage: URL, staged: [String: URL],
                                    progress: (String) -> Void, cancelled: () -> Bool) throws {
        if exists(layout.game) {
            try requireGameFiles(layout.game)
            _ = try baseline(layout)
            progress("Keeping the installed game and any official updates")
            return
        }
        try checkCancellation(cancelled)
        progress("Preparing the official game files")
        let extraction = stage.appendingPathComponent("game-" + UUID().uuidString)
        let game = try extract(inputs[2], from: staged[inputs[2].name]!, into: extraction)
        try requireGameFiles(game)
        var hashes: [String: String] = [:]
        for file in gameFiles { hashes[file] = try RuntimeCore.sha256(game.appendingPathComponent(file)) }
        let expected = GameBaseline(format: receiptFormat, version: "1.1.113", files: hashes)
        let baselineURL = layout.path("game-baseline.json")
        if exists(baselineURL) {
            let saved = try baseline(layout)
            guard saved.files == expected.files else {
                throw AppFailure.message("The original game record differs from this supported version. Existing files were preserved.")
            }
        } else {
            try writeJSON(expected, to: baselineURL, replace: false)
        }
        try createDirectory(layout.game.deletingLastPathComponent())
        try checkCancellation(cancelled)
        try RuntimeCore.ensureQuiet()
        try publish(game, to: layout.game)
    }

    private static func prepareDotnet(_ layout: InstallationLayout, installer: URL, cancelled: () -> Bool) throws {
        let configuration = layout.game.appendingPathComponent("DarkorbitLauncher.runtimeconfig.json")
        try requireRegularFile(configuration)
        guard try metadata(configuration).st_size <= 65_536,
              let object = try JSONSerialization.jsonObject(with: Data(contentsOf: configuration)) as? [String: Any],
              let options = object["runtimeOptions"] as? [String: Any],
              let frameworks = options["frameworks"] as? [[String: Any]], frameworks.count == 2,
              Set(frameworks.compactMap { $0["name"] as? String }) == Set(["Microsoft.NETCore.App", "Microsoft.WindowsDesktop.App"]),
              frameworks.allSatisfy({ $0["version"] as? String == "6.0.0" }) else {
            throw AppFailure.message("The official launcher's Windows requirements have changed. Its files were preserved; a compatibility review is needed.")
        }
        if !dotnetFiles(layout).allSatisfy({ exists($0) }) {
            try checkCancellation(cancelled)
            try RuntimeCore.ensureQuiet()
            let result = try RuntimeCore.run(layout.engine.appendingPathComponent("bin/wine"),
                                             [installer.path, "/install", "/quiet", "/norestart"],
                                             environment: RuntimeCore.environment(layout), directory: layout.root, timeout: 600)
            try waitServer(layout)
            guard result.status == 0 else {
                throw AppFailure.message("The Windows components did not finish installing. Retry Set Up after quitting any setup windows; existing progress was preserved.")
            }
        }
        try requireDotnet(layout)
        try checkCancellation(cancelled)
        try RuntimeCore.ensureQuiet()
        let result = try RuntimeCore.run(layout.engine.appendingPathComponent("bin/wine"),
                                         ["C:\\Program Files\\dotnet\\dotnet.exe", "--list-runtimes"],
                                         environment: RuntimeCore.environment(layout), directory: layout.root, timeout: 60, capture: true)
        try waitServer(layout)
        let pattern = #"^Microsoft\.(NETCore|WindowsDesktop)\.App 6\.0\.36 \[[^\r\n]+\]$"#
        let regex = try NSRegularExpression(pattern: pattern)
        var confirmed: Set<String> = []
        for line in result.output.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
            if regex.firstMatch(in: trimmed, range: range) != nil {
                confirmed.insert(trimmed.components(separatedBy: " ")[0])
            }
        }
        guard result.status == 0, confirmed == Set(["Microsoft.NETCore.App", "Microsoft.WindowsDesktop.App"]) else {
            throw AppFailure.message("Both required Windows components could not be confirmed. Setup progress was preserved.")
        }
    }

    private static func waitServer(_ layout: InstallationLayout) throws {
        let result = try RuntimeCore.run(layout.engine.appendingPathComponent("bin/wineserver"), ["-w"],
                                         environment: RuntimeCore.environment(layout), directory: layout.root, timeout: 90)
        guard result.status == 0 else {
            throw AppFailure.message("Windows setup is still active. Quit its windows normally before retrying; no processes were stopped.")
        }
    }

    private static func verifyConfiguration(_ layout: InstallationLayout) throws {
        let actual = RuntimeCore.environment(layout)
        guard environmentPlan.allSatisfy({ key, value in
            actual[key] == value.replacingOccurrences(of: "$INSTALL_ROOT", with: layout.root.path)
        }) else {
            throw AppFailure.message("The runtime configuration differs from the verified setup recipe. A configuration review is needed before continuing.")
        }
    }

    private static func verifyRuntime(_ layout: InstallationLayout) throws {
        let expected: RuntimeManifest = try readJSON(layout.path("runtime-manifest.json"))
        guard expected.format == receiptFormat, expected.inputHashes == pinMap() else {
            throw AppFailure.message("The runtime verification record is not recognized. Existing files were preserved.")
        }
        let runtime = layout.path("runtime")
        try validateRuntimeShape(runtime, manifest: expected)
        guard try tree(runtime) == expected.entries else {
            throw AppFailure.message("Compatibility files have changed or are incomplete. Use a new setup folder; the current installation was preserved.")
        }
    }

    private static func validateRuntimeShape(_ root: URL, manifest: RuntimeManifest) throws {
        try requireDirectory(root)
        guard Set(try fm.contentsOfDirectory(atPath: root.path)) == Set(components),
              requiredRuntimeFiles.allSatisfy({ manifest.entries[$0]?.kind == "file" }),
              !exists(root.appendingPathComponent("support/renderer")),
              !exists(root.appendingPathComponent("support/SikarugirSdk.framework")) else {
            throw AppFailure.message("The compatibility components are incomplete or contain an unsupported component.")
        }
        for name in requiredRuntimeFiles { try requireRegularFile(root.appendingPathComponent(name)) }
        for name in ["wswine.bundle/bin/wine", "wswine.bundle/bin/wineserver"] {
            guard access(root.appendingPathComponent(name).path, X_OK) == 0 else {
                throw AppFailure.message("A compatibility executable is not available. Nothing was started.")
            }
        }
    }

    private static func verifyPrefix(_ layout: InstallationLayout) throws {
        try requireDirectory(layout.prefix)
        for name in ["system.reg", "user.reg"] { try requireRegularFile(layout.prefix.appendingPathComponent(name)) }
    }

    private static func requireGameFiles(_ root: URL) throws {
        try requireDirectory(root)
        for name in gameFiles { try requireRegularFile(root.appendingPathComponent(name)) }
    }

    private static func baseline(_ layout: InstallationLayout) throws -> GameBaseline {
        let baseline: GameBaseline = try readJSON(layout.path("game-baseline.json"))
        guard baseline.format == receiptFormat, baseline.version == "1.1.113",
              Set(baseline.files.keys) == Set(gameFiles), baseline.files.values.allSatisfy(validHash) else {
            throw AppFailure.message("The original game verification record is not recognized. Existing files were preserved.")
        }
        return baseline
    }

    private static func dotnetFiles(_ layout: InstallationLayout) -> [URL] {
        let dotnet = layout.prefix.appendingPathComponent("drive_c/Program Files/dotnet")
        return [dotnet.appendingPathComponent("dotnet.exe")] + ["Microsoft.NETCore.App", "Microsoft.WindowsDesktop.App"].map {
            dotnet.appendingPathComponent("shared/" + $0 + "/6.0.36/" + $0 + ".deps.json")
        }
    }

    private static func requireDotnet(_ layout: InstallationLayout) throws {
        for file in dotnetFiles(layout) { try requireRegularFile(file) }
    }

    private static func extract(_ input: Input, from archive: URL, into directory: URL) throws -> URL {
        guard let expectedRoot = input.archiveRoot, inputs.contains(where: { $0.name == input.name && $0.sha256 == input.sha256 }) else {
            throw AppFailure.message("Only the listed supported archives can be extracted.")
        }
        // Recheck the private copy immediately before handing it to the system extractor.
        try requireRegularFile(archive, owner: true)
        guard try RuntimeCore.sha256(archive) == input.sha256 else {
            throw AppFailure.message("A private setup file changed before extraction. Nothing from it was executed.")
        }
        guard !exists(directory) else { throw AppFailure.message("An extraction destination already exists. It was preserved.") }
        try createDirectory(directory)
        let result = try RuntimeCore.run(URL(fileURLWithPath: "/usr/bin/tar"),
                                         ["-xf", archive.path, "-C", directory.path, "--no-same-owner"],
                                         environment: ["PATH": "/usr/bin:/bin", "LANG": "en_US.UTF-8", "LC_ALL": "en_US.UTF-8"],
                                         directory: directory, timeout: 1200)
        guard result.status == 0, Set(try fm.contentsOfDirectory(atPath: directory.path)) == Set([expectedRoot]) else {
            throw AppFailure.message("A supported archive could not be extracted completely. Setup progress was preserved.")
        }
        let root = directory.appendingPathComponent(expectedRoot)
        try requireDirectory(root)
        // Known pinned archives may contain internal relative symlinks, never external ones.
        try validateExtractedTree(root, input: input)
        return root
    }

    private static func validateExtractedTree(_ root: URL, input: Input) throws {
        var count = 0
        try visit(root, base: root) { relative, file, attributes in
            count += 1
            guard count <= 30_000, attributes.st_size >= 0, attributes.st_size <= 8 * 1024 * 1024 * 1024 else {
                throw AppFailure.message("An extracted archive exceeds the supported limits.")
            }
            let kind = attributes.st_mode & S_IFMT
            guard kind == S_IFDIR || kind == S_IFREG || kind == S_IFLNK else {
                throw AppFailure.message("An extracted archive contains an unsupported file type.")
            }
            if kind == S_IFLNK {
                let target = try fm.destinationOfSymbolicLink(atPath: file.path)
                if permitsUnusedTemplatePlaceholder(archiveName: input.name, archiveHash: input.sha256,
                                                    relativePath: relative, linkTarget: target) {
                    // The upstream wrapper's unused prefix placeholder is never copied
                    // into the selected runtime. All runtime links remain strict.
                    return
                }
                try validateLink(file, within: root)
            }
        }
    }

    static func permitsUnusedTemplatePlaceholder(archiveName: String, archiveHash: String,
                                                 relativePath: String, linkTarget: String) -> Bool {
        archiveName == inputs[1].name && archiveHash == inputs[1].sha256 &&
        relativePath == "Contents/drive_c" && linkTarget == "SharedSupport/prefix/drive_c"
    }

    private static func tree(_ root: URL) throws -> [String: Entry] {
        try requireDirectory(root)
        var entries: [String: Entry] = [:]
        var bytes: Int64 = 0
        try visit(root, base: root) { relative, file, attributes in
            guard entries.count < 25_000 else { throw AppFailure.message("The runtime contains too many files.") }
            let kind = attributes.st_mode & S_IFMT
            if kind == S_IFDIR {
                entries[relative] = Entry(kind: "directory", size: nil, executableBits: nil, sha256: nil, target: nil)
            } else if kind == S_IFLNK {
                try validateLink(file, within: root)
                entries[relative] = Entry(kind: "symlink", size: nil, executableBits: nil, sha256: nil,
                                          target: try fm.destinationOfSymbolicLink(atPath: file.path))
            } else if kind == S_IFREG {
                bytes += attributes.st_size
                guard attributes.st_size >= 0, attributes.st_size <= 1024 * 1024 * 1024, bytes <= 4 * 1024 * 1024 * 1024 else {
                    throw AppFailure.message("The runtime exceeds the supported file size limits.")
                }
                entries[relative] = Entry(kind: "file", size: attributes.st_size, executableBits: attributes.st_mode & 0o111,
                                          sha256: try RuntimeCore.sha256(file), target: nil)
            } else {
                throw AppFailure.message("The runtime contains an unsupported file type.")
            }
        }
        return entries
    }

    private static func visit(_ directory: URL, base: URL,
                              body: (String, URL, stat) throws -> Void) throws {
        for child in try fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil).sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let relative = String(child.path.dropFirst(base.path.count + 1))
            guard validRelative(relative) else { throw AppFailure.message("An unexpected file path was found. Existing files were preserved.") }
            let attributes = try metadata(child)
            try body(relative, child, attributes)
            if attributes.st_mode & S_IFMT == S_IFDIR { try visit(child, base: base, body: body) }
        }
    }

    private static func validateLink(_ file: URL, within root: URL) throws {
        let target = try fm.destinationOfSymbolicLink(atPath: file.path)
        let resolved = try realPath(file)
        let boundary = try realPath(root)
        guard !target.hasPrefix("/"), !target.contains("\\"), !target.contains(":"),
              !target.unicodeScalars.contains(where: { $0.value < 32 || $0.value == 127 }),
              resolved.hasPrefix(boundary + "/"), exists(URL(fileURLWithPath: resolved)) else {
            throw AppFailure.message("A component contains an unsupported external or broken link.")
        }
    }

    private static func realPath(_ file: URL) throws -> String {
        guard let path = realpath(file.path, nil) else {
            throw AppFailure.message("A component link could not be resolved safely.")
        }
        defer { free(path) }
        return String(cString: path)
    }

    private static func validateRoot(_ root: URL) throws {
        guard root.isFileURL, root.path.hasPrefix("/"), root.path != "/", root.path != NSHomeDirectory(),
              root.path == root.standardized.path, !root.path.contains(":"), !root.path.contains("\\"),
              !root.path.unicodeScalars.contains(where: { $0.value < 32 || $0.value == 127 }) else {
            throw AppFailure.message("Choose a normal local setup folder with no special path characters.")
        }
        try requireDirectory(root)
        try requirePrivateDirectory(root)
    }

    private static func requirePrivateDirectory(_ directory: URL) throws {
        try requireDirectory(directory)
        let info = try metadata(directory)
        guard info.st_uid == getuid(), info.st_mode & 0o077 == 0 else {
            throw AppFailure.message("The setup folder must be private to your macOS account. Existing files were preserved.")
        }
    }

    private static func requireDirectory(_ directory: URL) throws {
        try validateParents(directory)
        guard try metadata(directory).st_mode & S_IFMT == S_IFDIR else {
            throw AppFailure.message("A required setup folder is missing or is not a normal directory.")
        }
    }

    private static func requireRegularFile(_ file: URL, owner: Bool = false) throws {
        try validateParents(file.deletingLastPathComponent())
        let info = try metadata(file)
        guard info.st_mode & S_IFMT == S_IFREG, (!owner || info.st_uid == getuid()), info.st_nlink == 1 else {
            throw AppFailure.message("A required file is missing, linked, or not a regular file. Existing files were preserved.")
        }
    }

    private static func validateParents(_ directory: URL) throws {
        var current = URL(fileURLWithPath: "/", isDirectory: true)
        for component in directory.pathComponents.dropFirst() {
            current.appendPathComponent(component, isDirectory: true)
            guard try metadata(current).st_mode & S_IFMT == S_IFDIR else {
                throw AppFailure.message("The setup path contains a link or a non-directory. Existing files were preserved.")
            }
        }
    }

    private static func createDirectory(_ directory: URL) throws {
        if exists(directory) { try requireDirectory(directory); return }
        let parent = directory.deletingLastPathComponent()
        if !exists(parent) { try createDirectory(parent) }
        try requireDirectory(parent)
        guard mkdir(directory.path, 0o700) == 0 else {
            throw AppFailure.message("A private setup folder could not be created. Existing files were preserved.")
        }
    }

    private static func copyPrivate(_ source: URL, to destination: URL, cancelled: () -> Bool) throws {
        guard source.isFileURL else { throw AppFailure.message("Choose files already downloaded to this Mac.") }
        let input = open(source.path, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
        guard input >= 0 else { throw AppFailure.message("A selected file could not be opened. Choose an ordinary downloaded file.") }
        defer { close(input) }
        var information = stat()
        guard fstat(input, &information) == 0, information.st_mode & S_IFMT == S_IFREG,
              information.st_size > 0, information.st_size <= 8 * 1024 * 1024 * 1024 else {
            throw AppFailure.message("A selected download is not a supported regular file.")
        }
        try requireDirectory(destination.deletingLastPathComponent())
        let output = open(destination.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard output >= 0 else { throw AppFailure.message("A private copy of a setup input could not be created.") }
        defer { close(output) }
        var buffer = [UInt8](repeating: 0, count: 1024 * 1024)
        var total: Int64 = 0
        while true {
            try checkCancellation(cancelled)
            let count = buffer.withUnsafeMutableBytes { read(input, $0.baseAddress, $0.count) }
            if count == -1 && errno == EINTR { continue }
            guard count >= 0 else { throw AppFailure.message("A downloaded file could not be copied completely.") }
            if count == 0 { break }
            total += Int64(count)
            guard total <= information.st_size else { throw AppFailure.message("A selected file changed while it was being copied. Retry with a completed download.") }
            var offset = 0
            while offset < count {
                let written = buffer.withUnsafeBytes { write(output, $0.baseAddress!.advanced(by: offset), count - offset) }
                if written == -1 && errno == EINTR { continue }
                guard written > 0 else { throw AppFailure.message("A downloaded file could not be copied completely. Check free disk space.") }
                offset += written
            }
        }
        guard total == information.st_size, fsync(output) == 0, fchmod(output, 0o400) == 0 else {
            throw AppFailure.message("A private setup input could not be completed. The original download was preserved.")
        }
    }

    private static func publish(_ source: URL, to destination: URL) throws {
        try requireDirectory(destination.deletingLastPathComponent())
        guard renamex_np(source.path, destination.path, UInt32(RENAME_EXCL)) == 0 else {
            throw AppFailure.message("A setup destination already exists or could not be published. Existing files were preserved.")
        }
    }

    private static func readJSON<T: Decodable>(_ file: URL) throws -> T {
        try requireRegularFile(file, owner: true)
        guard try metadata(file).st_size <= 8 * 1024 * 1024 else {
            throw AppFailure.message("A setup verification record is too large.")
        }
        return try JSONDecoder().decode(T.self, from: Data(contentsOf: file))
    }

    private static func writeJSON<T: Encodable>(_ object: T, to destination: URL, replace: Bool = true) throws {
        try requireDirectory(destination.deletingLastPathComponent())
        if exists(destination) {
            guard replace else { throw AppFailure.message("A setup record already exists and was preserved.") }
            try requireRegularFile(destination, owner: true)
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        var data = try encoder.encode(object)
        data.append(0x0a)
        let temporary = destination.deletingLastPathComponent().appendingPathComponent(".record-" + UUID().uuidString)
        let handle = open(temporary.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard handle >= 0 else { throw AppFailure.message("A setup record could not be created.") }
        do {
            let output = FileHandle(fileDescriptor: handle, closeOnDealloc: false)
            try output.write(contentsOf: data)
            try output.synchronize()
            guard close(handle) == 0 else { throw AppFailure.message("A setup record could not be completed.") }
        } catch {
            close(handle)
            try? removeRegularFile(temporary)
            throw error
        }
        if replace {
            guard rename(temporary.path, destination.path) == 0 else {
                try? removeRegularFile(temporary)
                throw AppFailure.message("A setup record could not be saved.")
            }
        } else {
            try publish(temporary, to: destination)
        }
    }

    private static func removeRegularFile(_ file: URL) throws {
        if !exists(file) { return }
        try requireRegularFile(file, owner: true)
        guard unlink(file.path) == 0 else { throw AppFailure.message("A temporary setup file could not be removed.") }
    }

    private static func metadata(_ file: URL) throws -> stat {
        var info = stat()
        guard lstat(file.path, &info) == 0 else {
            throw AppFailure.message("A required setup file or folder could not be read. Existing files were preserved.")
        }
        return info
    }

    private static func exists(_ file: URL) -> Bool {
        var info = stat()
        return lstat(file.path, &info) == 0
    }

    private static func validRelative(_ path: String) -> Bool {
        !path.hasPrefix("/") && !path.contains("\\") && !path.contains(":") &&
        !path.unicodeScalars.contains(where: { $0.value < 32 || $0.value == 127 }) &&
        path.split(separator: "/", omittingEmptySubsequences: false).allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".." }
    }

    private static func validStageName(_ name: String) -> Bool {
        name.hasPrefix(".install-stage-") && UUID(uuidString: String(name.dropFirst(".install-stage-".count))) != nil
    }

    private static func validHash(_ hash: String) -> Bool {
        hash.count == 64 && hash.allSatisfy { "0123456789abcdef".contains($0) }
    }

    private static func pinMap() -> [String: String] {
        Dictionary(uniqueKeysWithValues: inputs.map { ($0.name, $0.sha256) })
    }

    private static func checkCancellation(_ cancelled: () -> Bool) throws {
        if cancelled() {
            throw AppFailure.message("Setup was cancelled at a safe stopping point. Existing progress was preserved; use Set Up to continue.")
        }
    }

    private static func timestamp() -> String { ISO8601DateFormatter().string(from: Date()) }
}
