# Multiplayer Service Specification  
Location: `aws/multiplayer/spec.md`  
Applies to: the AWS-based matchmaking and signalling backend used by all OneDayGames titles for peer-to-peer multiplayer.

This document defines the backend services that queue players for multiplayer games, create matches, and exchange signalling data required for peer-to-peer sessions. It is implemented on AWS using serverless components and is consumed by client-side code via MatchmakingManager.gd and NetSessionManager.gd.

---

## 1. Goals and Scope

- Provide a simple, generic matchmaking service for peer-to-peer games.
- Support anonymous players identified by a per-device `player_id` (no user authentication).
- Pair players based on basic metrics (for example game_id, mode, region, and optional MMR or latency hints).
- Provide a signalling channel for exchanging WebRTC (or other transport) session descriptions and ICE candidates between matched peers.
- Keep cost and complexity low using AWS serverless components.
- Define all infrastructure, code, and pipelines using Infrastructure as Code.

This service does not run the game simulation; all gameplay is peer-to-peer between clients.

---

## 2. High-Level Architecture

The multiplayer service consists of:

- AWS API Gateway (HTTP API) exposing at minimum:
  - `POST /queue/join`
  - `POST /queue/leave`
  - `GET /match/status`
  - `POST /match/signal`
  - `GET /match/signal`
- AWS Lambda functions (Node.js 24.x runtime) implementing:
  - Queueing and unqueueing players.
  - Matchmaking logic.
  - Match status lookups.
  - Signalling message handling.
- Amazon DynamoDB tables for:
  - Matchmaking queue.
  - Active matches.
  - Signalling messages (short-lived).
- IAM roles and permissions for Lambdas and DynamoDB access.
- Infrastructure as Code using AWS SAM (template.yaml).
- CI/CD pipelines to build, test, and deploy the service.

---

## 3. Data Model

### 3.1 Matchmaking Queue Table

Table name: `MatchQueue` (configurable).

Primary key:

- Partition key: `queue_key` (String)  
  - Composition: `region#game_id#mode`.
- Sort key: `enqueue_time` (Number or String)  
  - Timestamp (for example epoch millis or ISO) used to order players in the queue.

Attributes:

- `player_id` (String)
- `metrics` (Map) – optional metrics such as MMR, latency_hint.
- `enqueue_time` (Number or String) – duplicate of sort key for convenience.
- `status` (String) – for example `"queued"`, `"matched"`, `"removed"`.
- `match_id` (String, optional) – set when player is matched.

### 3.2 Matches Table

Table name: `Matches` (configurable).

Primary key:

- Partition key: `match_id` (String)

Attributes:

- `match_id` (String)
- `game_id` (String)
- `mode` (String)
- `region` (String)
- `player_a_id` (String)
- `player_b_id` (String)
- `host_player_id` (String) – which player acts as host/authority in P2P.
- `created_at` (String)
- `state` (String) – for example `"pending"`, `"active"`, `"completed"`.
- `metadata` (Map, optional) – extra info as needed.

### 3.3 Signalling Table

Table name: `MatchSignals` (configurable).

Primary key:

- Partition key: `match_id` (String)
- Sort key: `timestamp` (Number or String)

Attributes:

- `match_id` (String)
- `timestamp` (Number or String)
- `from_player_id` (String)
- `to_player_id` (String)
- `payload` (String or Map) – signalling data (for example WebRTC SDP, ICE).
- `ttl` (Number, optional) – for automatic expiry.

---

## 4. API Design

All endpoints:

- Use HTTPS via API Gateway HTTP API.
- Accept and return JSON.
- Use HMAC-signed requests with a client-held shared secret, passed via `X-Signature` header.
- Enforce rate limits via API Gateway and optionally AWS WAF.

### 4.1 Common Request Fields

Most requests from clients will include:

- `player_id` – anonymous ID from PlayerIdentityManager.
- `game_id` – identifies which game is being played.
- `mode` – game-specific mode name (for example `"ranked"`, `"casual"`).
- `region` – region string (for example `"eu"`, `"us"`).
- `nonce` – random UUID for replay protection.
- `timestamp` – Unix epoch seconds or milliseconds.

These fields must be validated in Lambda:

- Non-empty strings where required.
- Reasonable regions and modes based on configuration.
- Timestamp must be within a configurable skew (for example ±5 minutes).

### 4.2 `POST /queue/join`

Request body (example):

```json
{
  "player_id": "uuid-from-client",
  "game_id": "MyGame",
  "mode": "default",
  "region": "eu",
  "metrics": {
    "mmr": 1200,
    "latency_hint": 40
  },
  "nonce": "random-uuid",
  "timestamp": 1730000000
}
```

Behaviour:

- Verify HMAC signature using shared secret from Parameter Store or Secrets Manager.
- Validate payload.
- Construct `queue_key = region + "#" + game_id + "#" + mode`.
- Insert or update an item in `MatchQueue` with:
  - `queue_key`
  - `enqueue_time`
  - `player_id`
  - `metrics`
  - `status = "queued"`.
- Return a simple acknowledgement:

```json
{
  "status": "ok",
  "queued": true
}
```

Matchmaking logic may be invoked in the same Lambda or by an asynchronous process.

### 4.3 `POST /queue/leave`

Request body:

```json
{
  "player_id": "uuid-from-client",
  "game_id": "MyGame",
  "mode": "default",
  "region": "eu",
  "nonce": "random-uuid",
  "timestamp": 1730000000
}
```

Behaviour:

- Verify signature and validate payload.
- Look up and mark the player as removed from `MatchQueue` (for example by updating `status` to `"removed"` or deleting the entry).
- Return a simple acknowledgement.

### 4.4 `GET /match/status`

Query parameters:

- `player_id` (required)
- `game_id` (required)
- `mode` (optional)
- `region` (optional)

Behaviour:

- Lookup player in `MatchQueue` and/or `Matches`.
- If still searching, return:

```json
{
  "status": "searching"
}
```

- If matched, return at minimum:

```json
{
  "status": "matched",
  "match_id": "match-uuid",
  "role": "host", 
  "game_id": "MyGame",
  "mode": "default",
  "region": "eu"
}
```

The `"role"` field indicates whether this client should host or join the P2P session.

### 4.5 `POST /match/signal`

Request body (example for WebRTC):

```json
{
  "match_id": "match-uuid",
  "from_player_id": "uuid-a",
  "to_player_id": "uuid-b",
  "payload": {
    "type": "offer",
    "sdp": "..."
  },
  "nonce": "random-uuid",
  "timestamp": 1730000000
}
```

Behaviour:

- Verify signature and validate payload.
- Ensure the sender belongs to the match.
- Write a record into `MatchSignals` with:
  - `match_id`
  - `timestamp`
  - `from_player_id`
  - `to_player_id`
  - `payload`
  - Optional TTL for expiry.
- Return acknowledgement:

```json
{
  "status": "ok",
  "stored": true
}
```

### 4.6 `GET /match/signal`

Query parameters:

- `match_id` (required)
- `player_id` (required)
- Optional filter (for example since timestamp).

Behaviour:

- Query `MatchSignals` for items belonging to `match_id` where `to_player_id` equals the requesting `player_id`.
- Return an array of signalling messages and optionally delete or mark them as consumed.

Example response:

```json
{
  "match_id": "match-uuid",
  "messages": [
    {
      "from_player_id": "uuid-a",
      "payload": {
        "type": "offer",
        "sdp": "..."
      },
      "timestamp": 1730000000
    }
  ]
}
```

---

## 5. Matchmaking Logic

The matchmaker's initial implementation can use a simple algorithm:

- Group players by `queue_key` (region, game_id, mode).
- Within each group:
  - Sort by `enqueue_time`.
  - Optionally consider `metrics.mmr` to pair players with similar MMR.
- Pair players in FIFO order or nearest-metric order.
- For each pair:
  - Create a new `match_id`.
  - Decide host:
    - Could be random or based on `latency_hint` or a simple rule (for example lower latency).
  - Create a record in `Matches`.
  - Update both players' entries in `MatchQueue` to include `match_id` and `status = "matched"`.

The matchmaker can run:

- Synchronously during `queue/join`, or
- As a separate scheduled Lambda triggered at regular intervals.

---

## 6. Security and Abuse Mitigation

- All requests must be HMAC-SHA256 signed using a shared secret.
- All fields must be validated and constrained to avoid:
  - Arbitrary injection into DynamoDB.
  - Excessive queue pollution.
- Use API Gateway throttling to limit:
  - Requests per IP.
  - Requests per API key (if using API keys).
- Optional AWS WAF rules can be used to block:
  - Known bad IP ranges.
  - Abnormal request rates.

This system does not attempt to prevent cheating in the game itself; it aims to prevent unauthenticated third parties from abusing the matchmaking infrastructure.

---

## 7. AWS Implementation Details

### 7.1 Runtimes and Language

- All Lambda functions must use runtime `nodejs24.x`.
- Language: Node.js with modern `async/await`.
- Suggested layout:

- `aws/multiplayer/template.yaml` – AWS SAM template.
- `aws/multiplayer/src/queueJoin.ts` – `POST /queue/join`.
- `aws/multiplayer/src/queueLeave.ts` – `POST /queue/leave`.
- `aws/multiplayer/src/matchStatus.ts` – `GET /match/status`.
- `aws/multiplayer/src/matchSignalPost.ts` – `POST /match/signal`.
- `aws/multiplayer/src/matchSignalGet.ts` – `GET /match/signal`.
- `aws/multiplayer/src/lib/` – shared helpers (HMAC, validation, DynamoDB access, matchmaking algorithm).
- `aws/multiplayer/tests/` – Jest unit tests.
- `aws/multiplayer/package.json` – dependencies and scripts.
- `aws/multiplayer/README.md` – documentation.

### 7.2 Infrastructure as Code (AWS SAM)

The SAM template must define:

- An HTTP API with routes:
  - `POST /queue/join` → QueueJoinFunction
  - `POST /queue/leave` → QueueLeaveFunction
  - `GET /match/status` → MatchStatusFunction
  - `POST /match/signal` → MatchSignalPostFunction
  - `GET /match/signal` → MatchSignalGetFunction
- Lambda functions with runtime `nodejs24.x`.
- DynamoDB tables:
  - `MatchQueue`
  - `Matches`
  - `MatchSignals`
- IAM policies for least-privilege access:
  - Each function should have only the DynamoDB permissions it needs.
- Parameters and environment variables for:
  - Table names.
  - Shared HMAC secret parameter path.
  - Matching and timeout configuration (for example max queue time).

---

## 8. Build and Deployment Pipeline

The multiplayer service must include a CI/CD pipeline configuration that:

- Checks out the repository.
- Installs dependencies for the multiplayer service.
- Runs unit tests (e.g. using Jest).
- Builds TypeScript to JavaScript (if used).
- Runs `sam build` to package the application.
- Runs `sam deploy` to deploy to the target environment.

It should support at least:

- `dev`
- `stage`
- `prod`

environments via separate stacks or parameters.

---

## 9. Client Integration Contract

On the Godot side:

- MatchmakingManager.gd must call:
  - `/queue/join` and `/queue/leave` to manage the queue.
  - `/match/status` to determine when a match has been created and what role the player should assume (`host` or `client`).
  - `/match/signal` (POST and GET) to exchange signalling data between players.
- NetSessionManager.gd must:
  - Use data from MatchmakingManager to decide when to create or join a P2P session.
  - Translate signalling payloads into WebRTC/ENet operations.
- All calls must use `player_id` from PlayerIdentityManager.
- All network operations must be asynchronous and must not crash the game on error.
- If matchmaking is disabled or the backend is unreachable, games must remain fully playable in single-player or local modes.

Any future changes to this spec must preserve backward compatibility at the API boundary or introduce a versioned API (for example `/v2/queue/join`).

