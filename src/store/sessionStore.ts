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

type State = {
  profile: {
    role?: RoleId;
    score?: number;
    level?: Level;
    guidanceStyle?: 'Hand-holding' | 'Balanced' | 'Just the steps';
  };
  course?: { id: string; title: string; heroMoves: Move[] };
  session?: Session;
};
type Actions = {
  selectRole: (role: RoleId) => void;
  setReadiness: (score: number, level: Level, guidance?: State['profile']['guidanceStyle']) => void;
  setCourse: (course: State['course']) => void;
  startSession: (payload: { sessionId: string; tokenCap: number; moves: Move[] }) => void;
  completeMove: (moveId: string) => void;
  addTokens: (n: number) => void;
};

export const useSessionStore = create<State & Actions>((set, get) => ({
  profile: {},
  selectRole: (role) => set((s) => ({ profile: { ...s.profile, role } })),
  setReadiness: (score, level, guidanceStyle) =>
    set((s) => ({ profile: { ...s.profile, score, level, guidanceStyle } })),
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


