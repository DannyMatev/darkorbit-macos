# Known limitations

- This is an experimental hobby project with one user-reported gameplay configuration. It has no support service or maintenance guarantee.
- The native application candidate still needs installation and lifecycle validation. See [Compatibility](compatibility.md) for what has and has not been tested.
- Occasional frame drops were reported. Lowering graphics helped in that session, but no frame-rate measurements or exact settings were captured.
- The official launcher used here depends on Windows .NET 6, which reached end of support on 12 November 2024. A supported replacement must be tested with the official launcher; changing major versions blindly can break it. [Microsoft support policy](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core)
- The pinned runtime uses Rosetta. Compatibility with future macOS releases is unverified and depends on Apple's continued support for the required translation behavior. [Apple Rosetta guidance](https://support.apple.com/en-us/102527)
- Installation requires four separately downloaded, exact-version files. If an upstream file disappears, the candidate cannot substitute another version automatically.
- The official updater can change the game and its requirements. We cannot guarantee that a later version will continue to work.
- The candidate is not Developer ID signed or notarized. Distribution outside the development machine still needs work.
- Publisher approval for this setup is unresolved. We cannot promise legal clearance or protection from account restrictions. See [Distribution review](distribution.md).

The project does not modify the game, collect credentials, automate gameplay, or supply a private server. These boundaries do not establish publisher approval.
