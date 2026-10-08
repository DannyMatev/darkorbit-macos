# Distribution review

This candidate is prepared locally. It is not cleared for public release. A source license and a disclaimer do not settle every dependency, contract, or branding question.

## What a project package contains

Only original launcher source, its native app, documentation, tests, and notices belong in this project's packages. Users obtain the game and runtime files from their providers. No game binary, asset, Windows environment, installer, runtime binary, or account state is redistributed here.

## Questions still open

1. **Publisher policy.** Bigpoint's official terms contain broad restrictions on game analysis, modification, and unauthorized scripts. No explicit approval of this Wine/DXMT configuration or its public launcher has been established. Confirm the applicable current terms and seek written clarification or qualified advice before public promotion. [Official terms, posted 10 June 2026](https://board-en.darkorbit.com/threads/general-terms-and-conditions.130276/)
2. **Dependency permissions.** Exact source/build correspondence and all support-library terms are unresolved. This prevents a blanket runtime redistribution claim. Separately downloading dependencies avoids bundling them but does not establish every permission for their use. See [Third-party notices](../THIRD_PARTY_NOTICES.md).
3. **Microsoft installer terms.** The .NET Library terms embedded in all four payloads of the pinned 6.0.36 installer have been reviewed. Their installation grant concerns designing, developing, and testing programs; the intended ordinary end-user gameplay use through Wine still needs qualified interpretation alongside the component terms. The current online terms differ from the embedded text. Neither the terms-review checkbox nor separate downloads establish permission. See the [Windows licensing notice](https://github.com/dotnet/core/blob/main/license-information-windows.md).
4. **Name and distribution identity.** The proposed app name identifies the game, but trademark clearance has not been established. Review the name, description, signing identity, and any future artwork before publishing. No publisher logo or artwork is included.
5. **User delivery.** A trusted signing/notarization workflow and packaged-app acceptance are pending. A local ad-hoc build is not a finished download for ordinary users.

These are release questions, not a claim that the project is necessarily prohibited. Keep preparation local while resolving them. Do not promise zero legal risk or protection from account restrictions.

There is relevant historical context: the DarkOrbit team published [macOS instructions using Wine in December 2020](https://board-fr.darkorbit.com/threads/jouer-avec-le-client-darkorbit-sur-macos.132735/). That supports past use of a compatibility layer. It predates the current game and this launcher, so it is not approval of this implementation or its public distribution. Missing runtime source/build correspondence is a question for any future runtime bundle, not evidence that distributing this separate launcher source is prohibited.

## Before a future publication

Review the exact proposed archive, notices, build results, and compatibility claims. Keep downloaded components and private reports out. Inspect the intended Git history and publication identity. Publish only after the owner explicitly authorizes it and the material release questions are addressed.

Share only the audited source and app archives when an export is authorized. Do not upload the enclosing development folder, installation data, or private reports. The source ZIP omits Git metadata. A future repository push can disclose author and committer names, email addresses, and timestamps even when the files contain no personal directories. A signing certificate or hosting account can also identify the publisher.
