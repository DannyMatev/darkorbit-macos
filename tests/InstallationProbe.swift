import Foundation
import Darwin

// Developer-only validation tool. It never starts the game or authenticates.
@main
struct InstallationProbe {
    static func main() {
        let args = Array(CommandLine.arguments.dropFirst())
        guard args.count >= 2, ["install", "verify", "quiet"].contains(args[0]) else {
            fputs("Usage: installation-probe install|verify|quiet ROOT [FOUR_INPUT_FILES]\n", stderr)
            exit(2)
        }
        let layout = InstallationLayout(root: URL(fileURLWithPath: args[1], isDirectory: true).standardized)
        do {
            if args[0] == "quiet" {
                try RuntimeCore.ensureQuiet()
                print("PASS: no Wine or game process found")
                return
            }
            let lock = try InstallationLock(layout: layout)
            defer { withExtendedLifetime(lock) {} }
            if args[0] == "install" {
                try Installer.install(at: layout, inputs: args.dropFirst(2).map { URL(fileURLWithPath: $0) }, progress: { print($0); fflush(stdout) }, cancelled: { false })
            } else {
                try Installer.verify(at: layout)
            }
            let original = try Installer.gameCompatibility(at: layout)
            print("PASS: installation verified; original game baseline matches: \(original)")
        } catch let error as AppFailure {
            fputs((error.errorDescription ?? "Validation failed.") + "\n", stderr)
            exit(1)
        } catch {
            fputs("Validation failed; raw errors withheld.\n", stderr)
            exit(1)
        }
    }
}
