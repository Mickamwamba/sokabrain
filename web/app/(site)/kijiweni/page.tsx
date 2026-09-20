import { fetchKijiweniSpaces, fetchKijiweniThreads } from "@/lib/kijiweni-api";
import { KijiweniHub } from "@/components/kijiweni/kijiweni-hub";

export const dynamic = "force-dynamic";

export const metadata = {
  title: "Kijiweni (Fan Zone) — Sokabrain",
  description: "Kona ya mashabiki wa soka la Afrika Mashariki. Bisha, cheka, tambiana na chambua mbinu za soka.",
};

export default async function KijiweniPage() {
  const [spaces, threads] = await Promise.all([
    fetchKijiweniSpaces(),
    fetchKijiweniThreads({ sort: "latest" }),
  ]);

  return <KijiweniHub spaces={spaces} initialThreads={threads} />;
}
