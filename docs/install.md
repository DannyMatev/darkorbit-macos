# Start here

**The native candidate works in the latest user-confirmed test on the documented Mac.** The separate development setup also has an earlier hour-long gameplay report. Other Macs and the individual acceptance checks listed in [Compatibility](compatibility.md) remain unverified.

These instructions are for local candidate testing. There is no public download release yet. The package-scope distribution review is complete; ordinary-user delivery and remaining acceptance checks are still pending.

## Before you start

You need an Apple Silicon Mac running macOS 14.6 or later, Rosetta, and internet access for the official game. Only an M1 Pro with 16 GB of memory on macOS 26.0 has been tested in gameplay. Intel Macs are outside this candidate's scope.

Allow at least 25 GB of free space as a conservative installation allowance. The game download alone is about 3.7 GB and expands to about 4.6 GB. The runtime, temporary installation files, and future game updates need additional space. This is an allowance, not a measured minimum.

Rosetta is Apple's Intel-app compatibility software. If it is missing, follow [Apple's installation instructions](https://support.apple.com/en-us/102527). Review the terms in Apple's prompt. The launcher does not silently accept them for you.

Read [Known limitations](limitations.md) and [Distribution review](distribution.md). The project is unofficial, and current publisher assurance for this Wine configuration has not been obtained.

## Get the four installation files

Download the exact versions below from their original providers. Keep the files together in a folder you can find, such as Downloads. Do not unpack them yourself or download another person's ready-made game folder.

| Exact download | Provider information |
| --- | --- |
| [WS12WineSikarugir11.0_1.tar.xz](https://github.com/Sikarugir-App/Engines/releases/download/v1.0/WS12WineSikarugir11.0_1.tar.xz) | [Sikarugir engine release](https://github.com/Sikarugir-App/Engines/releases/tag/v1.0) |
| [Template-1.0.21.tar.xz](https://github.com/Sikarugir-App/Template/releases/download/v1.0/Template-1.0.21.tar.xz) | [Sikarugir template release](https://github.com/Sikarugir-App/Template/releases/tag/v1.0) |
| [DarkOrbit_Version1.1.113.zip](https://alicdn-oss-prod.darkorbit.com/release/archive/DarkOrbit_Version1.1.113.zip) | [Official DarkOrbit site](https://www.darkorbit.com/) |
| [windowsdesktop-runtime-6.0.36-win-x64.exe](https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/6.0.36/windowsdesktop-runtime-6.0.36-win-x64.exe) | [Microsoft .NET 6 downloads](https://dotnet.microsoft.com/en-us/download/dotnet/6.0) |

The links select the pinned versions directly, rather than a provider's latest download. Clicking a download opens it in your browser; the app does not fetch files automatically. An official download link does not establish permission for every use. Review the providers' terms and the [distribution questions](distribution.md).

The app checks each file against a recorded fingerprint before using it. If a provider removes or replaces a version, stop and report that the required file is unavailable. Do not rename a different version to match. See [Dependencies](dependencies.md) for the exact fingerprints and their limits.

The pinned official game launcher requires Windows .NET 6. Microsoft ended support for .NET 6 on 12 November 2024. This dependency needs future maintenance; installing macOS .NET does not replace it. [Microsoft support policy](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core)

## Install and play

1. Open the supplied `DarkOrbit for Mac.app` in Finder. A developer can build the local candidate using the [developer guide](development.md); ordinary users should not need a compiler or Python.
2. Read the providers' terms using the app's links, then select the acknowledgement. Choose **Choose four files and install...** and select all four downloads together using Command-click. Let installation finish before launching the game.
3. Choose **Play / check for game updates**. The official DarkOrbit updater opens and can update its own game files.
4. Use the official updater to start the game, then sign in through the game's own interface.

Keep the Mac launcher open until the game and updater have closed. During setup, **Cancel installation** requests a safe stop. If setup was interrupted, the app offers **Resume setup** when the retained files can be used. Do not start a second installation while one is running.

The candidate has not been Developer ID signed or notarized. If macOS blocks it, stop. This project does not provide instructions to disable Gatekeeper or remove quarantine. A public release needs an appropriate signing and distribution workflow.

If the game pauses briefly or drops frames, try lowering its graphics settings. This helped substantially in the reported session; the exact settings were not recorded and the result is not guaranteed on every Mac.

## Updates and repairs

Use **Play / check for game updates** for normal game updates. It opens the official updater. An update may change compatibility, so report the new game version if behavior changes.

Use **Verify installation** to check the local setup. Verification does not restore old game files over an official update. If verification reports a missing or changed component, follow the message instead of copying files from an older installation.

Do not run installation, removal, or repair while the game is open. Quit it normally first. The launcher must not stop unrelated Wine applications.

## Remove the installation

Quit the game and its updater. In the launcher, choose **Move installation to Trash...** and read the confirmation before proceeding. This moves this app's installation data to the Trash, including its local settings and stored sign-in state. It does not delete your online DarkOrbit account.

The data folder is `~/Library/Application Support/DarkOrbitCommunity`. The `~` means your own home folder. Do not share its contents. Move the app itself to the Trash separately when you no longer want it. Keep the Trash until you are sure you no longer need the local data.

For problems, see [Troubleshooting](troubleshooting.md).
