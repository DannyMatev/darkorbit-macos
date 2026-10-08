# Third-party notices

Reviewed 8 October 2026. The source package and native app contain this project's original material. The components below are obtained separately and retain their own terms. Listing them here is not a redistribution grant or proof of publisher approval.

| Component | License or terms | Project boundary |
| --- | --- | --- |
| Official DarkOrbit game and assets | Bigpoint terms and applicable game rules | Not included; the official client manages login and updates |
| Sikarugir Wine engine | Wine LGPL-2.1-or-later plus component notices | Not included; exact source/build correspondence for revision 1 remains unverified |
| DXMT | LGPL-2.1-or-later, plus incorporated component notices | Not included; selected from the separately obtained template |
| Template support libraries | Mixed licenses | Not included; a complete binary-to-source/license mapping is not established |
| Windows .NET Desktop Runtime | Mixed Microsoft and open-source terms | Not included; installed from the user's official Microsoft file |
| Rosetta and macOS frameworks | Apple's applicable terms | Supplied by Apple; not packaged here |

## Sources and attribution

Wine's license and component notices are in the [Sikarugir Wine source repository](https://github.com/Sikarugir-App/wine). A generic Wine version or release-page source archive is not proof of the complete corresponding source for the selected modified binary.

DXMT's [license at the selected source commit](https://github.com/3Shain/dxmt/blob/7c8dee1c2d73415301ceb7d1fa810861cef4cd67/LICENSE) credits `Copyright (c) 2023-2026 Feifan He for CodeWeavers`. Its LGPL grant does not imply that a paid CrossOver installation is required. Preserve all applicable notices if future work distributes DXMT itself.

The [Sikarugir README](https://github.com/Sikarugir-App/Sikarugir) distinguishes its LGPL Configure component from its Launcher and Creator components. Do not describe the full template as one open-source library. This project does not use or package those wrapper applications, the unverified SDK, or Apple's D3DMetal. The selected support libraries still require their own review before redistribution.

[Microsoft's Windows .NET licensing notice](https://github.com/dotnet/core/blob/main/license-information-windows.md) identifies MIT files, files under the [.NET Library License](https://dotnet.microsoft.com/en-us/dotnet_library_license.htm), and a Windows SDK component. A source repository's MIT license does not cover every binary in the Windows installer. The linked [Windows SDK terms](https://learn.microsoft.com/en-us/legal/windows-sdk/license) restrict distribution of their Distributable Code to Microsoft operating-system platforms. No such files are redistributed here. A distribution restriction is not by itself a blanket prohibition on local Wine use.

Static inspection of the verified 6.0.36 installer recovered identical .NET Library EULAs from all four MSI payloads, plus its host license and third-party notices. The embedded grant concerns designing, developing, and testing programs and differs from the current online text. Microsoft documents this runtime for [running existing desktop applications](https://dotnet.microsoft.com/en-us/download/dotnet/6.0). No specific Microsoft restriction on publishing our separate source, helper app, or guide was identified. This does not establish Microsoft approval or support for Wine, and the embedded/component terms still apply. License fingerprints are recorded in `dependencies.json`; extracted vendor files remain outside this project package.

The game's name is used to identify compatibility. No game logos, artwork, or publisher branding are supplied by this project. See [Distribution review](docs/distribution.md) for the remaining questions.
