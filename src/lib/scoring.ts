export type Level = 'L1' | 'L2' | 'L3';

export function computeScore(q1: number, q2: number, q3: number): number {
  const raw = q1 + q2 + q3; // max 12
  const pct = Math.round((raw / 12) * 100);
  return Math.max(0, Math.min(100, pct));
}

export function levelFromScore(score: number): Level {
  if (score <= 39) return 'L1';
  if (score <= 69) return 'L2';
  return 'L3';
}


