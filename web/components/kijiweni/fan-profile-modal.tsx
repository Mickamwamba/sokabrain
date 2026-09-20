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
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4">
      <div className="w-full max-w-md rounded-xl border border-line bg-paper p-5 sm:p-6 shadow-xl space-y-4">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-line/40 pb-3">
          <div>
            <h3 className="text-base font-bold text-ink">{t.kijiweni.fanModalTitle}</h3>
            <p className="text-xs text-muted mt-0.5">{t.kijiweni.fanModalSub}</p>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label={t.kijiweni.cancel}
            className="text-muted hover:text-ink text-xl font-bold p-1 cursor-pointer"
          >
            ×
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Nickname */}
          <div>
            <label className="block text-xs font-bold text-ink mb-1">
              {t.kijiweni.fanHandle} <span className="text-rose-500">*</span>
            </label>
            <input
              type="text"
              required
              maxLength={30}
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Mzee_Wa_Kariakoo"
              className="w-full rounded-lg border border-line bg-wash/30 px-3 py-2 text-sm font-semibold text-ink placeholder:text-muted focus:border-brand focus:bg-paper focus:outline-none transition-colors"
            />
            {error && <p className="text-xs text-rose-500 mt-1">{error}</p>}
          </div>

          {/* Club Allegiance */}
          <div>
            <label className="block text-xs font-bold text-ink mb-1">
              {t.kijiweni.chooseTeam}
            </label>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-1.5 max-h-48 overflow-y-auto p-1 border border-line/60 rounded-lg bg-wash/20 scrollbar-thin">
              {POPULAR_FAN_TEAMS.map((tName) => {
                const isSelected = team === tName;
                return (
                  <button
                    key={tName}
                    type="button"
                    onClick={() => setTeam(tName)}
                    className={`flex items-center gap-1.5 p-1.5 rounded border text-left transition-colors cursor-pointer ${
                      isSelected
                        ? "border-brand bg-brand/10 text-brand font-bold"
                        : "border-line/60 bg-paper hover:bg-wash text-ink text-xs"
                    }`}
                  >
                    <div className="shrink-0">
                      <Crest name={tName} size={18} />
                    </div>
                    <span className="text-xs truncate font-medium">{tName}</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Live Preview */}
          <div className="rounded-lg bg-wash/40 border border-line p-2.5 flex items-center justify-between">
            <span className="text-[11px] font-semibold text-muted">Muonekano wako:</span>
            <div className="flex items-center gap-2">
              <Crest name={team} size={20} />
              <span className="font-bold text-sm text-ink">{name || "Mwanakijiwe"}</span>
            </div>
          </div>

          {/* Buttons */}
          <div className="flex items-center justify-end gap-2 pt-1">
            <button
              type="button"
              onClick={onClose}
              className="px-3.5 py-1.5 text-xs font-semibold text-muted hover:text-ink transition-colors cursor-pointer"
            >
              {t.kijiweni.cancel}
            </button>
            <button
              type="submit"
              className="rounded-lg bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand/90 transition-colors cursor-pointer"
            >
              {t.kijiweni.saveProfile}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
