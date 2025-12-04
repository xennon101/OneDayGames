# Multiplayer Backend Implementation Plan

## Goal
Deliver the AWS multiplayer service per `multiplayer_spec.md` with SAM-defined HTTP API, Node.js 24.x Lambdas, DynamoDB queues/matches/signals, HMAC verification, and AWS-native CI/CD (CodePipeline/CodeBuild) triggered on commits.

## Public API (final contract)
- HTTPS JSON; header `X-Signature = hex(hmac_sha256(secret, canonical_payload))`; canonical JSON for POST, sorted query string for GET.
- `POST /queue/join` body `{player_id, game_id, mode, region, metrics?, nonce, timestamp}` → `{"status":"ok","queued":true}`.
- `POST /queue/leave` body `{player_id, game_id, mode, region, nonce, timestamp}` → ack.
- `GET /match/status` query `player_id`, `game_id`, optional `mode`, `region` → `{"status":"searching"}` or `{"status":"matched","match_id","role","game_id","mode","region"}`.
- `POST /match/signal` body `{match_id, from_player_id, to_player_id, payload, nonce, timestamp}` → `{"status":"ok","stored":true}`.
- `GET /match/signal` query `match_id`, `player_id` (optional since filter) → `{"match_id","messages":[{from_player_id,payload,timestamp}]}`.

## Architecture & Components
- SAM template defining HTTP API routes above.
- DynamoDB tables:
  - `MatchQueue` (PK `queue_key`, SK `enqueue_time`, attrs `player_id`, `metrics`, `status`, `match_id`).
  - `Matches` (PK `match_id`, attrs `game_id`, `mode`, `region`, `player_a_id`, `player_b_id`, `host_player_id`, `state`, `created_at`, `metadata`).
  - `MatchSignals` (PK `match_id`, SK `timestamp`, attrs `from_player_id`, `to_player_id`, `payload`, `ttl`).
- Lambdas:
  - `QueueJoinFunction` (POST /queue/join)
  - `QueueLeaveFunction` (POST /queue/leave)
  - `MatchStatusFunction` (GET /match/status)
  - `MatchSignalPostFunction` (POST /match/signal)
  - `MatchSignalGetFunction` (GET /match/signal)
- Shared lib modules: canonicalization, HMAC verify, validation, DynamoDB accessors, matchmaking algorithm, responses.
- Environment/params: table names, HMAC secret param path, timestamp skew, max queue time, default region/mode, signal TTL.

## Matchmaking Logic
- Build `queue_key = region#game_id#mode`.
- On join: upsert queued item with enqueue_time, metrics; trigger matchmaking inline or via helper.
- Matching algorithm: FIFO within queue_key, optional MMR closeness; pair earliest compatible two, choose host (lower latency or first in queue), create `match_id`, write `Matches` record, update both queue entries to `status=matched` and `match_id`.
- On status: if queue entry marked matched, return match details + role (host/client).
- On leave: delete or mark queue entry removed; clean up stale matches optionally.

## Security & Abuse Controls
- HMAC-SHA256 validation using secret from SSM/Secrets Manager; reject missing/invalid signatures.
- Validate required fields, region/mode non-empty, timestamp skew ±5m (configurable).
- API Gateway throttling; optional WAF.
- Signal table TTL to avoid storage growth; limit payload size.

## Observability
- Structured logs for validation/signature failures and matchmaking decisions.
- Metrics: queued, matched, leave events, status polls, signal posts/gets, errors; optional alarms on error/throttle.

## CI/CD (AWS-native, IaC-defined)
- CodePipeline source (repo commit-trigger via CodeStar Connection/CodeCommit) → CodeBuild: `npm ci`, `npm test`, `npm run build`, `sam build`, `sam deploy` with env-specific params.
- Pipeline defined in `aws/multiplayer/pipeline.yaml`; single IaC that provisions pipeline roles/projects; updates delivered as deltas to the same IaC per AGENTS 6.3.
- `samconfig.toml` with dev/stage/prod parameter sets for deployments.

## File/Folder Layout
- `aws/multiplayer/template.yaml`
- `aws/multiplayer/package.json`
- `aws/multiplayer/tsconfig.json`
- `aws/multiplayer/jest.config.cjs`
- `aws/multiplayer/src/queueJoin.ts`
- `aws/multiplayer/src/queueLeave.ts`
- `aws/multiplayer/src/matchStatus.ts`
- `aws/multiplayer/src/matchSignalPost.ts`
- `aws/multiplayer/src/matchSignalGet.ts`
- `aws/multiplayer/src/lib/*` (canonical, signature, validation, dynamo, matchmaking)
- `aws/multiplayer/tests/*.test.ts`
- `aws/multiplayer/pipeline.yaml` (CodePipeline/CodeBuild)
- `aws/multiplayer/samconfig.toml`
- `aws/multiplayer/README.md`

## Open Questions/Assumptions
- Host selection: default to first-in-queue unless latency metric provided; document rule.
- Match expiry: assume matches cleaned up by TTL or scheduled job; clarify during implementation.
- Region/mode validation list: assume configurable lists via env/parameter; otherwise accept any non-empty string.
