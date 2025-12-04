import { APIGatewayProxyEventV2, APIGatewayProxyResultV2 } from 'aws-lambda';
import { canonicalizeJson } from './lib/canonical';
import { getEnvConfig } from './lib/env';
import { jsonResponse, errorResponse } from './lib/responses';
import { getSecret } from './lib/secret';
import { verifySignature } from './lib/signature';
import { validateSubmit } from './lib/validation';
import { deleteScoreItem, getPlayerBest, putBestScore } from './lib/dynamo';

export const handler = async (event: APIGatewayProxyEventV2): Promise<APIGatewayProxyResultV2> => {
  const env = getEnvConfig();
  if (!event.body) {
    return errorResponse(400, 'invalid_body');
  }
  let body: Record<string, unknown>;
  try {
    body = JSON.parse(event.body);
  } catch {
    return errorResponse(400, 'invalid_json');
  }

  const payload = canonicalizeJson(body);
  const signature = event.headers?.['x-signature'] ?? event.headers?.['X-Signature'];
  const secret = await getSecret(env.hmacSecretParam);
  if (!verifySignature(secret, payload, signature)) {
    return errorResponse(400, 'invalid_signature');
  }

  const validation = validateSubmit(body, env.maxScore, env.timestampSkewSecs);
  if (!validation.ok) {
    return errorResponse(400, 'validation_error', { reasons: validation.errors });
  }

  const gameId = body.game_id as string;
  const playerId = body.player_id as string;
  const playerName = (body.player_name as string) || '';
  const score = body.score as number;
  const scoreSort = -score;

  const existing = await getPlayerBest(env.tableName, gameId, playerId);
  let newBest = true;
  if (existing) {
    if (score <= existing.score) {
      newBest = false;
    } else {
      await deleteScoreItem(env.tableName, gameId, existing.score_sort);
    }
  }

  if (newBest) {
    const item = {
      game_id: gameId,
      player_id: playerId,
      player_name: playerName,
      score,
      score_sort: scoreSort,
      created_at: new Date().toISOString()
    };
    await putBestScore(env.tableName, item);
  }

  return jsonResponse(200, {
    status: 'ok',
    accepted: true,
    new_best: newBest
  });
};
