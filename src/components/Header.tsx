import Link from "next/link";
import Image from "next/image";
import Button from "./Button";
import '../styles/tokens.css';

export default function Header() {
  return (
    <header className="sticky top-0 z-40 w-full border-b bg-[var(--surface)] backdrop-blur-sm h-header border-default">
      <div className="mx-auto flex h-full max-w-[1200px] items-center justify-between px-4">
        <Link href="/" className="flex items-center gap-3" aria-label="AI Tutor (home)">
          <Image
            src="/assets/ai-tutor-logo.svg"
            alt="AI Tutor"
            width={32}
            height={32}
            className="h-logo"
            priority
          />
          <span className="text-lg font-semibold tracking-tight text-[var(--text-high)]">AI Tutor</span>
        </Link>
        <div className="flex items-center gap-4">
          <Link
            href="/account"
            className="text-[var(--text-mid)] hover:text-[var(--text-high)] transition-colors"
          >
            Sign in
          </Link>
          <Button variant="ghost" size="sm">
            Start free
          </Button>
        </div>
      </div>
    </header>
  );
}