import '../styles/components.css';
import '../styles/tokens.css';
import '@/styles/brand.css';
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import Header from "@/components/Header";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  display: 'swap'
});

export const metadata: Metadata = {
  title: "AI Tutor",
  description: "Learn and apply AI to your job. No fluff.",
  icons: { icon: '/brand/ai-tutor-mark.svg' }
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" data-ssr-beta="true">
      <body className={`${inter.variable} antialiased grid-container`} data-ssr-beta="true">
        <Header />
        {children}
        {/* SSR beta marker for monitors */}
        <div data-ssr-beta="true" style={{ display: 'none' }}>BETA</div>
      </body>
    </html>
  );
}
