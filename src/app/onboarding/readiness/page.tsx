'use client';
import { useRouter } from 'next/navigation';
import { useSessionStore } from '@/store/sessionStore';
import { computeScore, levelFromScore } from '@/lib/scoring';

const Q1 = ['Never','Once','Monthly','Weekly','Daily'] as const;
const Q1V = { Never:0, Once:1, Monthly:2, Weekly:3, Daily:4 } as const;

const Q2 = ['Not comfortable','Somewhat','Confident'] as const;
const Q2V = { 'Not comfortable':0, 'Somewhat':2, 'Confident':4 } as const;

const Q3 = ['No','A little','Yes, regularly'] as const;
const Q3V = { 'No':0, 'A little':2, 'Yes, regularly':4 } as const;

const Q4 = ['Hand-holding','Balanced','Just the steps'] as const;

export default function ReadinessPage() {
  const router = useRouter();
  const assessment = useSessionStore(s => s.assessment);
  const setAssessment = useSessionStore(s => s.setAssessment);
  const setReadiness = useSessionStore(s => s.setReadiness);
  const profile = useSessionStore(s => s.profile);

  const hasExisting = profile.score != null && profile.level != null;

  const ready = assessment.usedAiTools != null && assessment.comfortEditing != null && assessment.automateToday != null;

  function onContinue() {
    if (ready) {
      const score = computeScore(
        assessment.usedAiTools!, assessment.comfortEditing!, assessment.automateToday!
      );
      const level = levelFromScore(score);
      setReadiness(score, level, assessment.guidanceStyle);
    } else if (hasExisting) {
      // User came back just to tweak guidance; keep prior score/level
      setReadiness(profile.score!, profile.level!, assessment.guidanceStyle);
    } else {
      return; // still nothing to proceed with
    }
    router.push('/onboarding/proposal');
  }

  return (
    <main className="mx-auto max-w-3xl p-6">
      <h1 className="text-2xl font-semibold">Quick AI readiness check</h1>
      <p className="text-sm text-gray-600 mb-6">≤20s</p>

      <fieldset role="radiogroup" aria-label="Used AI tools?" className="mb-5">
        <legend className="font-medium mb-2">Used AI tools?</legend>
        {Q1.map(label => (
          <label key={label} className="mr-4">
            <input
              type="radio" name="q1"
              checked={assessment.usedAiTools === Q1V[label]}
              onChange={() => setAssessment({ usedAiTools: Q1V[label] })}
            /> {label}
          </label>
        ))}
      </fieldset>

      <fieldset role="radiogroup" aria-label="Comfort editing AI output?" className="mb-5">
        <legend className="font-medium mb-2">Comfort editing AI output?</legend>
        {Q2.map(label => (
          <label key={label} className="mr-4">
            <input
              type="radio" name="q2"
              checked={assessment.comfortEditing === Q2V[label]}
              onChange={() => setAssessment({ comfortEditing: Q2V[label] })}
            /> {label}
          </label>
        ))}
      </fieldset>

      <fieldset role="radiogroup" aria-label="Do you automate anything today?" className="mb-5">
        <legend className="font-medium mb-2">Do you automate anything today?</legend>
        {Q3.map(label => (
          <label key={label} className="mr-4">
            <input
              type="radio" name="q3"
              checked={assessment.automateToday === Q3V[label]}
              onChange={() => setAssessment({ automateToday: Q3V[label] })}
            /> {label}
          </label>
        ))}
      </fieldset>

      <fieldset role="radiogroup" aria-label="Guidance style (not scored):" className="mb-8">
        <legend className="font-medium mb-2">Guidance style (not scored):</legend>
        {Q4.map(label => (
          <label key={label} className="mr-4">
            <input
              type="radio" name="q4"
              checked={assessment.guidanceStyle === label}
              onChange={() => setAssessment({ guidanceStyle: label })}
            /> {label}
          </label>
        ))}
      </fieldset>

      <button
        type="button"
        disabled={!(ready || hasExisting)}
        className={`px-4 py-2 rounded ${
          (ready || hasExisting) ? 'bg-black text-white' : 'bg-gray-300 text-gray-600 cursor-not-allowed'
        }`}
        onClick={onContinue}
      >
        Continue
      </button>
    </main>
  );
}


