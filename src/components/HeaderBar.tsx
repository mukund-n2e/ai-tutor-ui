// web/src/components/HeaderBar.tsx
import Link from "next/link";

export default function HeaderBar() {
  return (
    <header className="header">
      <div className="container header-inner">
        <Link href="/" className="logo" aria-label="Home">
          {/* Use your repo's /public/logo.svg */}
          <img src="/logo.svg" alt="Logo" height={28} />
        </Link>
        {/* Intentionally no Screens/Courses links per request */}
      </div>
    </header>
  );
}
