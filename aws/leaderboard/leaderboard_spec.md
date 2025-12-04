# Leaderboard Service Specification  
Location: `aws/leaderboard/spec.md`  
Applies to: the AWS-based global leaderboard backend used by all OneDayGames titles.

This document defines the backend service that stores and serves leaderboard entries for games. It is implemented on AWS using serverless components and is consumed by client-side code via LeaderboardManager.gd.

---

## 1. Goals and Scope

- Provide a simple, global leaderboard for each game.
- Allow players to submit scores and retrieve top scores.
- Require no user authentication; identity is anonymous and based on a per-device `player_id`.
- Use a client-held shared secret and HMAC signing to discourage trivial abuse.
- Be cost-efficient and easy to operate using serverless AWS components.
- Be defined entirely as Infrastructure as Code (IaC), including build and deployment pipelines.

---

## 2. High-Level Architecture

The leaderboard service consists of:

- AWS API Gateway (HTTP API) exposing:
- `POST /leaderboard/submit`
- `GET /leaderboard/top`
- AWS Lambda functions (Node.js 24.x runtime) implementing the API logic.
- Amazon DynamoDB table for score storage and querying.
- AWS IAM roles and permissions for Lambdas and DynamoDB access.
- Infrastructure as Code using AWS SAM (template.yaml).
- A CI/CD pipeline that:
- Installs dependencies.
- Runs unit tests.
- Builds and packages the Lambda functions.
- Deploys the stack via `sam deploy`.

---

## 3. Data Model

### 3.1 DynamoDB Table

Table name: `LeaderboardScores` (configurable via parameter)

Primary key:

- Partition key: `game_id` (String)
- Sort key: `score_sort` (Number)

Attributes:

- `game_id` (String) – identifier for the game (for example `CoinFlip`, `defaultTemplate`).
- `score_sort` (Number) – negative of the score (`-score`) so that the best scores sort first when querying.
- `score` (Number) – the original positive score.
- `player_id` (String) – anonymous player identifier from PlayerIdentityManager.
- `player_name` (String) – display name provided by the client (optional, may be empty).
- `created_at` (String) – ISO 8601 timestamp of submission.
- `ttl` (Number, optional) – Unix epoch seconds for time-to-live (if expiry is desired).

Optional GSI (if per-player queries are needed):

- Index name: `GSI_Player`
- Partition key: `player_id`
- Sort key: `game_id`

---

## 4. API Design

### 4.1 Common Requirements

- All endpoints must be served over HTTPS.
- All request and response bodies must be JSON.
- All responses must include appropriate HTTP status codes:
- 200 OK for successes.
- 400 Bad Request for validation or signature errors.
- 429 Too Many Requests for throttling.
- 500 Internal Server Error only for unexpected conditions.

Each request from the client must include:

- A JSON body (for POST) or query parameters (for GET).
- An `X-Signature` header containing an HMAC-SHA256 signature over the canonical JSON body or query string using a shared secret.

The shared secret must be stored in:
- AWS Secrets Manager or
- AWS Systems Manager Parameter Store

and injected into Lambda via environment variables. It must not be hardcoded.

### 4.2 `POST /leaderboard/submit`

Request body:

```json
{
  "game_id": "MyGame",
  "player_id": "uuid-or-platform-id",
  "player_name": "PlayerName",
  "score": 12345,
  "nonce": "random-uuid",
  "timestamp": 1730000000
}
```

Behaviour:

- Verify HMAC signature using the configured secret.
- Validate fields:
- `game_id`: non-empty string.
- `player_id`: non-empty string.
- `score`: integer, 0 <= score <= MAX_SCORE (configurable upper bound).
- `player_name`: optional string, may be empty.
- `timestamp`: within an acceptable time skew window (for example ±5 minutes).
- Optionally ensure `nonce` has not been reused recently to limit replay (for example cached in DynamoDB or in-memory cache).
- Compute `score_sort = -score`.
- Insert or update the player's best score for that game:
- Look up existing best score for `(game_id, player_id)`.
- If no existing score or `score > existing_best`, write the new record.
- If `score <= existing_best`, ignore the new submission or log it as a non-improving attempt.
- Return:

```json
{
  "status": "ok",
  "accepted": true,
  "new_best": true
}
```

or

```json
{
  "status": "ok",
  "accepted": true,
  "new_best": false
}
```

On validation or signature failure:

```json
{
  "status": "error",
  "error": "invalid_signature"
}
```

or similar with a descriptive error code.

### 4.3 `GET /leaderboard/top`

Request:

- Method: GET
- Path: `/leaderboard/top`
- Query parameters:
- `game_id` (required)
- `limit` (optional, default 10, max 100)

The client may also include an HMAC signature in the `X-Signature` header over the canonicalised query string if desired for consistency.

Behaviour:

- Validate `game_id` and `limit`.
- Perform a DynamoDB query:
- Partition key: `game_id`.
- Sort by `score_sort` ascending (smallest negative = highest score).
- Limit results to `limit`.
- Construct response:

```json
{
  "game_id": "MyGame",
  "entries": [
    {
      "player_name": "PlayerName",
      "score": 12345,
      "rank": 1
    },
    {
      "player_name": "OtherPlayer",
      "score": 11111,
      "rank": 2
    }
  ]
}
```

Ranks are computed on the fly based on the query result ordering.


### 4.4 `GET /leaderboard/player`

Request:

- Method: GET
- Path: `/leaderboard/player`
- Query parameters:
- `game_id` (required)
- `player_id` (required)

The client may include an HMAC signature in the `X-Signature` header over the canonicalised query string if request signing is enabled.

Behaviour:

- Validate `game_id` and `player_id`.
- Look up the best score for the specified `(game_id, player_id)` using the chosen access pattern (for example a GSI on `player_id`, or a separate per-player summary item).
- If the player has no recorded score, return a response indicating `has_score = false`.
- If the player has a recorded score, compute the player's rank within the game:
  - Rank is defined as `1 +` the count of distinct player records for the same `game_id` with a strictly higher `score`.
  - The implementation may use an efficient approximation or precomputed aggregates, but rank semantics must be consistent: lower rank value means a better position.
- Optionally include `total_players` (the count of distinct players with a recorded score for that game).

Example responses:

Player with a score:

```json
{
  "game_id": "MyGame",
  "player_id": "uuid-or-platform-id",
  "has_score": true,
  "score": 12345,
  "rank": 42,
  "total_players": 1000
}
```

Player with no recorded score:

```json
{
  "game_id": "MyGame",
  "player_id": "uuid-or-platform-id",
  "has_score": false
}
```

### 4.5 `GET /leaderboard/top-with-player`

Request:

- Method: GET
- Path: `/leaderboard/top-with-player`
- Query parameters:
- `game_id` (required)
- `player_id` (required)
- `limit` (optional, default 10, max 100)

Behaviour:

- Validate `game_id`, `player_id`, and `limit`.
- Retrieve the top `limit` scores as described for `GET /leaderboard/top`.
- Retrieve the requesting player's best score and rank as described for `GET /leaderboard/player`.
- Construct a response that always includes:
  - The top `limit` entries for the game.
  - The player's own best score and rank (if any), even if the player is not in the top `limit`.

If the player is already in the top `limit`, the implementation may either:

- Reuse the existing entry from the `entries` list and flag it, or
- Return both the `entries` list and a separate `player` object that matches one of the entries.

Example response (player not in top N):

```json
{
  "game_id": "MyGame",
  "entries": [
    {
      "player_name": "TopPlayer",
      "score": 20000,
      "rank": 1
    },
    {
      "player_name": "OtherPlayer",
      "score": 19000,
      "rank": 2
    }
  ],
  "player": {
    "player_id": "uuid-or-platform-id",
    "player_name": "CurrentPlayer",
    "score": 8000,
    "rank": 137,
    "has_score": true,
    "included_in_top": false
  }
}
```

If the player has no recorded score, the `player` object must indicate `has_score = false`:

```json
{
  "game_id": "MyGame",
  "entries": [
    {
      "player_name": "TopPlayer",
      "score": 20000,
      "rank": 1
    }
  ],
  "player": {
    "player_id": "uuid-or-platform-id",
    "has_score": false,
    "included_in_top": false
  }
}
```


---

## 5. Security and Abuse Mitigation

- Use HMAC-SHA256 with a shared secret to deter trivial scripted abuse.
- Validate all request fields and enforce sensible score bounds.
- Use API Gateway throttling and optional AWS WAF rules to:
- Limit requests per IP or per API key.
- Block obvious abusive patterns.
- Do not store or expose secrets in source code or SAM templates.
- The system assumes an “honest-but-curious” threat model:
- It does not fully prevent cheating by a determined attacker with access to the client.
- It does aim to prevent unauthenticated third-party abuse and obviously invalid submissions.

---

## 6. AWS Implementation Details

### 6.1 Runtimes and Language

- All Lambda functions must use runtime `nodejs24.x`.
- Language: Node.js with modern `async/await`.
- Use a simple project layout:

- `aws/leaderboard/template.yaml` – AWS SAM template.
- `aws/leaderboard/src/submitScore.ts` – Lambda for `POST /leaderboard/submit`.
- `aws/leaderboard/src/getTopScores.ts` – Lambda for `GET /leaderboard/top`.
- `aws/leaderboard/src/lib/` – shared helpers (for example HMAC verification, validation, DynamoDB access).
- `aws/leaderboard/tests/` – Jest test suites.
- `aws/leaderboard/package.json` – dependencies and scripts.
- `aws/leaderboard/README.md` – documentation.

TypeScript should be compiled to JavaScript for deployment as part of the build pipeline, or the code may be authored directly in JavaScript if the task specifies that.

### 6.2 Infrastructure as Code (AWS SAM)

The SAM template must define:

- An HTTP API with routes:
- `POST /leaderboard/submit` → SubmitScoreFunction
- `GET /leaderboard/top` → GetTopScoresFunction
- Two Lambda functions:
- `SubmitScoreFunction` using `nodejs24.x`.
- `GetTopScoresFunction` using `nodejs24.x`.
- A DynamoDB table `LeaderboardScores` with:
- `game_id` (partition key, String).
- `score_sort` (sort key, Number).
- Optional GSI for `player_id` if required.
- IAM policies granting Lambdas least-privilege access to the DynamoDB table.
- Parameters or environment variables for:
- Table name.
- HMAC secret parameter path.
- Maximum allowed score.
- Optional TTL configuration.

---

## 7. Build and Deployment Pipeline

The leaderboard service must include a build pipeline configuration (for example GitHub Actions or CodeBuild) that:

- Checks out the repository.
- Installs Node.js dependencies (using `npm`, `yarn`, or `pnpm`).
- Runs unit tests (for example `npm test` using Jest).
- Builds TypeScript to JavaScript (if TypeScript is used).
- Runs `sam build` to package the application.
- Runs `sam deploy` (or equivalent) to deploy to the target AWS account/stage.

The pipeline should be configurable for at least:

- `dev`
- `stage`
- `prod`

environments, with separate stacks or stack parameters.

---

## 8. Logging, Monitoring, and Observability

- Lambda functions must log:
- Validation errors.
- Signature failures.
- Unexpected internal errors.
- Use CloudWatch Logs for function logs.
- Metrics:
- Count of successful submissions.
- Count of rejected submissions (by type).
- Count of GET /top queries.
- Alarms (optional but recommended):
- High error rates on submit or top endpoints.
- Unusual spikes in traffic or rejected submissions.

---

## 9. Client Integration Contract

The Godot-side LeaderboardManager.gd must:

- Use the URLs, request shapes, and response shapes defined in this spec.
- Send `player_id` from PlayerIdentityManager and a game-specific `game_id`.
- Optionally send `player_name` if available.
- Handle error responses gracefully and not crash the game.
- Treat the leaderboard as optional:
- If disabled in ConfigManager or if the backend is unreachable, the game must still be fully playable.

Any future changes to this spec must maintain backward compatibility at the API boundary, or must be versioned appropriately (for example `/v2/leaderboard/...` endpoints).
