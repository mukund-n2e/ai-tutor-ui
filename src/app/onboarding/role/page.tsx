'use client';
import { useRouter } from 'next/navigation';
import { useSessionStore } from '@/store/sessionStore';

const ROLES = [
  'Creator','Consultant/Coach','Tradie','Doctor/Clinician','Accountant/Bookkeeper',
  'Teacher','Senior/New-to-tech','Student/Grad','SMB Owner','Other'
] as const;

export default function RolePage() {
  const router = useRouter();
  const role = useSessionStore(s => s.profile.role);
  const selectRole = useSessionStore(s => s.selectRole);

  return (
    <main className="mx-auto max-w-3xl p-6">
      <h1 className="text-2xl font-semibold mb-2">Who are you today?</h1>
      <p className="text-sm text-gray-600 mb-6">🎤 You can speak your choice</p>

      <div className="grid grid-cols-2 md:grid-cols-3 gap-2 mb-8">
        {ROLES.map(r => (
          <button
            key={r}
            data-testid={`role-chip-${r}`}
            className={`px-3 py-2 rounded border ${role===r ? 'bg-black text-white' : 'bg-white text-black'}`}
            onClick={() => selectRole(r as any)}
          >
            {r}
          </button>
        ))}
      </div>

      <button
        type="button"
        disabled={!role}
        className={`px-4 py-2 rounded ${role ? 'bg-black text-white' : 'bg-gray-300 text-gray-600 cursor-not-allowed'}`}
        onClick={() => router.push('/onboarding/readiness')}
      >
        Continue
      </button>
    </main>
  );
}


