# DarkOrbit for Mac

An unofficial, vibe-coded hobby project built with AI assistance. It sets up a separate compatibility environment and opens the official Windows DarkOrbit client on Apple Silicon Macs, without CrossOver.

**Current candidate status: gameplay acceptance failed.** Login succeeds, but the page after login has a missing background and repeatedly returns to server selection. The cause is under investigation. The earlier working development setup is separate from this native installation.

This is a local release candidate, not a published or publisher-approved product. The packaged application still needs the checks listed in [Compatibility](docs/compatibility.md), and the [distribution review](docs/distribution.md) has unresolved questions.

## Want to play?

Start with the [installation guide](docs/install.md). The app uses four files that you download from their original providers. It does not include the game or its runtime dependencies. You sign in through the official game interface.

The candidate requires an Apple Silicon Mac, macOS 14.6 or later, Rosetta, and an internet connection. Only an M1 Pro with 16 GB of memory on macOS 26.0 has gameplay evidence. Other configurations are untested.

One player reported about an hour of stable gameplay, smooth overall. Occasional lag spikes or frame drops were substantially reduced by lowering the game's graphics settings. This is a user report from one setup, not an FPS benchmark.

## Want to contribute?

Read [Contributing](CONTRIBUTING.md), then the [architecture notes](docs/architecture.md) and [developer guide](docs/development.md). Useful work includes installation testing, lifecycle testing, accessibility, clearer instructions, and validating other Mac configurations. AI-assisted contributions still need review and meaningful tests.

## How it works

The native Mac app prepares and launches the official Windows updater. Wine supplies Windows compatibility, Rosetta runs the Intel-based runtime on Apple Silicon, and DXMT translates the game's DirectX graphics to Metal. The official updater manages game updates.

Our launcher adds no credential service or telemetry. The game and separately installed dependencies have their own network behavior and terms. Account data remains in the local game installation, so do not share that folder or raw logs.

## Project boundaries

DarkOrbit belongs to its respective rights holders. This project is not affiliated with or endorsed by Bigpoint, Apple, Microsoft, CodeWeavers, or the runtime maintainers. No publisher approval or guarantee against account restrictions has been established.

The [MIT license](LICENSE) covers only this repository's original code and documentation. It grants no rights to the game or separately obtained runtimes. See [Third-party notices](THIRD_PARTY_NOTICES.md) and [Known limitations](docs/limitations.md) before using the candidate.
