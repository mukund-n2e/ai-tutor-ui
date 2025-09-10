import { YTDoc, ProposalDoc } from './types';
import { words } from './strings';

const IMPERATIVE_HINTS = /^(add|book|claim|click|download|join|learn|see|start|try|watch|visit|get|schedule|apply)\b/i;

export const ytChecks = (d: YTDoc) => {
  const hook_pattern_tag = /\[Pattern:\s*[^\]]+\]/.test(d.hook);
  const beats_count = d.beats.length >= 5 && d.beats.length <= 7 && d.beats.every(b => words(b).length <= 12);
  const cta_words = (() => { const w = words(d.cta); return w.length >= 2 && w.length <= 8; })();
  const ctaLooksImperative = IMPERATIVE_HINTS.test(d.cta.trim());
  const duration_sum = d.shots.reduce((s, x) => s + (x.durationSeconds||0), 0);
  const duration_total = duration_sum <= 60;
  const long_shot_soft = d.shots.some(x => (x.durationSeconds||0) > 12);
  const payoff_present = d.beats.some(b => /(so you can|you'll get|payoff:)/i.test(b));

  return [
    { id:'hook_pattern_tag', label:'Hook has pattern tag', pass: hook_pattern_tag },
    { id:'beats_count', label:'5–7 beats, ≤12 words each', pass: beats_count },
    { id:'cta_words', label:'CTA is 2–8 words (verb + object)', pass: cta_words, notes: ctaLooksImperative ? 'looks imperative' : undefined },
    { id:'duration_total', label:'Total duration ≤ 60s', pass: duration_total, notes: `${duration_sum}s` },
    { id:'payoff_present', label:'One beat names the payoff', pass: payoff_present },
    { id:'shot_too_long_soft', label:'No single shot > 12s (soft)', pass: !long_shot_soft }
  ];
};

export function resolveWeek(label: string, anchor = new Date()): Date | null {
  const m = /week\s*(\d+)/i.exec(label);
  if (!m) return null;
  const n = Math.max(1, parseInt(m[1], 10));
  const d = new Date(anchor);
  const day = d.getUTCDay();
  const deltaToMon = (8 - (day || 7)) % 7;
  d.setUTCDate(d.getUTCDate() + deltaToMon + (n - 1) * 7);
  d.setUTCHours(0,0,0,0);
  return d;
}

export function coerceDate(x?: string, anchor?: Date) {
  if (!x) return null;
  const wk = resolveWeek(x, anchor);
  if (wk) return wk;
  const dt = new Date(x);
  return isFinite(+dt) ? dt : null;
}

export const proposalChecks = (d: ProposalDoc, now = new Date()) => {
  const kpi_present = !!d.kpi && !/\n|\r/.test(d.kpi);
  const options_mece = d.options.length >= 2 && d.options.length <= 3 && d.options.every(o => /^[ABC]$/.test(o.id) && /\w/.test(o.tradeoff));
  const scope_verbs = d.scope.length >= 3 && d.scope.length <= 5 && d.scope.every(s => /^[A-Za-z]+/.test(s));
  const dates = [d.timeline?.start, d.timeline?.milestone, d.timeline?.end].map(x => coerceDate(x || '', now)).filter(Boolean) as Date[];
  const timeline_present = dates.length >= 2 && dates.every(dt => dt >= now);
  const hasCurrency = /(\$|USD|£|€)/.test(d.investment);
  const hasMagnitude = /\b\d{2,6}\b/.test(d.investment) || /\b\d+(?:\.\d+)?\s*[kKmM]\b/.test(d.investment);
  const price_valid = hasCurrency && hasMagnitude;

  return [
    { id:'kpi_present', label:'Exactly one KPI line', pass: kpi_present },
    { id:'options_mece', label:'2–3 options A/B/C with trade‑offs', pass: options_mece },
    { id:'scope_verbs', label:'3–5 deliverables start with verbs', pass: scope_verbs },
    { id:'timeline_present', label:'Start/finish + milestone in future', pass: timeline_present },
    { id:'price_valid', label:'Price has currency + magnitude', pass: price_valid }
  ];
};

export const ytFix = {
  tightenBeat: (d: YTDoc, i:number) => ({ ...d, beats: d.beats.map((b,idx)=> idx===i ? words(b).slice(0,12).join(' ') : b) }),
  addPatternTag: (d: YTDoc, tag='[Pattern: Challenge]') => ({ ...d, hook: /\[Pattern:/.test(d.hook) ? d.hook : `${tag} ${d.hook}` })
};

export const proposalFix = {
  addKPI: (d: ProposalDoc, kpi: string) => ({ ...d, kpi }),
  verbifyScope: (d: ProposalDoc) => ({ ...d, scope: d.scope.map(s => /^(Design|Build|Create|Draft|Audit|Implement|Review|Ship)/.test(s) ? s : `Create ${s}`) }),
  addPrice: (d: ProposalDoc, price='USD $3k–$5k') => ({ ...d, investment: price })
};


