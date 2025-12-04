# Leaderboard Service

Backend for OneDayGames leaderboards implemented with AWS SAM, Node.js 24.x, DynamoDB, and HMAC request signing.

## API
- `POST /leaderboard/submit` – submit a score.
- `GET /leaderboard/top` – fetch top scores (query: `game_id`, `limit`).
- `GET /leaderboard/player` – fetch best score for a player (query: `game_id`, `player_id`).
- `GET /leaderboard/top-with-player` – fetch top list plus requesting player (query: `game_id`, `player_id`, `limit`).
- Header `X-Signature` = `hex(hmac_sha256(secret, canonical_payload))`; payload = canonical JSON (POST) or sorted query string (GET).

## Prerequisites
- Node.js 20+ for tooling.
- AWS SAM CLI.
- SSM Parameter with the HMAC secret (pass name via `HMAC_SECRET_PARAM`).

## Install
```bash
cd aws/leaderboard
npm ci
```

## Test
```bash
npm test
```

## Build
```bash
npm run build
sam build
```

## Deploy (manual)
```bash
sam deploy --stack-name leaderboard-service --guided \
  --parameter-overrides \
    LeaderboardTableName=LeaderboardScores \
    MaxScore=100000000 \
    TimestampSkewSecs=300 \
    HmacSecretParam=/leaderboard/hmac \
    EnableTTL=false \
    ReplayTtlSecs=0
```

## Pipeline (AWS-native)
- IaC: `aws/leaderboard/pipeline.yaml` provisions CodePipeline + CodeBuild using this repo as source.
- Parameters:
  - `SourceConnectionArn`: CodeStar Connection ARN to the repo.
  - `SourceRepositoryId`: `owner/repo` (GitHub) or CodeCommit ARN.
  - `SourceBranch`: branch to deploy from.
  - `ArtifactBucketName`: S3 bucket for artifacts.
  - `DeployStackName`: target stack name (default `leaderboard-service`).
  - `SamConfigEnv`: SAM config environment (dev/stage/prod).
- Deploy the pipeline once; subsequent changes are made by updating the same IaC (deltas only). Pipeline triggers on commits to the configured branch, builds with `npm ci` -> `npm test` -> `npm run build` -> `sam build` -> `sam deploy`.

## Environment variables
- `TABLE_NAME`, `MAX_SCORE`, `TIMESTAMP_SKEW_SECS`, `HMAC_SECRET_PARAM`, `ENABLE_TTL`, `REPLAY_TTL_SECS` are injected via SAM template parameters.

## Local invoke
```bash
sam local invoke SubmitScoreFunction --event events/submit.json
```
