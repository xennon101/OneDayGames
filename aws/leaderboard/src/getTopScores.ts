import { APIGatewayProxyEventV2, APIGatewayProxyResultV2 } from 'aws-lambda';
import { canonicalizeQuery } from './lib/canonical';
import { getEnvConfig } from './lib/env';
import { jsonResponse, errorResponse } from './lib/responses';
import { getSecret } from './lib/secret';
import { verifySignature } from './lib/signature';
import { queryTop } from './lib/dynamo';
import { validateTop } from './lib/validation';

export const handler = async (event: APIGatewayProxyEventV2): Promise<APIGatewayProxyResultV2> => {
  const env = getEnvConfig();
  const params = event.queryStringParameters || {};
  const validation = validateTop(params);
  if (!validation.ok) {
    return errorResponse(400, 'validation_error', { reasons: validation.errors });
  }

  const canonicalQuery = canonicalizeQuery({
    game_id: params.game_id,
    ...(params.limit ? { limit: params.limit } : {})
  });
  const signature = event.headers?.['x-signature'] ?? event.headers?.['X-Signature'];
  const secret = await getSecret(env.hmacSecretParam);
  if (!verifySignature(secret, canonicalQuery, signature)) {
    return errorResponse(400, 'invalid_signature');
  }

  const items = await queryTop(env.tableName, params.game_id as string, validation.parsedLimit as number);
  const entries = items.map((item, idx) => ({
    player_name: item.player_name || '',
    score: item.score,
    rank: idx + 1
  }));

  return jsonResponse(200, {
    game_id: params.game_id,
    entries
  });
};
