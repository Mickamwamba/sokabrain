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
      className={`group relative flex flex-col justify-between rounded-2xl border p-4 transition-all duration-200 overflow-hidden ${
        isActive
          ? "border-brand bg-brand/5 ring-2 ring-brand/20 shadow-xs"
          : "border-line bg-paper hover:border-ink/40 hover:bg-wash/60 shadow-2xs hover:shadow-xs"
      }`}
    >
      {/* Top accent glow */}
      <div
        className={`absolute top-0 left-0 right-0 h-1 bg-gradient-to-r ${space.badgeColor} opacity-70 group-hover:opacity-100 transition-opacity`}
      />

      <div className="space-y-2">
        <div className="flex items-center justify-between gap-2">
          <div className="flex items-center gap-2.5">
            <span className="text-2xl select-none group-hover:scale-110 transition-transform">
              {space.icon}
            </span>
            <h3 className="font-black text-sm text-ink group-hover:text-brand transition-colors">
              {name}
            </h3>
          </div>
          <span className="rounded-full bg-wash px-2.5 py-0.5 text-[11px] font-bold text-muted border border-line/60">
            {space.threadsCount} {t.kijiweni.threadsCount}
          </span>
        </div>
        <p className="text-xs text-muted leading-relaxed line-clamp-2">{desc}</p>
      </div>

      <div className="mt-3 flex items-center justify-between text-[11px] font-bold text-muted border-t border-line/50 pt-2.5">
        <span className="group-hover:text-ink transition-colors">Ingia Kijiweni →</span>
        <span className="h-1.5 w-1.5 rounded-full bg-emerald-500" />
      </div>
    </Link>
  );
}
