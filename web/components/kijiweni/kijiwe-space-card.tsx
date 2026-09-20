"use client";

import Link from "next/link";
import { useLanguage } from "@/lib/i18n";

export interface KijiweSpace {
  id: number;
  slug: string;
  nameSw: string;
  nameEn: string;
  descriptionSw: string;
  descriptionEn: string;
  icon: string;
  badgeColor: string;
  threadsCount: number;
}

export function KijiweSpaceCard({
  space,
  isActive = false,
}: {
  space: KijiweSpace;
  isActive?: boolean;
}) {
  const { lang, t } = useLanguage();
  const name = lang === "sw" ? space.nameSw : space.nameEn;
  const desc = lang === "sw" ? space.descriptionSw : space.descriptionEn;

  return (
    <Link
      href={`/kijiweni/${space.slug}`}
      className={`group flex flex-col justify-between rounded-xl border p-4 transition-colors ${
        isActive
          ? "border-brand bg-brand/5 ring-1 ring-brand/30"
          : "border-line bg-paper hover:border-ink/30 hover:bg-wash/30"
      }`}
    >
      <div className="space-y-1.5">
        <div className="flex items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            <span className="text-xl select-none">{space.icon}</span>
            <h3 className="font-bold text-sm text-ink group-hover:text-brand transition-colors">
              {name}
            </h3>
          </div>
          <span className="rounded bg-wash px-2 py-0.5 text-[11px] font-semibold text-muted border border-line/50">
            {space.threadsCount} {t.kijiweni.threadsCount}
          </span>
        </div>
        <p className="text-xs text-muted leading-relaxed line-clamp-2">{desc}</p>
      </div>

      <div className="mt-3 flex items-center justify-between text-[11px] font-semibold text-muted border-t border-line/40 pt-2">
        <span className="group-hover:text-ink transition-colors">Fungua kijiwe →</span>
      </div>
    </Link>
  );
}
