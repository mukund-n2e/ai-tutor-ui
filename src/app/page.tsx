import { TutorPanel } from "@/components/TutorPanel";

export default function Home() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center p-8 gap-6">
      <h1 className="text-3xl font-bold">AI Tutor MVP</h1>
      <TutorPanel scope="probe" courseTitle="Probe" />
    </div>
  );
}
