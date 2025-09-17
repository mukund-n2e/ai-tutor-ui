export const dynamic = 'force-static';
export const revalidate = 3600;

export default function Smoke() {
  return (
    <main style={{maxWidth: 720, margin: '40px auto', padding: '0 16px'}}>
      <h1>Deploy OK</h1>
      <p>This is the smoke page. If you can read this in production, Git→Vercel is wired.</p>
    </main>
  );
}
