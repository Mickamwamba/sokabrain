"use client";

import { useState } from "react";
import { useLanguage } from "@/lib/i18n";
import { useFanProfile, POPULAR_FAN_TEAMS } from "@/lib/fan-profile";
import { Crest } from "@/components/ui";

export function FanProfileModal({
  isOpen,
  onClose,
  onSaved,
}: {
  isOpen: boolean;
  onClose: () => void;
  onSaved?: () => void;
}) {
  const { t } = useLanguage();
  const { profile, update } = useFanProfile();
  const [name, setName] = useState(profile.name);
  const [team, setTeam] = useState(profile.team || "Simba SC");
  const [error, setError] = useState("");

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setError(t.kijiweni.fanHandle + " inahitajika!");
      return;
    }
    update({ name: name.trim(), team });
    setError("");
    onSaved?.();
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-ink/75 backdrop-blur-sm p-4 animate-in fade-in duration-200">
      <div className="w-full max-w-md rounded-2xl border border-line bg-paper p-6 shadow-2xl space-y-5">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-line/60 pb-3">
          <div className="flex items-center gap-2">
            <span className="text-2xl">⚽</span>
            <div>
              <h3 className="text-base font-black text-ink">{t.kijiweni.fanModalTitle}</h3>
              <p className="text-xs text-muted">{t.kijiweni.fanModalSub}</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="text-muted hover:text-ink text-xl font-bold p-1 cursor-pointer"
          >
            ×
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Nickname */}
          <div>
            <label className="block text-xs font-bold text-ink mb-1.5">
              {t.kijiweni.fanHandle} <span className="text-rose-500">*</span>
            </label>
            <input
              type="text"
              required
              maxLength={30}
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Mzee_Wa_Kariakoo, Fundi_Soka"
              className="w-full rounded-xl border border-line bg-wash/50 px-3.5 py-2.5 text-sm font-semibold text-ink focus:border-brand focus:bg-paper focus:outline-none transition-all"
            />
            {error && <p className="text-xs text-rose-500 mt-1">{error}</p>}
          </div>

          {/* Club Allegiance */}
          <div>
            <label className="block text-xs font-bold text-ink mb-1.5">
              {t.kijiweni.chooseTeam}
            </label>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 max-h-48 overflow-y-auto p-1 border border-line/60 rounded-xl bg-wash/30 scrollbar-thin">
              {POPULAR_FAN_TEAMS.map((tName) => {
                const isSelected = team === tName;
                return (
                  <button
                    key={tName}
                    type="button"
                    onClick={() => setTeam(tName)}
                    className={`flex items-center gap-2 p-2 rounded-lg border text-left transition-all cursor-pointer ${
                      isSelected
                        ? "border-brand bg-brand/10 text-brand font-bold shadow-2xs"
                        : "border-line/60 bg-paper hover:bg-wash text-ink text-xs"
                    }`}
                  >
                    <div className="shrink-0">
                      <Crest name={tName} size={22} />
                    </div>
                    <span className="text-xs truncate font-medium">{tName}</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Live Preview */}
          <div className="rounded-xl bg-wash/80 border border-line p-3 flex items-center justify-between">
            <span className="text-[11px] font-bold text-muted uppercase">Muonekano wako:</span>
            <div className="flex items-center gap-2">
              <Crest name={team} size={24} />
              <span className="font-black text-sm text-ink">{name || "Mwanakijiwe"}</span>
            </div>
          </div>

          {/* Buttons */}
          <div className="flex items-center justify-end gap-2.5 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-xs font-bold text-muted hover:text-ink transition-colors cursor-pointer"
            >
              {t.kijiweni.cancel}
            </button>
            <button
              type="submit"
              className="rounded-xl bg-brand px-5 py-2 text-xs font-black text-white hover:bg-brand/90 transition-all shadow-sm cursor-pointer"
            >
              {t.kijiweni.saveProfile}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
