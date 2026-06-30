// app/layout.tsx

import type { Metadata } from "next";
import { Merriweather, Lato } from "next/font/google";
import Link from "next/link";
import "./globals.css";

const merriweather = Merriweather({
  subsets: ["latin"],
  weight: ["400", "700"],
  variable: "--font-merriweather",
});

const lato = Lato({
  subsets: ["latin"],
  weight: ["400", "600", "700"],
  variable: "--font-lato",
});

export const metadata: Metadata = {
  title: "Embre Serials",
  description: "A fiction platform for readers and writers.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={`${merriweather.variable} ${lato.variable}`}>
        <header className="site-header">
          <Link href="/" className="logo">
            Embre Serials
          </Link>
          <nav>
            <Link href="/browse">Browse</Link>
            <Link href="/write">Write</Link>
          </nav>
        </header>
        {children}
      </body>
    </html>
  );
}
