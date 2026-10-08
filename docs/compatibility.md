# Compatibility and test evidence

Updated 8 October 2026. A successful development setup and a verified application release are different milestones.

The current native candidate has failed gameplay acceptance. The user can log in, but the page after login has a missing background and repeatedly returns to server selection. The same symptoms persisted after a full normal restart. Diagnosis is ongoing. The earlier hour-long development session remains valid evidence for that separate configuration.

## Development gameplay evidence

| Item | Result | Evidence |
| --- | --- | --- |
| Apple M1 Pro, 16 GB memory, macOS 26.0 | User-confirmed | Successful official login and approximately one hour of gameplay |
| Overall stability | User-confirmed | Stable and smooth overall during that session |
| Intermittent lag or frame drops | User-confirmed | Substantially reduced by lowering in-game graphics |
| Actual FPS, frame times, game resolution, exact settings | Not measured | No benchmark claim |
| Wine mixed 32-bit and 64-bit execution | Observed in development | Both architecture probes completed |
| DXMT loaded by the game | Observed in development | Matching graphics modules were mapped by the game process |
| Other Mac models and macOS releases | Not tested | The minimum runtime requirement is not a compatibility result |

The runtime was Sikarugir Wine 11.0 revision 1 with DXMT `v0.80-244-g7c8dee1`, official DarkOrbit 1.1.113, and Windows Desktop Runtime 6.0.36 x64. The hour-long report supports extended gameplay; it does not establish every individual feature below.

## Candidate acceptance

| Check | Status |
| --- | --- |
| Native installation backend in a fresh Application Support folder | PASS, including both Windows architecture probes and .NET verification |
| Repeated setup preserves the existing installation | PASS |
| Full graphical installer file-selection flow | NOT TESTED |
| Application build and strict ad-hoc signature verification | PASS |
| Packaged app opens and Verify installation completes | PASS |
| Packaged app starts the official updater | PASS |
| Login through the native candidate's official game | User-confirmed |
| Candidate reaches playable gameplay after login | FAIL, missing page background and repeated server-selection loop; diagnosis ongoing |
| Runtime comparison against the working development setup | PASS, 6,166 entries match in hashes, symlink targets, and modes |
| Candidate game and browser helpers load matching DXMT | Observed; module loading does not establish correct rendering |
| Synthetic installer rejection and privacy checks | 41 assertions passed |
| Core configuration, paths, hashing, locks, and command checks | PASS |
| Three cold Finder launches through official updater | NOT TESTED |
| Normal quit, descendant cleanup, and relaunch | NOT TESTED |
| Installation lock during a real session | PASS, independent acquisition rejected; second GUI launch still untested |
| Movement, combat, chat, menus, and clipboard individually | NOT TESTED |
| Window size, fullscreen, display scaling, external display | NOT TESTED |
| Audio behavior | NOT TESTED |
| Measured performance and resource use | NOT TESTED |
| Recovery after network loss or interrupted update | NOT TESTED |
| Official update, verification, and removal with real data | NOT TESTED |
| Installation on another Mac | NOT TESTED |

Synthetic tests cover only the behaviors they exercise. Build success, a visible launcher window, and process uptime do not establish gameplay. Keep results tied to the app build and dependency versions tested. Recheck affected behavior when the app, game, or runtime changes.

The matching runtime files and observed DXMT loading narrow the investigation. They do not explain the page problem or establish that the complete installed environment behaves like the development setup. Do not describe the packaged candidate as a working gameplay release while this failure remains unresolved.

Machine-readable results and the tested executable fingerprint are in [verification.json](verification.json). A developer probe exercised the same native installer code used by the app; this does not claim the entire graphical file-picker flow was tested.
