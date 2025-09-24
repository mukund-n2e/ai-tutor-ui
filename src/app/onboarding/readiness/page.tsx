'use client';
import { useRouter } from 'next/navigation';
import { useSessionStore } from '@/store/sessionStore';
import { computeScore, levelFromScore } from '@/lib/scoring';
import { useState } from 'react';

type Opt<T extends string> = { label: T; value: number };

const Q1: Opt<'Never'|'Once'|'Monthly'|'Weekly'|'Daily'>[] = [
  {label:'Never',value:0},{label:'Once',value:1},{label:'Monthly',value:2},{label:'Weekly',value:3},{label:'Daily',value:4}
];
const Q2: Opt<'Not comfortable'|'Somewhat'|'Confident'>[] = [
  {label:'Not comfortable',value:0},{label:'Somewhat',value:2},{label:'Confident',value:4}
];
const Q3: Opt<'No'|'A little'|'Yes, regularly'>[] = [
  {label:'No',value:0},{label:'A little',value:2},{label:'Yes, regularly',value:4}
];
const Q4 = ['Hand-holding','Balanced','Just the steps'] as const;

export default function ReadinessPage() {
  const router = useRouter();
  const setReadiness = useSessionStore(s => s.setReadiness);

  const [q1, setQ1] = useState<number|undefined>();
  const [q2, setQ2] = useState<number|undefined>();
  const [q3, setQ3] = useState<number|undefined>();
  const [q4, setQ4] = useState<typeof Q4[number]|undefined>();

  const ready = q1!=null && q2!=null && q3!=null;

  function onContinue() {
    if (!ready) return;
    const score = computeScore(q1!, q2!, q3!);
    const level = levelFromScore(score);
    setReadiness(score, level, q4);
    router.push('/onboarding/proposal');
  }

  return (
    <main className="mx-auto max-w-3xl p-6">
      <h1 className="text-2xl font-semibold">Quick AI readiness check</h1>
      <p className="text-sm text-gray-600 mb-6">≤20s</p>

      <fieldset className="mb-5">
        <legend className="font-medium mb-2">Used AI tools?</legend>
        {Q1.map(o => (
          <label key={o.label} className="mr-4">
            <input type="radio" name="q1" value={o.value} onChange={() => setQ1(o.value)} /> {o.label}
          </label>
        ))}
      </fieldset>

      <fieldset className="mb-5">
        <legend className="font-medium mb-2">Comfort editing AI output?</legend>
        {Q2.map(o => (
          <label key={o.label} className="mr-4">
            <input type="radio" name="q2" value={o.value} onChange={() => setQ2(o.value)} /> {o.label}
          </label>
        ))}
      </fieldset>

      <fieldset className="mb-5">
        <legend className="font-medium mb-2">Do you automate anything today?</legend>
        {Q3.map(o => (
          <label key={o.label} className="mr-4">
            <input type="radio" name="q3" value={o.value} onChange={() => setQ3(o.value)} /> {o.label}
          </label>
        ))}
      </fieldset>

      <fieldset className="mb-8">
        <legend className="font-medium mb-2">Guidance style (not scored):</legend>
        {Q4.map(label => (
          <label key={label} className="mr-4">
            <input type="radio" name="q4" value={label} onChange={() => setQ4(label)} /> {label}
          </label>
        ))}
      </fieldset>

      <button
        type="button"
        disabled={!ready}
        className={`px-4 py-2 rounded ${ready ? 'bg-black text-white' : 'bg-gray-300 text-gray-600 cursor-not-allowed'}`}
        onClick={onContinue}
      >
        Continue
      </button>
    </main>
  );
}


