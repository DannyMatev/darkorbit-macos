# Dependency record

Reviewed 8 October 2026. These files are obtained separately by the user. None belongs in this repository or its source archive. This project does not mirror them.

| Component | Pinned version | Exact manual download | Provider information |
| --- | --- | --- | --- |
| Wine engine | `WS12WineSikarugir11.0_1` | [Engine archive](https://github.com/Sikarugir-App/Engines/releases/download/v1.0/WS12WineSikarugir11.0_1.tar.xz) | [Sikarugir engine releases](https://github.com/Sikarugir-App/Engines/releases/tag/v1.0) |
| Runtime template | `1.0.21` | [Template archive](https://github.com/Sikarugir-App/Template/releases/download/v1.0/Template-1.0.21.tar.xz) | [Sikarugir template releases](https://github.com/Sikarugir-App/Template/releases/tag/v1.0) |
| Official game archive | `1.1.113` | [Game archive](https://alicdn-oss-prod.darkorbit.com/release/archive/DarkOrbit_Version1.1.113.zip) | [DarkOrbit](https://www.darkorbit.com/) |
| Windows Desktop Runtime x64 | `6.0.36` | [Microsoft installer](https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/6.0.36/windowsdesktop-runtime-6.0.36-win-x64.exe) | [Microsoft .NET downloads](https://dotnet.microsoft.com/en-us/download/dotnet/6.0) |

Downloads happen only when the user follows a link in a browser. Installation reads the four selected local files and makes no automated download request. These provider URLs and recorded hashes establish the intended inputs, not legal clearance for use or redistribution. Review the [third-party notices](../THIRD_PARTY_NOTICES.md) and linked terms.

## File fingerprints

The installer checks SHA-256 before extraction or execution. A matching hash identifies the recorded bytes. It does not establish licensing permission or independently prove the publisher's identity.

| Filename | SHA-256 |
| --- | --- |
| `WS12WineSikarugir11.0_1.tar.xz` | `67e29fb3d74f363af39c69ba11f9b13a79812c5db07cf4748672658e4a200a0e` |
| `Template-1.0.21.tar.xz` | `bbe996e4e4375318485953d0c7818b7b4b0a4dc1f13303bcc584f99f7602f78d` |
| `DarkOrbit_Version1.1.113.zip` | `25dbc9ba125b35ef08beb3d239076a89b48667377d225775a9703323f7586073` |
| `windowsdesktop-runtime-6.0.36-win-x64.exe` | `0d20debb26fc8b2bc84f25fbd9d4596a6364af8517ebf012e8b871127b798941` |

## Selected runtime contents

The engine runs as x86_64 through Rosetta and supports the game's mix of 32-bit and 64-bit Windows processes. The template supplies DXMT and support libraries. Its Sikarugir launcher, Creator, SDK, and other renderer families are not part of this project's installed configuration.

The selected DXMT identifies itself as `v0.80-244-g7c8dee1`. Its declared source commit is [`7c8dee1c2d73415301ceb7d1fa810861cef4cd67`](https://github.com/3Shain/dxmt/tree/7c8dee1c2d73415301ceb7d1fa810861cef4cd67). Keep its 32-bit and 64-bit Windows DLLs with the matching Unix bridge. That source identity does not by itself prove a reproducible binary build.

The official game archive contains an x86 Unity game and x64 launcher/browser helpers. Folder names do not reliably indicate a binary's architecture. Its launcher requires the Windows .NET Core and Windows Desktop frameworks; a macOS .NET installation is not a substitute.

See [Third-party notices](../THIRD_PARTY_NOTICES.md) for license boundaries. New versions require a new provenance review and compatibility checks before changing these pins. Never replace a user's newer official game files with this baseline archive.
