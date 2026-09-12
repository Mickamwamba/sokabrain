import type { Metadata } from "next";
import { Archivo, Inter } from "next/font/google";
import "./globals.css";

// Archivo carries the bold display weights the stat figures need; Inter keeps
// dense tables readable at small sizes.
const archivo = Archivo({
  variable: "--font-archivo",
  subsets: ["latin"],
  weight: ["600", "700", "800"],
});
const inter = Inter({ variable: "--font-inter", subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Sokabrain — East African Football Stats",
  description:
    "Records, tables and stats for Tanzanian and Kenyan football — the depth global apps reserve for Europe.",
};

/**
 * Document shell only: fonts, metadata, <html> and <body>.
 *
 * The public site's header and footer are in app/(site)/layout.tsx and the
 * admin's sidebar shell in app/admin/layout.tsx, so each gets the frame it
 * needs without one wrapping the other.
 */
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${archivo.variable} ${inter.variable} h-full`}>
      <body className="min-h-full font-sans antialiased">{children}</body>
    </html>
  );
}
