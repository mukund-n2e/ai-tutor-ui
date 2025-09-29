import Link from "next/link";
import Image from "next/image";

const showScreens =
  process.env.NEXT_PUBLIC_UI_DEBUG === "1" && process.env.NODE_ENV !== "production";

export default function Header() {
  return (
    <header className="sticky top-0 z-40 w-full border-b bg-white/70 backdrop-blur">
      <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-4">
        <Link href="/" className="flex items-center gap-2">
          <Image
            src="/brand/logo.svg"
            alt="AI Tutor"
            width={28}
            height={28}
            priority
          />
          <span className="text-lg font-semibold tracking-tight">AI Tutor</span>
        </Link>

        {showScreens ? (
          <Link href="/screens" className="text-sm text-neutral-600 hover:text-neutral-900">
            Screens
          </Link>
        ) : null}
      </div>
    </header>
  );
}


