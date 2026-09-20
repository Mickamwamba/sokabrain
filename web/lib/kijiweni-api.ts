import { KijiweSpace } from "@/components/kijiweni/kijiwe-space-card";
import { ThreadItem } from "@/components/kijiweni/thread-card";
import { ThreadDetail } from "@/components/kijiweni/thread-detail-view";

const API_URL = process.env.API_URL ?? "http://localhost:4010";

export async function fetchKijiweniSpaces(): Promise<KijiweSpace[]> {
  try {
    const res = await fetch(`${API_URL}/api/kijiweni/spaces`, {
      cache: "no-store",
    });
    if (!res.ok) return [];
    const data = await res.json();
    return data.spaces || [];
  } catch (err) {
    console.error("Failed to fetch Kijiweni spaces:", err);
    return [];
  }
}

export async function fetchKijiweniThreads(params?: {
  spaceSlug?: string;
  tag?: string;
  sort?: "latest" | "popular";
}): Promise<ThreadItem[]> {
  try {
    const q = new URLSearchParams();
    if (params?.spaceSlug) q.set("spaceSlug", params.spaceSlug);
    if (params?.tag) q.set("tag", params.tag);
    if (params?.sort) q.set("sort", params.sort);

    const queryStr = q.toString() ? `?${q.toString()}` : "";
    const res = await fetch(`${API_URL}/api/kijiweni/threads${queryStr}`, {
      cache: "no-store",
    });
    if (!res.ok) return [];
    const data = await res.json();
    return data.threads || [];
  } catch (err) {
    console.error("Failed to fetch Kijiweni threads:", err);
    return [];
  }
}

export async function fetchKijiweniThreadDetail(id: string | number): Promise<ThreadDetail | null> {
  try {
    const res = await fetch(`${API_URL}/api/kijiweni/threads/${id}`, {
      cache: "no-store",
    });
    if (!res.ok) return null;
    const data = await res.json();
    return data.thread || null;
  } catch (err) {
    console.error("Failed to fetch Kijiweni thread detail:", err);
    return null;
  }
}
