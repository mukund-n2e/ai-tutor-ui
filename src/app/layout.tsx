// web/src/app/layout.tsx
import type { ReactNode } from "react";
import "../styles/tokens.css";
import "./globals.css";
import HeaderBar from "../components/HeaderBar";

export const metadata = {
  title: "AI Tutor",
  description: "Learn faster with a focused AI tutor.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>
        <HeaderBar />
        {children}
      </body>
    </html>
  );
}
