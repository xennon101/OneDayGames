export interface EnvConfig {
  tableName: string;
  maxScore: number;
  timestampSkewSecs: number;
  enableTtl: boolean;
  replayTtlSecs: number;
  hmacSecretParam: string;
}

export const getEnvConfig = (): EnvConfig => {
  const tableName = process.env.TABLE_NAME;
  if (!tableName) {
    throw new Error('TABLE_NAME not set');
  }
  const hmacSecretParam = process.env.HMAC_SECRET_PARAM;
  if (!hmacSecretParam) {
    throw new Error('HMAC_SECRET_PARAM not set');
  }
  return {
    tableName,
    hmacSecretParam,
    maxScore: parseInt(process.env.MAX_SCORE || '100000000', 10),
    timestampSkewSecs: parseInt(process.env.TIMESTAMP_SKEW_SECS || '300', 10),
    enableTtl: (process.env.ENABLE_TTL || 'false').toLowerCase() === 'true',
    replayTtlSecs: parseInt(process.env.REPLAY_TTL_SECS || '0', 10)
  };
};
