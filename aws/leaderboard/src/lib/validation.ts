import { ValidationResult } from './types';

export const validateSubmit = (
  body: Record<string, unknown>,
  maxScore: number,
  timestampSkewSecs: number
): ValidationResult => {
  const errors: string[] = [];
  const gameId = typeof body.game_id === 'string' ? body.game_id : '';
  const playerId = typeof body.player_id === 'string' ? body.player_id : '';
  const score = Number.isInteger(body.score) ? (body.score as number) : NaN;
  const playerName = typeof body.player_name === 'string' ? body.player_name : '';
  const timestamp = Number.isInteger(body.timestamp) ? (body.timestamp as number) : NaN;

  if (!gameId) errors.push('game_id_required');
  if (!playerId) errors.push('player_id_required');
  if (!Number.isInteger(score)) errors.push('score_invalid');
  if (Number.isInteger(score) && (score as number) < 0) errors.push('score_negative');
  if (Number.isInteger(score) && (score as number) > maxScore) errors.push('score_too_high');
  if (typeof body.nonce !== 'string' || (body.nonce as string).length < 8) errors.push('nonce_required');
  if (!Number.isInteger(timestamp)) errors.push('timestamp_required');
  if (Number.isInteger(timestamp)) {
    const now = Math.floor(Date.now() / 1000);
    if (Math.abs(now - (timestamp as number)) > timestampSkewSecs) {
      errors.push('timestamp_skew');
    }
  }
  if (typeof playerName !== 'string') errors.push('player_name_invalid');

  return { ok: errors.length == 0, errors };
};

export const validateTop = (params: Record<string, string | undefined>): ValidationResult => {
  const errors: string[] = [];
  const gameId = params.game_id || '';
  const limit = params.limit ? parseInt(params.limit, 10) : 10;
  if (!gameId) errors.push('game_id_required');
  if (isNaN(limit) || limit < 1 || limit > 100) errors.push('limit_invalid');
  return { ok: errors.length == 0, errors, parsedLimit: isNaN(limit) ? 10 : Math.min(Math.max(limit, 1), 100) };
};

export const validatePlayerQuery = (params: Record<string, string | undefined>): ValidationResult => {
  const errors: string[] = [];
  if (!params.game_id) errors.push('game_id_required');
  if (!params.player_id) errors.push('player_id_required');
  return { ok: errors.length == 0, errors };
};
