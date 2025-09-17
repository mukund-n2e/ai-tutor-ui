'use client';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  console.error(error);
  return (
    <main className="page">
      <h1>Something went wrong</h1>
      <p className="lead">Try again, or head back home.</p>
      <button onClick={() => reset()}>Try again</button>
    </main>
  );
}
