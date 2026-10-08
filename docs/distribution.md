# Distribution and legal review

Reviewed 8 October 2026. For the current packages, the review found no specific third-party redistribution restriction on sharing our independently written launcher, original icon, and documentation. This is a scoped finding, not publisher endorsement, a legal opinion from counsel, or a guarantee against claims or account restrictions.

Earlier notes treated the absence of explicit approval as a blanket public-release blocker. That was too broad. Publishing our own material, using separately downloaded software, and providing a polished Mac download are different questions.

## What is included

The packages contain original project source, its native helper app, documentation, tests, and notices. MIT applies only to that original material. They contain no game binaries, artwork, installed Windows environment, runtime binaries, installers, or account state. Users obtain unmodified dependencies from their providers.

| Area | Finding for the current scope |
| --- | --- |
| Original launcher and guide | No specific third-party redistribution restriction identified in the reviewed sources |
| Game and runtime redistribution | Excluded; bundling them would require a new component-by-component review |
| Gameplay through this Wine setup | Historically supported in principle; no current publisher assurance for this exact configuration or account treatment |
| Windows .NET through Wine | Microsoft supplies the runtime for end users; Wine-specific licensing/support assurance was not found |
| Descriptive use of the game name | Reviewed as a compatibility reference with prominent unofficial wording; not worldwide trademark clearance |
| Signing, notarization, broader testing | Delivery work, separate from copyright and license permission |
| Publication | Not authorized by the project owner; everything remains local |

## Publisher policy

[Bigpoint's current terms](https://legal.bigpoint.com/DE/terms-and-conditions/en-GB), especially sections 1.2.8 and 8.3, and [game rule 6](https://board-en.darkorbit.com/threads/game-rules.704/) restrict gameplay automation and external programs that influence the game; the terms also restrict reproduction, analysis, and modification of game material. The reviewed text does not expressly identify Wine or require permission merely to publish an independently written helper or factual guide.

The project opens the unchanged official updater/client. It does not automate gameplay, collect credentials, bypass authentication, or distribute game material. This is why the review distinguishes its scope from bots and modified clients; it is an interpretation of the reviewed facts, not a commitment from Bigpoint.

The DarkOrbit team published [macOS instructions using Wine in December 2020](https://board-fr.darkorbit.com/threads/jouer-avec-le-client-darkorbit-sur-macos.132735/). That is favorable historical evidence. It does not establish current approval of this implementation or a guarantee about accounts. If an affirmative answer on current account policy is required, seek written publisher clarification or qualified advice on these specific clauses.

## Microsoft and other dependencies

Microsoft describes [Desktop Runtime 6.0.36 as a way to run existing desktop applications](https://dotnet.microsoft.com/en-us/download/dotnet/6.0) and says its [runtimes have no licensing costs, including commercial use](https://dotnet.microsoft.com/en-us/platform/free). Its [installation guidance](https://learn.microsoft.com/en-us/dotnet/core/install/windows) addresses both users and developers. Ordinary end-user runtime use should not be treated as presumptively prohibited just because the embedded license also discusses development and testing.

The exact installer terms and notices were inspected without execution. Their fingerprints are in `dependencies.json`. They remain relevant alongside the [Windows component licensing notice](https://github.com/dotnet/core/blob/main/license-information-windows.md); a general free-software statement does not replace those terms. No express Wine prohibition was found in the embedded .NET Library text, but absence of a prohibition is not affirmative approval or support for Wine.

The Windows SDK restriction identified in that notice concerns distributing its code for non-Microsoft platforms. Our package distributes no Microsoft code. That restriction does not by itself bar publishing this separate Swift launcher or guide, or establish a blanket prohibition on local Wine use. Provider downloads and the terms checkbox are not substitutes for applicable rights.

Wine, DXMT, and support-library redistribution duties would matter if their binaries were added later. Missing exact binary/source correspondence is not a blocker for a package that does not contain those binaries. Keep the current exclusion and preserve [third-party notices](../THIRD_PARTY_NOTICES.md).

## Name and presentation

Use the description **Unofficial macOS launcher for DarkOrbit**, identify the game only to explain compatibility, keep the original icon, and place the non-affiliation statement nearby. Do not use publisher logos or describe the helper as an official or native game client.

[EU Regulation 2017/1001, Article 14(1)(c) and 14(2)](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32017R1001) allows certain honest referential uses of a trademark. Permission is not universally required merely to mention a compatible product. This EU rule is not worldwide clearance of a name, domain, advertisement, or future presentation. Review any materially different branding separately.

## Release decision and privacy

The source and helper-only package review is complete within the stated scope. No blanket provider-permission prerequisite has been established for publishing those original files. Current account-policy and Wine-specific assurances remain unconfirmed; obtain targeted clarification or qualified legal review if those assurances are required before your publication decision. No zero-risk promise is made.

Signing/notarization and remaining acceptance checks are still needed for a finished ordinary-user download. They do not grant intellectual-property rights. Publishing also requires the owner's explicit authorization; this review sends or publishes nothing.

Share only the audited source and app archives when an export is authorized. Do not upload the enclosing development folder, installation data, or private reports. The source ZIP omits Git metadata. A future Git push can disclose author and committer names, email addresses, and timestamps. A signing certificate or hosting account can also identify the publisher.
