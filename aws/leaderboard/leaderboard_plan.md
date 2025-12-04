# Leaderboard Backend Implementation Plan

## Goal
Deliver the AWS leaderboard service per `leaderboard_spec.md` using SAM, Node.js 24.x Lambdas, DynamoDB storage, HMAC request validation, and AWS-native CI/CD (CodePipeline/CodeBuild) for dev/stage/prod. Ensure full deployment instructions are provided in a text file for how to provision the pipeline and do any wiring or configuration.

## Public API (final contract)
- Security: HTTPS; JSON; header `X-Signature = hex(hmac_sha256(secret, canonical_payload))`. Canonical payload: stable-key-order JSON (POST) or sorted query string (GET).
- `POST /leaderboard/submit` body `{game_id, player_id, player_name?, score, nonce, timestamp}` -> `200 {"status":"ok","accepted":true,"new_best":<bool>}`; `400` for `invalid_signature|validation_error`, `429` throttled.
- `GET /leaderboard/top` query `game_id` (required), `limit` (default 10, max 100) -> `{"game_id":..., "entries":[{player_name, score, rank}, ...]}`.
- `GET /leaderboard/player` query `game_id`, `player_id` -> `{"has_score":false,...}` or `{"has_score":true,"score":<int>,"rank":<int>,"total_players":<int?>}`.
- `GET /leaderboard/top-with-player` query `game_id`, `player_id`, `limit` -> `entries` list + `player` summary (`included_in_top` flag).

## Architecture & Components
- SAM template: HTTP API routes to four Lambdas (`SubmitScore`, `GetTopScores`, `GetPlayer`, `GetTopWithPlayer`).
- DynamoDB table `LeaderboardScores`: PK `game_id` (S), SK `score_sort` (N = -score); attrs `score`, `player_id`, `player_name`, `created_at`, `ttl`. Optional GSI `GSI_Player` (PK `player_id`, SK `game_id`) for per-player lookups.
- IAM: least-privilege for Lambdas (table read/write, secrets access).
- Secrets: HMAC secret in SSM/Secrets Manager; env var `HMAC_SECRET_PARAM`/`HMAC_SECRET_ARN` + retrieval at cold start.
- Config params/env: `TABLE_NAME`, `MAX_SCORE`, `TIMESTAMP_SKEW_SECS`, `ENABLE_TTL`, optional `REPLAY_TTL_SECS`.
- Pipeline IaC stack: CodePipeline + CodeBuild (and SAM deploy action) sourcing from this repository and triggering on commits; roles/policies defined in the same IaC.

## Lambda Responsibilities
- Shared lib (`src/lib`):
  - `canonicalizeBody`, `canonicalizeQuery`
  - `verifySignature(secret, payload)`
  - `validateSubmit`, `validateTop`, `validatePlayer`, `validateTopWithPlayer`
  - `dynamo` helpers: `putBestScore`, `queryTop`, `getPlayerBest`, `countHigherScores`, `ensureNonce`
  - `responses` helpers with consistent CORS/JSON headers
- `SubmitScoreFunction`:
  - Load secret, verify HMAC, validate inputs and timestamp skew, optional nonce dedupe (Dynamo item with TTL).
  - Fetch existing best for `(game_id, player_id)` via GSI or summary item; if better score, upsert with `score_sort=-score`, set `created_at`, optional `ttl`.
  - Return accepted/new_best flags; log rejects (reason) and emit metrics.
- `GetTopScoresFunction`:
  - Validate params; query table by `game_id` ordered by `score_sort` ascending; limit; compute rank in-memory.
- `GetPlayerFunction`:
  - Validate; fetch player best (GSI or summary); compute rank via `countHigherScores` (`score_sort < -score`); include `total_players` if feasible (counter or bounded count query).
- `GetTopWithPlayerFunction`:
  - Compose `GetTopScores` + `GetPlayer`; if player in top list, mark `included_in_top=true` without duplicate query when possible.

## Data & Access Patterns
- Top list: Query PK `game_id`, SK ascending `score_sort`, `Limit = N`.
- Player best: `GSI_Player` query by `player_id` filtered by `game_id`, or per-player summary item keyed by `game_id` + `player_id`.
- Rank: count items with `score_sort < -score`; if performance becomes an issue, allow approximate rank with documented semantics.
- TTL (optional): enable via SAM param; apply to items if leaderboard should prune old entries.

## Security & Abuse Controls
- HMAC-SHA256 on every request; reject missing/invalid signature.
- Timestamp skew check ±5 minutes (param).
- Nonce replay protection optional with short TTL items.
- API Gateway throttling + usage plans; WAF hooks (document, optional).
- Input bounds: score `0..MAX_SCORE`; strings non-empty; limits capped at 100.

## Observability
- Structured logs (JSON) for errors, validation failures, signature failures.
- Metrics counters: submissions accepted/rejected, top queries, player queries, replay blocks.
- Optional CloudWatch alarms for elevated error rates or throttling.

## CI/CD & Developer Workflow
- `package.json` scripts: `lint` (optional), `test` (Jest), `build` (tsc), `sam-build`, `sam-deploy --config-env`.
- AWS-native pipeline (IaC-defined): CodePipeline stages -> Source (this repo, commit-triggered via CodeStar Connections/GitHub or CodeCommit) -> Build (CodeBuild: `npm ci`, `npm test`, `npm run build`, `sam build`) -> Deploy (CodeBuild or CloudFormation action running `sam deploy` with env-specific params).
- Single-use IaC template provisions pipeline resources; any pipeline modification is delivered as a delta to that IaC.
- Pipeline must use AWS services (CodePipeline/CodeBuild/CodeDeploy/SAM deploy) and deploy automatically on commits to this repository; support dev/stage/prod via parameters or per-environment pipelines.
- Local testing: `sam local invoke` with event fixtures; document in README.

## File/Folder Layout
- `aws/leaderboard/template.yaml`
- `aws/leaderboard/src/submitScore.ts`
- `aws/leaderboard/src/getTopScores.ts`
- `aws/leaderboard/src/getPlayer.ts`
- `aws/leaderboard/src/getTopWithPlayer.ts`
- `aws/leaderboard/src/lib/*` (crypto, validation, dynamo, responses)
- `aws/leaderboard/tests/*.test.ts` with Jest + sample events
- `aws/leaderboard/README.md`
- `aws/leaderboard/pipeline.yaml` (CodePipeline/CodeBuild IaC)

## Open Questions/Assumptions
- Rank accuracy: plan to use exact count query; if cost/performance issues arise, may introduce approximate rank + precomputed aggregates (would be a versioned change).
- Replay cache: default enablement TBD; design supports optional toggle.
- Per-player summary item vs GSI: will pick GSI for clarity unless constraints require summary items (document decision in code comments/README).
- Pipeline source connection: assumes repository access via CodeStar Connection ARN (GitHub) or CodeCommit; confirm at implementation time and parameterize if needed. Trigger via webhook.
