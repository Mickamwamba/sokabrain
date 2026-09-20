import { notFound } from "next/navigation";
import { fetchKijiweniThreadDetail } from "@/lib/kijiweni-api";
import { ThreadDetailView } from "@/components/kijiweni/thread-detail-view";

export const dynamic = "force-dynamic";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string; id: string }>;
}) {
  const { id } = await params;
  const thread = await fetchKijiweniThreadDetail(id);
  if (!thread) return { title: "Mada Kijiweni — Sokabrain" };
  return {
    title: `${thread.title} — Kijiweni Sokabrain`,
    description: thread.content.slice(0, 150),
  };
}

export default async function ThreadPage({
  params,
}: {
  params: Promise<{ slug: string; id: string }>;
}) {
  const { id } = await params;
  const thread = await fetchKijiweniThreadDetail(id);

  if (!thread) {
    notFound();
  }

  return <ThreadDetailView initialThread={thread} />;
}
