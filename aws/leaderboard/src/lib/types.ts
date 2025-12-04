export interface ValidationResult {
  ok: boolean;
  errors: string[];
  parsedLimit?: number;
}

export interface LeaderboardItem {
  game_id: string;
  player_id: string;
  player_name?: string;
  score: number;
  score_sort: number;
  created_at: string;
  ttl?: number;
}

export interface PlayerBestResult {
  game_id: string;
  player_id: string;
  player_name?: string;
  score: number;
  score_sort: number;
}
