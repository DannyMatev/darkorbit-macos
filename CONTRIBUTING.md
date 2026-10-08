# Contributing

This is an unofficial, vibe-coded hobby project built with AI assistance. Clear reports, tested fixes, and readable documentation are welcome. AI assistance does not replace review or testing.

Start with the [developer guide](docs/development.md) and [architecture](docs/architecture.md). Keep changes small enough to review and explain the problem, resulting behavior, and checks performed.

Useful contributions include testing another Mac configuration, improving installation or accessibility, checking lifecycle behavior, documenting reproducible failures, and reviewing dependency provenance. Consult [Compatibility](docs/compatibility.md) before assuming something has already been tested.

## Project rules

- Preserve the official game and its normal updater and login flow. Do not add gameplay automation, game patches, authentication workarounds, or private-server functionality.
- Never add downloaded games, runtimes, installers, account data, raw logs, or copies of a Windows environment.
- Do not change macOS security settings, remove quarantine, or stop all Wine processes.
- Derive user directories at runtime. Use neutral examples, synthetic fixtures, and fixed error messages.
- Preserve third-party notices and review dependency changes. The project's license does not relicense upstream software.
- Keep prose direct and readable. Avoid decorative emojis, em dashes, invisible characters, hidden HTML text, and generated filler.
- Record untested behavior honestly. A user report, a measured result, and a synthetic test are different kinds of evidence.

## Reports and patches

Use an issue template for a reproducible problem or compatibility report once a repository is published. Do not include passwords, tokens, cookies, home paths, account screenshots, or raw logs. There is no private security-reporting channel configured, so never post secrets or exploit details publicly.

For a patch, run relevant tests, check the publication contents for private data, and update affected documentation. Include the exact versions needed to reproduce the result. Do not claim publisher approval, legal clearance, or guaranteed account safety.

This local candidate has no remote repository configured for publication. Commit meaningful changes locally. Publishing code, releases, or announcements requires a separate decision.
