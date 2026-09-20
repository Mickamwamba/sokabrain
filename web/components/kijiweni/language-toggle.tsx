"use client";

import { useLanguage } from "@/lib/i18n";

export function LanguageToggle({ className = "" }: { className?: string }) {
  const { lang, setLang } = useLanguage();

  return (
    <div
      className={`inline-flex items-center rounded-full border border-white/20 bg-white/10 p-0.5 text-xs font-bold shadow-2xs backdrop-blur-xs select-none ${className}`}
    >
      <button
        type="button"
        onClick={() => setLang("sw")}
        className={`rounded-full px-2.5 py-1 transition-all cursor-pointer ${
          lang === "sw"
            ? "bg-brand text-white shadow-xs font-black"
            : "text-white/70 hover:text-white"
        }`}
        title="Badili Lugha kwenda Kiswahili"
      >
        SW
      </button>
      <button
        type="button"
        onClick={() => setLang("en")}
        className={`rounded-full px-2.5 py-1 transition-all cursor-pointer ${
          lang === "en"
            ? "bg-brand text-white shadow-xs font-black"
            : "text-white/70 hover:text-white"
        }`}
        title="Switch Language to English"
      >
        EN
      </button>
    </div>
  );
}
