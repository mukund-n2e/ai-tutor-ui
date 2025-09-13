'use client';

export default function GlobalError({
  error,
  reset,
}: { error: Error & { digest?: string }; reset: () => void }) {
  return (
    <html>
      <body>
        <main style={{ padding: 16, fontFamily: 'system-ui' }}>
          <h1>Something went wrong</h1>
          <pre style={{ whiteSpace: 'pre-wrap' }}>{error.message}</pre>
          {error.digest && <p>Digest: {error.digest}</p>}
          <button onClick={() => reset()}>Reload</button>
        </main>
      </body>
    </html>
  );
}


