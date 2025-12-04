# Leaderboard Client Plan

## Goal
Implement the shared `LeaderboardManager.gd` and supporting config/hooks to satisfy `shared_systems_spec.md` while matching the backend contract in `aws/leaderboard/leaderboard_spec.md`. Provide a stable async API for games to submit and fetch scores without leaking HTTP details.

## API Contract (client↔backend)
- HTTPS only; JSON requests/responses.
- Header `X-Signature` = `hex(hmac_sha256(secret, canonical_payload))`; canonical payload = stable-key-order JSON for POST, sorted query string for GET.
- `POST /leaderboard/submit` body: `{game_id, player_id, player_name?, score, nonce, timestamp}`. Success `200 {"status":"ok","accepted":true,"new_best":<bool>}`; `400` for signature/validation; `429` throttled.
- `GET /leaderboard/top` query: `game_id` (req), `limit` (default 10, max 100). Success `{"game_id":..., "entries":[{player_name, score, rank}, ...]}`.
- `GET /leaderboard/player` query: `game_id`, `player_id`. Success with `has_score` flag and optional `score`, `rank`, `total_players`.
- `GET /leaderboard/top-with-player` query: `game_id`, `player_id`, `limit`. Success includes `entries` plus `player` summary (`included_in_top` flag).

## Config Surface
- `leaderboard.base_url` (string, required for network calls).
- `leaderboard.enabled` (bool, default true; when false act as no-op with safe defaults).
- `leaderboard.hmac_key` or indirection `leaderboard.hmac_key_id` (secret injection; never hardcode).
- `leaderboard.max_score` (int bound for client-side validation).
- `leaderboard.timeout_secs` and `leaderboard.retry_attempts` (sane defaults; optional).

## Planned Structure
- Extend `shared/autoload/LeaderboardManager.gd` (new) using `HTTPRequest` node.
- Helpers:
  - `canonicalize_json(data: Dictionary) -> String`
  - `canonicalize_query(params: Dictionary) -> String`
  - `sign(payload: String) -> String`
  - `request(method, path, body_or_query, callback)`
- Public API:
  - `submit_score(game_id: String, score: int, player_name: String = "", callback: Callable = Callable())`
  - `fetch_top(game_id: String, limit: int = 10, callback: Callable)`
  - `fetch_player(game_id: String, callback: Callable)` (convenience)
  - `fetch_top_with_player(game_id: String, limit: int = 10, callback: Callable)`
- Normalized callback signature: `(result: Dictionary, error: String = "")`; errors empty string on success.

## Implementation Steps
1) Add defaults to `ConfigManager` schema under `leaderboard` and ensure bootstrap merges them.
2) Create `LeaderboardManager.gd` autoload registration in `project.godot` with HTTPRequest child setup and reusable request method (timeouts, retries).
3) Implement HMAC signing using `Crypto` class; pull secret from ConfigManager (no hardcoding).
4) Build submit flow: gather `player_id` from `PlayerIdentityManager`, add `nonce` (UUID) and `timestamp` (unix seconds), validate score within `leaderboard.max_score`, short-circuit if disabled.
5) Build fetch flows: map APIs to backend endpoints, parse responses into normalized arrays/dicts, compute local rank flags when needed.
6) Error handling: on network/signature/validation errors return empty lists or `has_score=false` without crashing; log via `push_error` or `print_error`.
7) UI integration hooks: ensure default template can call `fetch_top` and `submit_score`; keep logic self-contained so games only pass callbacks.
8) Security/resilience: honor `leaderboard.enabled=false`; never send requests without `base_url`; support retries with backoff; guard concurrent HTTPRequests by queueing or instancing temporary HTTPRequest nodes.
9) Tests: add GUT tests (or existing test runner) for canonicalization, signing, request construction (without real network), response normalization, disabled-mode behaviour.

## Open Questions/Assumptions
- Secret provisioning: assumes build/runtime injects `leaderboard.hmac_key`; if absent, Manager should log and operate as disabled.
- Replay protection: client only supplies nonce/timestamp; backend enforces reuse; client does not track nonce cache.
- Timeout values: assume 8s default unless project specifies otherwise.
