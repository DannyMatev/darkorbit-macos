# Developer guide

## Build the local app

Use an Apple Silicon Mac with Apple's Xcode command line tools and a Swift compiler. Developer tests and the publication audit also use Python 3. The application targets macOS 14.6 or later. End users of a built application do not need Python or a compiler.

From the repository root:

```sh
./scripts/build.sh
```

The result is `build/DarkOrbit for Mac.app`. The script makes a local ad-hoc signature and verifies its structure. This is not Developer ID signing or notarization and does not establish that Gatekeeper will accept a downloaded copy on another Mac.

Build from source in a normal local folder. A build must not depend on the original development checkout, personal paths, a pre-existing Windows environment, or files outside the documented inputs.

## Test in layers

Start with synthetic tests for hashes, archive paths, environment construction, private directories, process recognition, and installation boundaries. Synthetic tests must never start the game, use account data, change the real application-data directory, or stop unrelated processes.

```sh
./scripts/test.sh
python3 -B scripts/audit_release.py --app "build/DarkOrbit for Mac.app"
```

The audit checks the selected source files, reachable Git objects, and supplied app bundle. Its heuristics are a useful check, not proof that no private data could exist. Review the actual export as well.

Then exercise setup with the four [pinned files](dependencies.md) in a separate disposable environment. Include a path with spaces. Record the tested app revision, runtime versions, results, and whether an observation was automated or made by a person. A successful build is not an installation test.

`./scripts/probe-build.sh` builds the developer-only `build/installation-probe`. It accepts `install`, `verify`, or `quiet`, followed by an explicit test root. Installation also takes the four local input paths. Use a new disposable test directory, never the player's existing installation. The probe does not launch the game or authenticate; setup still executes Wine and the selected Microsoft installer.

For a manual candidate test, use the [compatibility table](compatibility.md). Check official update flow, launch, normal quit, relaunch, duplicate prevention, verification, and removal. Sign in only through the official game. Collect no account identifiers, raw logs, or screenshots containing account information.

The existing hour-long gameplay report is valid user evidence for the development configuration. Repeat gameplay when a change could affect it or a specific missing check requires it, rather than treating the earlier session as nonexistent.

## Change dependencies carefully

Review the upstream source, license, release record, hash, and compatibility together. Keep renderer architecture variants and their Unix bridge matched. Do not relax hash checks to make a new download pass. Do not downgrade the official game after its updater has changed it.

Use synthetic failing inputs to verify safe error handling. Avoid tests that can affect a player's real session. A normal quit and independently confirmed quiet state are prerequisites for setup and removal tests involving runtime processes.

## Prepare a release

Export an explicit allowlist of original source, resources, documentation, tests, and notices. Do not include downloaded binaries, installers, game files, a Windows environment, build caches, raw evidence, or private reports. A separate app archive may contain the app built from this source, subject to the distribution review.

Review source, generated text, archive entries, binary strings, debug information, metadata, symlinks, and intended Git history for personal data. Check commit author and committer identity separately before any publication. A clean working tree alone says nothing about old commits.

Keep signing/notarization credentials outside the repository. No public upload is part of the local build. Resolve [distribution questions](distribution.md) and complete the relevant [acceptance checks](compatibility.md) before describing a release as ready for ordinary users.

## Package a local candidate

Commit the intended source first, then run `python3 -B scripts/package.py`. The packager checks the exact file allowlist and Git contents, copies the approved source into a temporary folder, builds the app there, verifies its ad-hoc signature, and creates source and app ZIP files plus checksums in `dist/`. It does not replace a running development app or change a game installation. No remote is contacted by packaging and nothing is published. The app ZIP includes `START-HERE.txt` and the user documentation.

The release manifest records the source commit and whether the resulting executable matches the fingerprint in `verification.json`. A different executable needs its own acceptance record. A matching fingerprint does not turn failed or untested checks into passes. Close the community launcher and game normally before using `build.sh` to replace the development app or performing launch tests on an extracted candidate.
