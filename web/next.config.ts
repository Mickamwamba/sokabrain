import type { NextConfig } from "next";

const API_URL = process.env.API_URL ?? "http://localhost:4010";

const nextConfig: NextConfig = {
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
