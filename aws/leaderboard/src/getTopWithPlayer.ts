import { APIGatewayProxyEventV2, APIGatewayProxyResultV2 } from 'aws-lambda';
import { canonicalizeQuery } from './lib/canonical';
import { getEnvConfig } from './lib/env';
import { jsonResponse, errorResponse } from './lib/responses';
import { getSecret } from './lib/secret';
import { verifySignature } from './lib/signature';
import { countHigherScores, countPlayers, getPlayerBest, queryTop } from './lib/dynamo';
import { validateTop, validatePlayerQuery } from './lib/validation';

export const handler = async (event: APIGatewayProxyEventV2): Promise<APIGatewayProxyResultV2> => {
  const env = getEnvConfig();
  const params = event.queryStringParameters || {};
  const playerValidation = validatePlayerQuery(params);
  const topValidation = validateTop(params);
  if (!playerValidation.ok || !topValidation.ok) {
    return errorResponse(400, 'validation_error', {
      reasons: [...(playerValidation.errors || []), ...(topValidation.errors || [])]
    });
  }

  const canonicalQuery = canonicalizeQuery({
    game_id: params.game_id,
    player_id: params.player_id,
    ...(params.limit ? { limit: params.limit } : {})
  });
  const signature = event.headers?.['x-signature'] ?? event.headers?.['X-Signature'];
  const secret = await getSecret(env.hmacSecretParam);
  if (!verifySignature(secret, canonicalQuery, signature)) {
    return errorResponse(400, 'invalid_signature');
  }

  const limit = topValidation.parsedLimit as number;
  const [topList, best] = await Promise.all([
    queryTop(env.tableName, params.game_id as string, limit),
    getPlayerBest(env.tableName, params.game_id as string, params.player_id as string)
  ]);

  const entries = topList.map((item, idx) => ({
    player_name: item.player_name || '',
    score: item.score,
    rank: idx + 1
  }));

  if (!best) {
    return jsonResponse(200, {
      game_id: params.game_id,
      entries,
      player: {
        player_id: params.player_id,
        has_score: false,
        included_in_top: false
      }
    });
  }

  const higher = await countHigherScores(env.tableName, params.game_id as string, best.score_sort);
  const totalPlayers = await countPlayers(env.tableName, params.game_id as string);
  const rank = higher + 1;
  const included = rank <= limit;

  return jsonResponse(200, {
    game_id: params.game_id,
    entries,
    player: {
      player_id: params.player_id,
      player_name: best.player_name || '',
      score: best.score,
      rank,
      total_players: totalPlayers,
      has_score: true,
      included_in_top: included
    }
  });
};
