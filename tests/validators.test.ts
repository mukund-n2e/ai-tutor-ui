import { ytChecks, proposalChecks, resolveWeek } from '@/lib/validators';
import type { YTDoc, ProposalDoc } from '@/lib/types';

test('CTA word count 2–8 passes, char length irrelevant', () => {
  const d: YTDoc = { hook:'[Pattern: Challenge] x', beats:['a b','c d','e f','g h','i j'], shots:[{framing:'x',durationSeconds:10},{framing:'y',durationSeconds:10},{framing:'z',durationSeconds:10}], cta:'Join now' };
  const res = ytChecks(d); const cta = res.find(x=>x.id==='cta_words'); expect(cta?.pass).toBe(true);
});

test('duration total ≤60 enforced', () => {
  const d: YTDoc = { hook:'[Pattern: Myth] x', beats:['a','b','c','d','e'], shots:[{framing:'x',durationSeconds:30},{framing:'y',durationSeconds:31}], cta:'Try this' };
  const res = ytChecks(d); const tot = res.find(x=>x.id==='duration_total'); expect(tot?.pass).toBe(false);
});

test('Week N resolves to a future Monday', () => {
  const now = new Date('2025-09-10T00:00:00Z');
  const dt = resolveWeek('Week 2', now); expect(dt).not.toBeNull(); expect(dt!.getUTCDay()).toBe(1);
});

test('proposal timeline must be future‑dated', () => {
  const now = new Date('2025-09-10T00:00:00Z');
  const d: ProposalDoc = { kpi:'Increase X by 10% by Dec', options:[{id:'A',scope:'Do x',tradeoff:'cost'},{id:'B',scope:'Do y',tradeoff:'risk'}], scope:['Create plan','Draft brief','Build asset'], timeline:{ start:'2025-09-01', end:'2025-09-05' }, investment:'USD $3000', nextStep:'Book call' };
  const res = proposalChecks(d, now); const t = res.find(x=>x.id==='timeline_present'); expect(t?.pass).toBe(false);
});

test('price validity checks currency + magnitude', () => {
  const now = new Date('2025-09-10T00:00:00Z');
  const d: ProposalDoc = { kpi:'One KPI', options:[{id:'A',scope:'Do x',tradeoff:'cost'},{id:'B',scope:'Do y',tradeoff:'risk'}], scope:['Create','Build','Ship'], timeline:{ start:'Week 1', end:'Week 2' }, investment:'USD $3k–$5k', nextStep:'Sign' };
  const res = proposalChecks(d, now); const p = res.find(x=>x.id==='price_valid'); expect(p?.pass).toBe(true);
});


