// web/src/app/layout.tsx
import type { ReactNode } from "react";
import "../styles/ai-tutor.css";
import HeaderBar from "../components/HeaderBar";

export const metadata = {
  title: "AI Tutor",
  description: "Learn faster with a focused AI tutor.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body className="ai-body">
        <HeaderBar />
        <main className="container">{children}</main>
      </body>
    </html>
  );
}
