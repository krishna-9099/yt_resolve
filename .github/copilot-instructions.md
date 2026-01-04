# Copilot / AI Agent Guide for yt_resolve 🚀

## Quick project summary
- Purpose: small Dart library + CLI to resolve YouTube playable stream URLs given a video ID.
- Entrypoint: `bin/yt_resolve.dart` (prints resolved stream URL)
- Test harness: `test/*` using `package:test`

## Big-picture architecture 🔧
- Engine: `lib/engine/resolver.dart` (main pipeline: fetch playerResponse, extract formats, score, probe, return `ResolvedStream`).
- Clients: `lib/clients/*` (e.g., `WebClient` implements `BaseClient`). These are **stubs** in this repo.
- Extractors: `lib/extract/*` (e.g., `PlayerFetcher`, `FormatsExtractor`) - transform parsed player response -> `Format` objects.
- Scoring & selection: `lib/score/scorer.dart` - returns a numeric score used to pick the best format.
- Probe: `lib/probe/http_probe.dart` - lightweight playability probe (currently a stub that returns `true`).
- Models: `lib/model/*` (e.g., `Format`, `ResolvedStream`, `PlayerResponse`).

## Key conventions & patterns ✅
- Small, immutable model objects (use `final` fields, prefer `const` constructors where possible).
- Most public APIs return `Future` even when stubbed; follow async/await style.
- The resolver tolerates client errors (it logs and continues). Do not crash the whole pipeline on a single client failure.
- DI is partially used: `YtResolve` accepts `HttpProbe` and `Scorer` (so tests can inject deterministic probes/scorers). Note: `PlayerFetcher` and clients are instantiated inside `resolve()` currently (see below for testing guidance).

## Where to implement real integrations / extensions 🔗
- HTTP / Innertube client: implement real calls in `lib/clients/web_client.dart#fetchPlayer` (should call `youtubei/v1/player` and return parsed JSON map).
- Player fetch orchestration: update `lib/extract/player_fetcher.dart#fetch` to use client(s) and HTTP helpers.
- Format extraction: extend `lib/extract/formats_extractor.dart#extract` to parse actual `playerResponse.raw` into `Format` instances.
- Playability probe: implement real HTTP range/HEAD checks in `lib/probe/http_probe.dart#probe`.
- Client rotation: update `_clientOrderFor` in `lib/engine/resolver.dart` when adding new client flavors (e.g., mobile/innertube variants).

## Testing & debugging workflow 🧪
- Run tests: `dart test -r expanded` (the project uses `package:test`).
- Typical debug run: `dart run bin/yt_resolve.dart <videoId>` (defaults to `dQw4w9WgXcQ`).
- CI / reproducible tests: tests currently rely on stubs (no network). When adding networked code, **mock the network layer** or provide a way to inject a fake `PlayerFetcher`/`HttpProbe` (preferred).

## Tests and writing changes 📋
- Add unit tests under `test/`. Existing tests show patterns: small focused assertions and using the public API `YtResolve`.
- When adding a networked service, add both:
  - unit tests that mock/override dependencies (e.g., inject a fake `HttpProbe` or `Scorer`) and
  - optional integration tests guarded by environment variables that run only when network access is allowed.

## File & symbol checklist (where to look) 📚
- Main pipeline: `lib/engine/resolver.dart` (core behavior)
- Client interfaces: `lib/clients/base_client.dart`, `lib/clients/web_client.dart`
- Player fetching & extraction: `lib/extract/player_fetcher.dart`, `lib/extract/formats_extractor.dart`
- Models: `lib/model/*` (`format.dart`, `stream.dart`, `player_response.dart`)
- Scoring & probing: `lib/score/scorer.dart`, `lib/probe/http_probe.dart`
- CLI: `bin/yt_resolve.dart`

## Small, actionable tips for contributors (AI-specific) 💡
- Prefer minimal, well-tested changes: add a small unit test that fails before implementing a change.
- Keep behavior backward-compatible: `YtResolve.resolve` must still return a `ResolvedStream` or throw `ResolveException` when nothing found.
- Use dependency injection where helpful (e.g., allow injecting `PlayerFetcher` in `YtResolve` to make tests deterministic).
- Use existing message format for debug logs (`[yt_resolve] …`) or switch to a single logger consistently across the project.

---

If you'd like, I can (a) add an example unit test that exercises a real HTTP client behind a mock, or (b) refactor `YtResolve` to accept an injectable `PlayerFetcher` to make testing easier—tell me which to do next.