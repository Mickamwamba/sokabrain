import type { NextConfig } from "next";

const API_URL = process.env.API_URL ?? "http://localhost:4010";

const nextConfig: NextConfig = {
  // Next 16 treats 127.0.0.1 and localhost as different origins and blocks its
  // own dev resources across them, so a page opened on 127.0.0.1:3100 renders
  // but never hydrates — no client component runs, and the only clue is one
  // "Blocked cross-origin request" line in the dev server log. That cost real
  // time to diagnose once; listing both spellings makes either work.
  allowedDevOrigins: ["127.0.0.1", "localhost"],

  async rewrites() {
    return [
      {
        source: "/api/vault/:path*",
        destination: `${API_URL}/api/vault/:path*`,
      },
      {
        source: "/api/kijiweni/:path*",
        destination: `${API_URL}/api/kijiweni/:path*`,
      },
    ];
  },
};

export default nextConfig;
