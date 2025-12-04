import {
  DynamoDBClient,
  QueryCommand,
  QueryCommandInput,
  DeleteItemCommand,
  AttributeValue
} from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand } from '@aws-sdk/lib-dynamodb';
import { LeaderboardItem, PlayerBestResult } from './types';

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const GSI_PLAYER = 'GSI_Player';

export const putBestScore = async (tableName: string, item: LeaderboardItem): Promise<void> => {
  await docClient.send(
    new PutCommand({
      TableName: tableName,
      Item: item
    })
  );
};

export const deleteScoreItem = async (tableName: string, gameId: string, scoreSort: number): Promise<void> => {
  await docClient.send(
    new DeleteItemCommand({
      TableName: tableName,
      Key: {
        game_id: { S: gameId },
        score_sort: { N: scoreSort.toString() }
      }
    })
  );
};

export const getPlayerBest = async (
  tableName: string,
  gameId: string,
  playerId: string
): Promise<PlayerBestResult | null> => {
  const input: QueryCommandInput = {
    TableName: tableName,
    IndexName: GSI_PLAYER,
    KeyConditionExpression: 'player_id = :pid AND game_id = :gid',
    ExpressionAttributeValues: {
      ':pid': { S: playerId },
      ':gid': { S: gameId }
    },
    Limit: 5
  };
  const result = await client.send(new QueryCommand(input));
  if (!result.Items || result.Items.length === 0) {
    return null;
  }
  // Because we keep only best item per player/game, first item is best.
  const item = result.Items[0] as Record<string, AttributeValue>;
  return {
    game_id: item.game_id.S as string,
    player_id: item.player_id.S as string,
    player_name: item.player_name?.S,
    score: parseInt(item.score.N as string, 10),
    score_sort: parseInt(item.score_sort.N as string, 10)
  };
};

export const queryTop = async (
  tableName: string,
  gameId: string,
  limit: number
): Promise<PlayerBestResult[]> => {
  const input: QueryCommandInput = {
    TableName: tableName,
    KeyConditionExpression: 'game_id = :gid',
    ExpressionAttributeValues: {
      ':gid': { S: gameId }
    },
    ScanIndexForward: true,
    Limit: limit
  };
  const result = await client.send(new QueryCommand(input));
  if (!result.Items) return [];
  return result.Items.map((item) => ({
    game_id: item.game_id.S as string,
    player_id: item.player_id.S as string,
    player_name: item.player_name?.S,
    score: parseInt(item.score.N as string, 10),
    score_sort: parseInt(item.score_sort.N as string, 10)
  }));
};

export const countHigherScores = async (
  tableName: string,
  gameId: string,
  targetScoreSort: number
): Promise<number> => {
  const result = await client.send(
    new QueryCommand({
      TableName: tableName,
      KeyConditionExpression: 'game_id = :gid AND score_sort < :sort',
      ExpressionAttributeValues: {
        ':gid': { S: gameId },
        ':sort': { N: targetScoreSort.toString() }
      },
      Select: 'COUNT'
    })
  );
  return result.Count ?? 0;
};

export const countPlayers = async (tableName: string, gameId: string): Promise<number> => {
  const result = await client.send(
    new QueryCommand({
      TableName: tableName,
      KeyConditionExpression: 'game_id = :gid',
      ExpressionAttributeValues: {
        ':gid': { S: gameId }
      },
      Select: 'COUNT'
    })
  );
  return result.Count ?? 0;
};
