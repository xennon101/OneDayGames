# Multiplayer Client Plan

## Goal
Implement shared Godot-side matchmaking and signalling clients (`MatchmakingManager.gd`, `NetSessionManager.gd`) that align with `shared_systems_spec.md` and `aws/multiplayer/multiplayer_spec.md`, providing async flows for queueing, match status, and signalling.

## API Contract (client ↔ backend)
- HTTPS JSON; header `X-Signature = hex(hmac_sha256(secret, canonical_payload))`.
- Canonical payload: stable-key-order JSON for POST bodies; sorted query string for GET.
- Endpoints:
  - `POST /queue/join` body `{player_id, game_id, mode, region, metrics?, nonce, timestamp}` → `{"status":"ok","queued":true}`.
  - `POST /queue/leave` body `{player_id, game_id, mode, region, nonce, timestamp}` → ack.
  - `GET /match/status` query `player_id`, `game_id`, optional `mode`, `region` → `{"status":"searching"}` or `{"status":"matched","match_id", "role","game_id","mode","region"}`.
  - `POST /match/signal` body `{match_id, from_player_id, to_player_id, payload, nonce, timestamp}` → `{"status":"ok","stored":true}`.
  - `GET /match/signal` query `match_id`, `player_id` → `{"match_id","messages":[{from_player_id,payload,timestamp}]}`.

## Config Surface (ConfigManager)
- `matchmaking.base_url` (string, required for calls).
- `matchmaking.enabled` (bool, default false).
- `matchmaking.hmac_key` (string, secret injected; never hardcode).
- `matchmaking.poll_interval_secs` (default 2–3s).
- `matchmaking.timeout_secs` (default 8s per request).
- `matchmaking.region_default` and optional mode default.

## Planned Structure
- `MatchmakingManager.gd` (autoload):
  - Public API (per spec): `queue_for_match(game_id, mode, metrics={})`, `cancel_queue(game_id, mode)`, `poll_match_status(game_id, mode, callback)`, `send_signal(match_id, payload)`, `poll_signals(match_id, callback)`.
  - Internal helpers: canonicalize JSON/query, sign payload, shared HTTP request (with retries/backoff), validate enabled/base_url/secret.
  - State tracking: last queued request (match_id, status), current poll timers.
- `NetSessionManager.gd`:
  - Consume match status result to decide host/client; call WebRTC setup; route signalling messages to/from MatchmakingManager.
  - Expose `handle_signalling_message` entry for incoming payloads.
- Integration:
  - Use `PlayerIdentityManager.get_player_id()` for all requests.
  - Emit events on status changes (matched/searching/error) via EventBus if useful for UI.
  - Non-blocking; safely no-op if matchmaking disabled or base_url missing.
- Security:
  - Include `nonce` (UUID) and `timestamp` per request; sign with HMAC secret from config.
  - Do not send requests without signature; surface errors via callbacks.

## Implementation Steps
1) Extend ConfigManager defaults with `matchmaking` keys; ensure load/merge behavior works.
2) Implement canonicalize + sign helpers (shared inside MatchmakingManager).
3) Build HTTP request wrapper with timeout/retries, attaches X-Signature, and parses JSON; map non-2xx to controlled errors.
4) Implement queue/leave/match status flows; start/stop polling loop for status until matched or canceled.
5) Implement signalling send/poll methods; deliver messages to NetSessionManager; acknowledge/clear any client-side queues.
6) Wire NetSessionManager to create WebRTC peers (host/client) when matched; route send/receive of signalling payloads.
7) Add minimal Godot tests (GUT or existing test runner) for canonicalization, signing, disabled-mode behavior, and polling logic (mock HTTPRequest).
8) Document usage expectations for games (how to start matchmaking, handle callbacks, and cleanly cancel).

## Open Questions/Assumptions
- Region/mode allowed values: assume supplied by game UI/config; validate only non-empty strings client-side.
- Polling cadence: default 2–3s; can be made configurable.
- Signalling payload format: opaque dictionary passed through to backend; NetSessionManager translates to WebRTC messages.
