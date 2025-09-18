export type SessionCtx = {
  verb: string; persona: string; minutes: string; task: string;
  prev?: { m1?: string; m2?: string; };
};
export type Move = { key: 'm1'|'m2'|'m3'; title: string; build: (c: SessionCtx)=>string; };

export const MOVES: Move[] = [
  {
    key: 'm1',
    title: 'Understand',
    build: (c) => [
      `You are a tutor guiding a ${c.persona}.`,
      `Goal verb: ${c.verb}. Time box: ${c.minutes} minutes.`,
      `TASK: ${c.task}`,
      `Move 1 - Understand: Ask 3 crisp clarifying questions and state 3 constraints.`,
      `Keep it brief and actionable.`
    ].join('\n')
  },
  {
    key: 'm2',
    title: 'Draft',
    build: (c) => [
      `You are a tutor guiding a ${c.persona}.`,
      `Goal verb: ${c.verb}. Time box: ${c.minutes} minutes.`,
      `TASK: ${c.task}`,
      c.prev?.m1 ? `Previous Move 1 (Understanding):\n${c.prev.m1}\n` : '',
      `Move 2 - Draft: Produce a concise first draft or outline in 6-10 bullets.`,
      `Front-load the most decisive actions.`
    ].join('\n')
  },
  {
    key: 'm3',
    title: 'Polish',
    build: (c) => [
      `You are a tutor guiding a ${c.persona}.`,
      `Goal verb: ${c.verb}. Time box: ${c.minutes} minutes.`,
      `TASK: ${c.task}`,
      c.prev?.m1 ? `Move 1 (Understanding):\n${c.prev.m1}\n` : '',
      c.prev?.m2 ? `Move 2 (Draft):\n${c.prev.m2}\n` : '',
      `Move 3 - Polish: Tighten for clarity and impact. Return the final result.`,
      `Prefer concrete language over fluff.`
    ].join('\n')
  }
];
