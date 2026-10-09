# Troubleshooting

## The app will not open

Check that you have an Apple Silicon Mac and macOS 14.6 or later. The candidate is not a completed public distribution. If macOS reports an unidentified developer, blocked software, or damaged software, stop and record the message in your own words. Do not disable security settings or run commands that remove quarantine.

## Installation rejects a file

Check its full filename and version against the [installation guide](install.md). Re-download it from the listed provider if the download was incomplete. Do not edit the file, change its fingerprint in the source, or substitute a different version. A fingerprint mismatch means this candidate has not verified that file.

## Rosetta is missing

Follow [Apple's instructions](https://support.apple.com/en-us/102527). Rosetta comes from Apple and may require an administrator to install it. Restart installation after it is available.

## The official updater is taking time

Give it time to finish and check the message in its own window. Avoid opening another copy. If an update fails, close the game and updater normally before trying again. An internet connection is required. Do not replace updated game files with files from the installation archive.

## The game stutters

Lower the in-game graphics settings and compare the same activity. This substantially reduced sporadic frame drops in the reported session. If you report a performance problem, include the Mac chip, memory, macOS version, game version, resolution, and graphics settings. Say whether your report is a visual impression or a measured result.

## Verification reports a problem

Record the app's short message and the step that led to it. Do not delete the data folder as a first repair step: it may contain your settings and stored sign-in state. Removal requires a separate confirmation and is not a substitute for diagnosis.

## Report a problem without exposing your account

Use the relevant issue template in the repository. Include reproducible steps and a short description of what happened. Never attach passwords, cookies, tokens, account screenshots, full installation folders, or raw game logs. Do not include a home-directory path or your Mac username. The issue forms do not need any game account details.

There is no private security-reporting channel configured in this candidate. Do not put secrets or exploit details in a public issue. Account and billing issues belong with the game's official support.
