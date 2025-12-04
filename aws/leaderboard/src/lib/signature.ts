import { createHmac } from 'crypto';

export const verifySignature = (secret: string, payload: string, provided?: string | null): boolean => {
  if (!secret || !provided) {
    return false;
  }
  const normalized = provided.trim().toLowerCase();
  const expected = createHmac('sha256', secret).update(payload, 'utf8').digest('hex').toLowerCase();
  return expected === normalized;
};

export const signPayload = (secret: string, payload: string): string => {
  return createHmac('sha256', secret).update(payload, 'utf8').digest('hex');
};
