# Architecture

The project is a native macOS launcher around the unchanged official Windows game. It does not implement the DarkOrbit protocol, store a separate game account, or automate gameplay.

```text
DarkOrbit for Mac.app
  -> dedicated Wine environment
  -> official DarkOrbit updater
  -> official game and browser helpers
  -> DXMT graphics translation
  -> Apple's Metal graphics system
```

Rosetta runs the Intel-based Wine runtime on Apple Silicon. Wine handles Windows APIs and both Windows process architectures. DXMT handles Direct3D graphics translation.

## Code and storage

`Sources/App.swift` provides the native interface. `Sources/Core.swift` owns the runtime environment, command execution, session coordination, and removal. `Sources/Installer.swift` validates the four inputs and prepares a separate environment. `Resources` contains only this project's application resources. `scripts` contains local developer tools.

The app bundle contains no game, Windows runtime, or account state. Mutable data lives in `~/Library/Application Support/DarkOrbitCommunity`:

| Relative path | Purpose |
| --- | --- |
| `runtime/wswine.bundle` | Sikarugir Wine engine |
| `runtime/support` | Selected matching support libraries |
| `runtime/dxmt` | Matching DXMT files |
| `state/prefix` | Dedicated Windows-style environment |
| `state/prefix/drive_c/DarkOrbitFree/Game` | Official game and updater |
| `installation.json` | This installation's receipt |

This environment is separate from other Wine or CrossOver installations. It is not a sandbox: Windows programs still run with the local user's permissions. Treat the environment as private because the game can store sign-in state there.

## Runtime configuration

The Swift environment builder is the configuration authority. It sets the dedicated `WINEPREFIX`, `WINEARCH=win64`, and engine-specific loader and server paths. It supplies the version-specific `SikarugirAppWine11=1` initialization value and points `WINEDLLPATH_DXMT` at the matching DXMT directory.

The graphics overrides are `d3d11,dxgi,d3d10core,winemetal=b;winemenubuilder.exe=`. The fallback library path includes the selected support libraries, GStreamer libraries, the engine's Unix libraries, DXMT's Unix bridge, and `/usr/lib`. Runtime commands use argument arrays, not a shell command assembled from input paths.

## Session lifecycle

Launch always starts the official updater in its game directory. The updater may exit after starting a replacement process, so its first parent exiting does not mean the game has finished. The launcher waits on the dedicated Wine server and performs another process check before allowing a new operation.

An advisory installation lock coordinates copies of this application. The current process guard is deliberately conservative: it refuses operations while any recognized Wine or DarkOrbit process is active. It does not terminate another application's session. This can require users to close an unrelated Wine application normally before proceeding.

The Mac launcher stays open while the game runs. It discards normal game command output rather than storing it as a raw log. Setup checks may inspect bounded command output internally; errors presented by the app must use fixed, non-sensitive messages. The official game, Wine, and Microsoft installer can independently create local logs and account files. These remain private installation data and must never enter a project package or issue report.

## Installation and maintenance

The user supplies exact official archives. Installation verifies their hashes, checks extraction paths, and prepares private staging before using the files. Existing game data is preserved. Verification checks the setup without rolling back an official update.

The selected template components exclude the Sikarugir wrapper, Creator, SDK, D3DMetal, and unrelated renderers. Copying the full template into the release would change both the technical and licensing scope.

Removal requires explicit confirmation and moves the recognized project installation to the Trash. It must not remove arbitrary directories, touch another Wine prefix, or permanently delete account data. The operating system's security controls stay enabled throughout.

For limitations and required evidence, read [Compatibility](compatibility.md) and [Distribution review](distribution.md).
