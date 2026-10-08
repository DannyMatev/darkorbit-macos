import AppKit
import Foundation

private final class CancellationFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false

    func request() { lock.lock(); value = true; lock.unlock() }
    func reset() { lock.lock(); value = false; lock.unlock() }
    var requested: Bool {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

private enum Operation {
    case idle, installing, verifying, playing, removing
}

@main
private struct DarkOrbitApplication {
    static func main() {
        let application = NSApplication.shared
        let delegate = ApplicationDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.regular)
        withExtendedLifetime(delegate) { application.run() }
    }
}

private final class ApplicationDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let layout = RuntimeCore.defaultLayout
    private let cancellation = CancellationFlag()
    private var operation = Operation.idle
    private var window: NSWindow!
    private var contentScroll: NSScrollView!
    private var statusField: NSTextField!
    private var progress: NSProgressIndicator!
    private var installButton: NSButton!
    private var resumeButton: NSButton!
    private var termsCheckbox: NSButton!
    private var playButton: NSButton!
    private var verifyButton: NSButton!
    private var removeButton: NSButton!
    private var cancelButton: NSButton!

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMenu()
        createWindow()
        refreshIdleStatus()
        updateButtons()
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func configureMenu() {
        let menu = NSMenu()
        let applicationItem = NSMenuItem()
        menu.addItem(applicationItem)
        let applicationMenu = NSMenu()
        applicationItem.submenu = applicationMenu
        let about = applicationMenu.addItem(withTitle: "About DarkOrbit for Mac", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        applicationMenu.addItem(.separator())
        applicationMenu.addItem(withTitle: "Quit DarkOrbit for Mac", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        NSApplication.shared.mainMenu = menu
    }

    private func createWindow() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 790, height: 800),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "DarkOrbit for Mac"
        window.delegate = self
        window.contentMinSize = NSSize(width: 730, height: 570)
        window.center()
        window.isReleasedWhenClosed = false
        let content = window.contentView!
        let scroll = NSScrollView()
        contentScroll = scroll
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.drawsBackground = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: content.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: content.bottomAnchor)
        ])
        let document = FlippedView()
        document.translatesAutoresizingMaskIntoConstraints = false
        scroll.documentView = document
        document.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor).isActive = true
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 13
        stack.translatesAutoresizingMaskIntoConstraints = false
        document.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: document.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: document.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: document.topAnchor, constant: 25),
            stack.bottomAnchor.constraint(equalTo: document.bottomAnchor, constant: -24)
        ])

        let title = label("DarkOrbit for Mac", size: 27, weight: .semibold)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(label("Unofficial, vibe-coded hobby project built with AI assistance. This experimental app sets up a Windows compatibility environment for the official game. It is not affiliated with or endorsed by the game publisher.", size: 13))
        stack.addArrangedSubview(label("Local test build for Apple Silicon Macs. Rosetta is required. Other Mac configurations have not been verified. No game files or Windows runtimes are included.", size: 12, secondary: true))
        playButton = button("Play / check for game updates", action: #selector(play))
        stack.addArrangedSubview(playButton)
        progress = NSProgressIndicator()
        progress.style = .bar
        progress.isIndeterminate = true
        progress.isDisplayedWhenStopped = false
        stack.addArrangedSubview(progress)
        progress.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        statusField = label("Ready. Choose your downloaded files to create a separate installation.", size: 13)
        statusField.setAccessibilityIdentifier("operationStatus")
        stack.addArrangedSubview(statusField)

        cancelButton = button("Cancel installation", action: #selector(cancelInstallation))
        cancelButton.isHidden = true
        stack.addArrangedSubview(cancelButton)
        stack.addArrangedSubview(separator())

        stack.addArrangedSubview(label("1. Get the installation files", size: 17, weight: .semibold))
        stack.addArrangedSubview(label("Download the four listed files from their official sources. Each button opens an official download in your browser. The publisher's and each provider's terms apply. Nothing downloads automatically.", size: 13))
        stack.addArrangedSubview(downloadRow("Official DarkOrbit", detail: "DarkOrbit_Version1.1.113.zip", selector: #selector(openGameSource)))
        stack.addArrangedSubview(downloadRow("Sikarugir engine", detail: "WS12WineSikarugir11.0_1.tar.xz", selector: #selector(openEngineSource)))
        stack.addArrangedSubview(downloadRow("Sikarugir template", detail: "Template-1.0.21.tar.xz", selector: #selector(openTemplateSource)))
        stack.addArrangedSubview(downloadRow("Microsoft .NET Desktop Runtime", detail: "windowsdesktop-runtime-6.0.36-win-x64.exe", selector: #selector(openDotNetSource)))
        stack.addArrangedSubview(label("Only these exact versions are accepted. If an official source no longer offers a file, stop and check the project documentation. Do not substitute a copy from an unknown source.", size: 12, secondary: true))

        stack.addArrangedSubview(label("2. Set up, then play", size: 17, weight: .semibold))
        let termsLinks = NSStackView(views: [
            button("Game terms", action: #selector(openGameTerms)),
            button("Sikarugir terms", action: #selector(openRuntimeTerms)),
            button("Microsoft runtime terms", action: #selector(openDotNetTerms))
        ])
        termsLinks.spacing = 10
        stack.addArrangedSubview(termsLinks)
        termsCheckbox = NSButton(checkboxWithTitle: "I have reviewed the providers' terms for the files I selected.", target: self, action: #selector(termsChanged))
        termsCheckbox.font = .systemFont(ofSize: 12)
        stack.addArrangedSubview(termsCheckbox)
        installButton = button("Choose four files and install...", action: #selector(install))
        resumeButton = button("Resume setup", action: #selector(resumeSetup))
        stack.addArrangedSubview(NSStackView(views: [installButton, resumeButton]))
        stack.addArrangedSubview(label("Installation uses a separate folder in Application Support. Play opens the official updater and game. Sign in only through the official game. Keep this app open until the game and updater have closed.", size: 13))

        stack.addArrangedSubview(separator())
        verifyButton = button("Verify installation", action: #selector(verify))
        let dataButton = button("Show data folder", action: #selector(showDataFolder))
        removeButton = button("Move installation to Trash...", action: #selector(removeInstallation))
        let secondaryActions = NSStackView(views: [verifyButton, dataButton, removeButton])
        secondaryActions.spacing = 10
        stack.addArrangedSubview(secondaryActions)
        stack.addArrangedSubview(label("Verify checks the installation without replacing game files. For occasional frame drops, try lower in-game graphics settings. Setup and performance can vary between Macs.", size: 12, secondary: true))
        for view in stack.arrangedSubviews where view is NSTextField || view is NSBox {
            view.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
    }

    private func label(_ text: String, size: CGFloat, weight: NSFont.Weight = .regular, secondary: Bool = false) -> NSTextField {
        let field = NSTextField(wrappingLabelWithString: text)
        field.font = .systemFont(ofSize: size, weight: weight)
        field.textColor = secondary ? .secondaryLabelColor : .labelColor
        field.isSelectable = true
        field.maximumNumberOfLines = 0
        return field
    }

    private func button(_ title: String, action: Selector) -> NSButton {
        let value = NSButton(title: title, target: self, action: action)
        value.bezelStyle = .rounded
        return value
    }

    private func separator() -> NSBox {
        let box = NSBox()
        box.boxType = .separator
        return box
    }

    private func downloadRow(_ title: String, detail: String, selector: Selector) -> NSView {
        let link = button(title, action: selector)
        link.widthAnchor.constraint(equalToConstant: 245).isActive = true
        let row = NSStackView(views: [link, label(detail, size: 12, secondary: true)])
        row.spacing = 14
        row.alignment = .centerY
        return row
    }

    private func updateButtons() {
        let idle = operation == .idle
        let hasData = FileManager.default.fileExists(atPath: layout.root.path)
        let installed = FileManager.default.fileExists(atPath: layout.path("installation.json").path)
        let interrupted = FileManager.default.fileExists(atPath: layout.path("installation-incomplete.json").path)
        let reviewedTerms = termsCheckbox.state == .on
        installButton.isEnabled = idle && reviewedTerms
        resumeButton.isEnabled = idle && interrupted && !installed && reviewedTerms
        resumeButton.isHidden = !interrupted || installed
        termsCheckbox.isEnabled = idle
        playButton.isEnabled = idle && installed
        verifyButton.isEnabled = idle && installed
        removeButton.isEnabled = idle && hasData
        cancelButton.isHidden = operation != .installing
        cancelButton.isEnabled = !cancellation.requested
    }

    private func refreshIdleStatus() {
        if FileManager.default.fileExists(atPath: layout.path("installation.json").path) {
            statusField.stringValue = "An installation is available. Choose Play to open the official updater."
        } else if FileManager.default.fileExists(atPath: layout.root.path) {
            statusField.stringValue = "Setup is incomplete. Resume using the verified files already saved, or choose all four files again."
        } else {
            statusField.stringValue = "Ready. Review the providers' terms, then choose your downloaded files."
        }
    }

    @objc private func termsChanged() { updateButtons() }

    private func begin(_ value: Operation, text: String) {
        operation = value
        cancellation.reset()
        statusField.stringValue = text
        progress.startAnimation(nil)
        updateButtons()
        contentScroll.contentView.scroll(to: .zero)
        contentScroll.reflectScrolledClipView(contentScroll.contentView)
    }

    private func finish(_ result: Result<String, Error>) {
        dispatchPrecondition(condition: .onQueue(.main))
        operation = .idle
        progress.stopAnimation(nil)
        switch result {
        case .success(let message): statusField.stringValue = message
        case .failure(let error):
            let message = safeMessage(error)
            statusField.stringValue = message
            showMessage("Could not complete this step", detail: message)
        }
        updateButtons()
    }

    private func safeMessage(_ error: Error) -> String {
        if case AppFailure.message(let message) = error { return message }
        return "The operation could not finish. Your existing files have not been intentionally removed. Check the setup guide before trying again."
    }

    private func report(_ message: String) {
        DispatchQueue.main.async { [weak self] in self?.statusField.stringValue = message }
    }

    @objc private func install() {
        guard operation == .idle else { return }
        let panel = NSOpenPanel()
        panel.title = "Choose the four official installation files"
        panel.message = "Place the four files in one folder. Select the game ZIP, engine archive, template archive, and Windows .NET installer using Command-click."
        panel.prompt = "Install"
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK, let self else { return }
            guard panel.urls.count == 4 else {
                self.showMessage("Choose all four files", detail: "Select exactly the four files listed in this window. Their contents and checksums will be checked before installation.")
                return
            }
            let inputs = panel.urls
            self.startInstallation(inputs: inputs)
        }
    }

    @objc private func resumeSetup() {
        guard operation == .idle, termsCheckbox.state == .on else { return }
        startInstallation(inputs: [])
    }

    private func startInstallation(inputs: [URL]) {
        begin(.installing, text: "Checking installation files. This can take several minutes.")
        DispatchQueue.global(qos: .userInitiated).async {
            let result: Result<String, Error> = Result {
                try RuntimeCore.ensureQuiet()
                let installationLock = try InstallationLock(layout: self.layout)
                return try withExtendedLifetime(installationLock) {
                    try Installer.install(at: self.layout, inputs: inputs,
                                          progress: { self.report($0) },
                                          cancelled: { self.cancellation.requested })
                    return "Installation is ready. Choose Play to open the official updater."
                }
            }
            DispatchQueue.main.async { self.finish(result) }
        }
    }

    @objc private func cancelInstallation() {
        guard operation == .installing else { return }
        cancellation.request()
        statusField.stringValue = "Cancellation requested. Waiting for the current safe installation step to finish."
        updateButtons()
    }

    @objc private func play() {
        guard operation == .idle else { return }
        begin(.playing, text: "Opening the official updater. Keep this app open while you play.")
        DispatchQueue.global(qos: .userInitiated).async {
            let result: Result<String, Error> = Result {
                try RuntimeCore.launch(self.layout, status: { self.report($0) })
                return "The game session has ended. You can play again or quit this app."
            }
            DispatchQueue.main.async { self.finish(result) }
        }
    }

    @objc private func verify() {
        guard operation == .idle else { return }
        begin(.verifying, text: "Checking the installation. Existing game files will be preserved.")
        DispatchQueue.global(qos: .userInitiated).async {
            let result: Result<String, Error> = Result {
                try RuntimeCore.ensureQuiet()
                let installationLock = try InstallationLock(layout: self.layout)
                return try withExtendedLifetime(installationLock) {
                    try Installer.verify(at: self.layout)
                    return "Installation verification finished. The official updater manages game updates."
                }
            }
            DispatchQueue.main.async { self.finish(result) }
        }
    }

    @objc private func showDataFolder() {
        let folder = layout.root
        if FileManager.default.fileExists(atPath: folder.path) {
            NSWorkspace.shared.activateFileViewerSelecting([folder])
        } else {
            showMessage("No installation yet", detail: "Installation will create a separate DarkOrbitCommunity folder in your Library's Application Support folder.")
        }
    }

    @objc private func removeInstallation() {
        guard operation == .idle else { return }
        let alert = NSAlert()
        alert.messageText = "Move this installation to Trash?"
        alert.informativeText = "This moves only this app's DarkOrbitCommunity data folder to Trash, including the downloaded runtime, installed game, saved settings, and local sign-in data. Other games and Wine installations are left alone. You can restore the folder from Trash. Close the game and updater first."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Move to Trash")
        alert.beginSheetModal(for: window) { [weak self] response in
            guard response == .alertSecondButtonReturn, let self else { return }
            self.begin(.removing, text: "Moving this installation to Trash.")
            DispatchQueue.global(qos: .userInitiated).async {
                let result: Result<String, Error> = Result {
                    try RuntimeCore.ensureQuiet()
                    try RuntimeCore.trashInstallation(self.layout)
                    return "The installation was moved to Trash. This app can be removed separately in Finder."
                }
                DispatchQueue.main.async { self.finish(result) }
            }
        }
    }

    @objc private func openGameSource() { openSource("https://alicdn-oss-prod.darkorbit.com/release/archive/DarkOrbit_Version1.1.113.zip") }
    @objc private func openEngineSource() { openSource("https://github.com/Sikarugir-App/Engines/releases/download/v1.0/WS12WineSikarugir11.0_1.tar.xz") }
    @objc private func openTemplateSource() { openSource("https://github.com/Sikarugir-App/Template/releases/download/v1.0/Template-1.0.21.tar.xz") }
    @objc private func openDotNetSource() { openSource("https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/6.0.36/windowsdesktop-runtime-6.0.36-win-x64.exe") }

    @objc private func openGameTerms() { openSource("https://board-en.darkorbit.com/threads/general-terms-and-conditions.130276/") }
    @objc private func openRuntimeTerms() { openSource("https://github.com/Sikarugir-App/Sikarugir#components-that-fall-under-lgpl-21-license") }
    @objc private func openDotNetTerms() { openSource("https://github.com/dotnet/core/blob/main/license-information-windows.md") }

    private func openSource(_ value: String) {
        guard let url = URL(string: value) else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func showAbout() {
        showMessage("DarkOrbit for Mac 0.1.0", detail: "An unofficial, vibe-coded hobby project built with AI assistance. This experimental local launcher contains no game or Windows runtime binaries. It is not affiliated with or endorsed by the game publisher. The game and dependencies retain their own terms and licenses.")
    }

    private func showMessage(_ title: String, detail: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = detail
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: window)
    }

    private func allowQuit() -> Bool {
        guard operation != .idle else { return true }
        if operation == .playing {
            showMessage("Close the game first", detail: "Close the official game and updater normally. Keep this app open until it reports that the session has ended.")
        } else if operation == .installing {
            showMessage("Installation is still running", detail: "Use Cancel installation, then wait for the current safe step to finish before quitting.")
        } else {
            showMessage("Please wait for this step to finish", detail: "The app is checking or removing its installation. You can quit when this step has finished.")
        }
        return false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        allowQuit() ? .terminateNow : .terminateCancel
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool { allowQuit() }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
