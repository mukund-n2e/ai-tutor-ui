import { create } from 'zustand';
import type { Level } from '@/lib/scoring';

export type RoleId =
  | 'Creator' | 'Consultant/Coach' | 'Tradie' | 'Doctor/Clinician'
  | 'Accountant/Bookkeeper' | 'Teacher' | 'Senior/New-to-tech'
  | 'Student/Grad' | 'SMB Owner' | 'Other';

type Move = { id: string; title: string; prompt?: string };
type Session = {
  sessionId: string;
  tokenCap: number;
  tokensUsed: number;
  moves: Move[];
  completedMoveIds: Set<string>;
};

type Guidance = 'Hand-holding' | 'Balanced' | 'Just the steps';

type State = {
  profile: {
    role?: RoleId;
    score?: number;
    level?: Level;
    guidanceStyle?: Guidance;
  };
  // Keep raw answers so back-nav restores selection
  assessment: {
    usedAiTools?: number;      // q1: 0..4
    comfortEditing?: number;   // q2: 0,2,4
    automateToday?: number;    // q3: 0,2,4
    guidanceStyle?: Guidance;  // q4: string (not scored)
  };
  course?: { id: string; title: string; heroMoves: Move[] };
  session?: Session;
};
type Actions = {
  selectRole: (role: RoleId) => void;
  setAssessment: (patch: Partial<State['assessment']>) => void;
  resetAssessment: () => void;
  setReadiness: (score: number, level: Level, guidance?: Guidance) => void;
  setCourse: (course: State['course']) => void;
  startSession: (payload: { sessionId: string; tokenCap: number; moves: Move[] }) => void;
  completeMove: (moveId: string) => void;
  addTokens: (n: number) => void;
};

export const useSessionStore = create<State & Actions>((set, get) => ({
  profile: {},
  assessment: {},

  selectRole: (role) => set((s) => ({ profile: { ...s.profile, role } })),

  setAssessment: (patch) =>
    set((s) => ({ assessment: { ...s.assessment, ...patch } })),

  resetAssessment: () => set({ assessment: {} }),

  setReadiness: (score, level, guidanceStyle) =>
    set((s) => ({
      profile: { ...s.profile, score, level, guidanceStyle: guidanceStyle ?? s.profile.guidanceStyle }
    })),

  setCourse: (course) => set({ course: course ?? undefined }),
  startSession: ({ sessionId, tokenCap, moves }) =>
    set({
      session: {
        sessionId,
        tokenCap,
        tokensUsed: 0,
        moves,
        completedMoveIds: new Set<string>()
      }
    }),
  completeMove: (moveId) =>
    set((s) => {
      if (!s.session) return {} as Partial<State>;
      const done = new Set(s.session.completedMoveIds);
      done.add(moveId);
      return { session: { ...s.session, completedMoveIds: done } } as Partial<State>;
    }),
  addTokens: (n) =>
    set((s) => {
      if (!s.session) return {} as Partial<State>;
      return { session: { ...s.session, tokensUsed: s.session.tokensUsed + n } } as Partial<State>;
    })
}));


