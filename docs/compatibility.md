# Compatibility and test evidence

Updated 8 October 2026. A successful development setup and a verified application release are different milestones.

## Gameplay evidence

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
| Clean installation through the final app | NOT TESTED |
| Three cold Finder launches through official updater | NOT TESTED |
| Normal quit, descendant cleanup, and relaunch | NOT TESTED |
| Duplicate-launch prevention during a real session | NOT TESTED |
| Movement, combat, chat, menus, and clipboard individually | NOT TESTED |
| Window size, fullscreen, display scaling, external display | NOT TESTED |
| Audio behavior | NOT TESTED |
| Measured performance and resource use | NOT TESTED |
| Recovery after network loss or interrupted update | NOT TESTED |
| Official update, verification, and removal with real data | NOT TESTED |
| Installation on another Mac | NOT TESTED |

Synthetic tests cover only the behaviors they exercise. Build success, a visible launcher window, and process uptime do not establish gameplay. Keep results tied to the app build and dependency versions tested. Recheck affected behavior when the app, game, or runtime changes.
