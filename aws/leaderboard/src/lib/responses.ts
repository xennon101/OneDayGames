import { APIGatewayProxyResultV2 } from 'aws-lambda';

const defaultHeaders = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*'
};

export const jsonResponse = (statusCode: number, body: Record<string, unknown>): APIGatewayProxyResultV2 => ({
  statusCode,
  headers: defaultHeaders,
  body: JSON.stringify(body)
});

export const errorResponse = (
  statusCode: number,
  error: string,
  details?: Record<string, unknown>
): APIGatewayProxyResultV2 =>
  jsonResponse(statusCode, {
    status: 'error',
    error,
    ...(details || {})
  });
