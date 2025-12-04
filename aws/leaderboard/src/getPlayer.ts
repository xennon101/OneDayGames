import { APIGatewayProxyEventV2, APIGatewayProxyResultV2 } from 'aws-lambda';
import { canonicalizeQuery } from './lib/canonical';
import { getEnvConfig } from './lib/env';
import { jsonResponse, errorResponse } from './lib/responses';
import { getSecret } from './lib/secret';
import { verifySignature } from './lib/signature';
import { countHigherScores, countPlayers, getPlayerBest } from './lib/dynamo';
import { validatePlayerQuery } from './lib/validation';

export const handler = async (event: APIGatewayProxyEventV2): Promise<APIGatewayProxyResultV2> => {
  const env = getEnvConfig();
  const params = event.queryStringParameters || {};
  const validation = validatePlayerQuery(params);
  if (!validation.ok) {
    return errorResponse(400, 'validation_error', { reasons: validation.errors });
  }

  const canonicalQuery = canonicalizeQuery({
    game_id: params.game_id,
    player_id: params.player_id
  });
  const signature = event.headers?.['x-signature'] ?? event.headers?.['X-Signature'];
  const secret = await getSecret(env.hmacSecretParam);
  if (!verifySignature(secret, canonicalQuery, signature)) {
    return errorResponse(400, 'invalid_signature');
  }

  const best = await getPlayerBest(env.tableName, params.game_id as string, params.player_id as string);
  if (!best) {
    return jsonResponse(200, {
      game_id: params.game_id,
      player_id: params.player_id,
      has_score: false
    });
  }

  const higher = await countHigherScores(env.tableName, params.game_id as string, best.score_sort);
  const totalPlayers = await countPlayers(env.tableName, params.game_id as string);
  const rank = higher + 1;

  return jsonResponse(200, {
    game_id: params.game_id,
    player_id: params.player_id,
    has_score: true,
    score: best.score,
    rank,
    total_players: totalPlayers
  });
};
