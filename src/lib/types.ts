export type YTDoc = {
  title?: string;
  hook: string;
  beats: string[];
  shots: { framing: string; durationSeconds: number; overlay?: string }[];
  cta: string;
};

export type ProposalDoc = {
  client?: string;
  kpi: string;
  options: { id: 'A'|'B'|'C'; scope: string; tradeoff: string }[];
  scope: string[];
  timeline: { start: string; milestone?: string; end: string; dates?: string[] };
  investment: string;
  nextStep: string;
};


