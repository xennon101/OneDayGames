export const canonicalizeJson = (input: unknown): string => {
  const sorted = sortValue(input);
  return JSON.stringify(sorted);
};

export const canonicalizeQuery = (params: Record<string, string | number | undefined | null>): string => {
  const entries = Object.entries(params).filter(([, v]) => v !== undefined && v !== null);
  entries.sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0));
  return entries
    .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`)
    .join('&');
};

const sortValue = (value: unknown): unknown => {
  if (Array.isArray(value)) {
    return value.map(sortValue);
  }
  if (value && typeof value === 'object') {
    const obj = value as Record<string, unknown>;
    const keys = Object.keys(obj).sort();
    const sorted: Record<string, unknown> = {};
    for (const key of keys) {
      sorted[key] = sortValue(obj[key]);
    }
    return sorted;
  }
  return value;
};
