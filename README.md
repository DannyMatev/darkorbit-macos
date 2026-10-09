# READ HERE FIRST

This was a successful attempt at vibecoding a macos client for the game, didn't really put that much effort into it other than make it stable enough to have non-disruptive play experience. Contribute, fork it or report bugs/suggestions here. If there's any demand I'll put some more effort into it. Everything and onwards is AI generated but the setup is verified. Enjoy!

[☕ Buy me a coffee](https://ko-fi.com/dannymv)

## TLDR - quick setup

**You need:** a Mac with an M-series chip, macOS 14.6 or newer, [Rosetta](https://support.apple.com/en-us/102527), internet, and about 25 GB of free space. Intel Macs are not supported by this setup.

### 1. Get the Mac launcher

There is no ready-to-download app release yet. For now, you need to build it once using the two copy-and-paste steps below. You do not need Homebrew, Python, or CrossOver.

Open **Terminal** from **Applications > Utilities**, paste this, and press Return:

```sh
xcode-select --install
```

Choose **Install** and wait for Apple's tools to finish installing. If Terminal says the tools are already installed, continue. Then paste this whole block and press Return:

```sh
git clone https://github.com/DannyMatev/darkorbit-macos.git "$HOME/Downloads/darkorbit-macos" &&
cd "$HOME/Downloads/darkorbit-macos" &&
./scripts/build.sh &&
open "build/DarkOrbit for Mac.app"
```

The launcher opens when the build finishes. For later sessions, open **Downloads > darkorbit-macos > build > DarkOrbit for Mac.app** in Finder. If a command fails, stop and check [Troubleshooting](docs/troubleshooting.md).

### 2. Download these four files

Save all four in **Downloads**. Keep them as downloaded: do not unzip them or open the `.exe` yourself.

| Download | What it is |
| --- | --- |
| [WS12WineSikarugir11.0_1.tar.xz](https://github.com/Sikarugir-App/Engines/releases/download/v1.0/WS12WineSikarugir11.0_1.tar.xz) | Windows compatibility software |
| [Template-1.0.21.tar.xz](https://github.com/Sikarugir-App/Template/releases/download/v1.0/Template-1.0.21.tar.xz) | Supporting files, including graphics support |
| [DarkOrbit_Version1.1.113.zip](https://alicdn-oss-prod.darkorbit.com/release/archive/DarkOrbit_Version1.1.113.zip) | Official game and updater |
| [windowsdesktop-runtime-6.0.36-win-x64.exe](https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/6.0.36/windowsdesktop-runtime-6.0.36-win-x64.exe) | Microsoft software required by the updater |

### 3. Install and play

1. Close any other Wine games or apps normally. In our launcher, review the providers' terms and tick the acknowledgement box.
2. Click **Choose four files and install...**. Hold **Command** while selecting all four files, confirm, and wait for setup to finish.
3. Click **Play / check for game updates**, then **Start** in the official updater. Sign in through the game's own interface. Keep our Mac launcher open while playing.

If the game stutters, try lowering its graphics settings. If macOS blocks the app, stop and follow the [installation guide](docs/install.md); do not disable Mac security protections.

More help: [Full installation guide](docs/install.md) | [Troubleshooting](docs/troubleshooting.md) | [Report a problem](https://github.com/DannyMatev/darkorbit-macos/issues/new/choose)

# Unofficial macOS launcher for DarkOrbit

An unofficial, vibe-coded hobby project built with AI assistance. It sets up a separate compatibility environment and opens the official Windows DarkOrbit client on Apple Silicon Macs, without CrossOver. 

**Current candidate status: working in the latest user test.** Confirmed that the native Mac candidate works as expected on the tested Mac.

This repository contains source for an experimental release candidate. It is not a publisher-approved product or a finished, signed Mac download. The [distribution review](docs/distribution.md) found no specific restriction on redistributing the original files in our packages. It does not guarantee publisher account-policy acceptance or approval of this Wine configuration. Delivery and acceptance work remains in [Compatibility](docs/compatibility.md).

## Want to play?

Start with the [installation guide](docs/install.md). The app uses four files that you download from their original providers. It does not include the game or its runtime dependencies. You sign in through the official game interface.

The candidate requires an Apple Silicon Mac, macOS 14.6 or later, Rosetta, and an internet connection. Only an M1 Pro with 16 GB of memory on macOS 26.0 has gameplay evidence. Other configurations are untested.

In the earlier development setup, one player reported about an hour of stable gameplay, smooth overall. Occasional lag spikes or frame drops were substantially reduced by lowering the game's graphics settings.

## Want to contribute?

Read [Contributing](CONTRIBUTING.md), then the [architecture notes](docs/architecture.md) and [developer guide](docs/development.md). Useful work includes installation testing, lifecycle testing, accessibility, clearer instructions, and validating other Mac configurations. AI-assisted contributions still need review and meaningful tests.

## How it works

The native Mac app prepares and launches the official Windows updater. Wine supplies Windows compatibility, Rosetta runs the Intel-based runtime on Apple Silicon, and DXMT translates the game's DirectX graphics to Metal. The official updater manages game updates.

Our launcher adds no credential service or telemetry. The game and its installers may create their own local logs, which are private and excluded from project packages. The game and separately installed dependencies have their own network behavior and terms. Local sign-in data is stored in the game installation, so do not share that folder or raw logs. The official online game also processes account data under its own privacy policy.

## Project boundaries

DarkOrbit belongs to its respective rights holders. This project is not affiliated with or endorsed by Bigpoint, Apple, Microsoft, CodeWeavers, or the runtime maintainers. No publisher approval or guarantee against account restrictions has been established.

The [MIT license](LICENSE) covers only this repository's original code and documentation. It grants no rights to the game or separately obtained runtimes. See [Third-party notices](THIRD_PARTY_NOTICES.md) and [Known limitations](docs/limitations.md) before using the candidate.
