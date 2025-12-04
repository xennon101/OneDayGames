import { SSMClient, GetParameterCommand } from '@aws-sdk/client-ssm';

const ssm = new SSMClient({});
let cachedSecret: string | null = null;

export const getSecret = async (paramName: string): Promise<string> => {
  if (cachedSecret) {
    return cachedSecret;
  }
  const resp = await ssm.send(
    new GetParameterCommand({
      Name: paramName,
      WithDecryption: true
    })
  );
  const value = resp.Parameter?.Value;
  if (!value) {
    throw new Error('HMAC secret missing in parameter store');
  }
  cachedSecret = value;
  return value;
};
