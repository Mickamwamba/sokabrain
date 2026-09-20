import { notFound } from "next/navigation";
import { fetchKijiweniSpaces, fetchKijiweniThreads } from "@/lib/kijiweni-api";
import { KijiweniHub } from "@/components/kijiweni/kijiweni-hub";

export const dynamic = "force-dynamic";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const spaces = await fetchKijiweniSpaces();
  const space = spaces.find((s) => s.slug === slug);
  if (!space) return { title: "Kijiweni — Sokabrain" };
  return {
    title: `${space.nameSw} / ${space.nameEn} — Kijiweni Sokabrain`,
    description: space.descriptionSw,
  };
}

export default async function KijiweSpacePage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const spaces = await fetchKijiweniSpaces();
  const space = spaces.find((s) => s.slug === slug);

  if (!space) {
    notFound();
  }

  const threads = await fetchKijiweniThreads({ spaceSlug: slug, sort: "latest" });

  return (
    <KijiweniHub
      spaces={spaces}
      initialThreads={threads}
      activeSpaceSlug={slug}
    />
  );
}
