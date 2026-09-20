"use client";

import { useSyncExternalStore, useCallback } from "react";

export interface FanProfile {
  name: string;
  team: string;
  fingerprint: string;
}

export const DEFAULT_PROFILE: FanProfile = {
  name: "",
  team: "Simba SC",
  fingerprint: "",
};

export const POPULAR_FAN_TEAMS = [
  "Simba SC",
  "Young Africans",
  "Azam FC",
  "Singida Black Stars",
  "Coastal Union",
  "Kagera Sugar",
  "Dodoma Jiji FC",
  "Pamba Jiji",
  "Namungo",
  "Tanzania",
  "Gor Mahia",
  "AFC Leopards",
  "Kenya",
  "Rayon Sports FC",
  "APR",
  "Rwanda",
  "Uganda",
];

function generateFingerprint(): string {
  return "fan_" + Math.random().toString(36).substring(2, 10) + Date.now().toString(36);
}

const listeners = new Set<() => void>();

function subscribeFanProfile(callback: () => void) {
  listeners.add(callback);
  window.addEventListener("storage", callback);
  return () => {
    listeners.delete(callback);
    window.removeEventListener("storage", callback);
  };
}

function notifyFanProfile() {
  cachedRaw = null;
  cachedProfile = null;
  listeners.forEach((l) => l());
}

let cachedRaw: string | null = null;
let cachedProfile: FanProfile | null = null;

export function getStoredFanProfile(): FanProfile {
  if (typeof window === "undefined") {
    return DEFAULT_PROFILE;
  }
  try {
    const raw = localStorage.getItem("sokabrain_fan_profile");
    if (raw === cachedRaw && cachedProfile) {
      return cachedProfile;
    }
    cachedRaw = raw;
    if (raw) {
      const parsed = JSON.parse(raw);
      if (parsed && typeof parsed.name === "string") {
        cachedProfile = {
          name: parsed.name,
          team: parsed.team || "Simba SC",
          fingerprint: parsed.fingerprint || generateFingerprint(),
        };
        return cachedProfile;
      }
    }
  } catch {
    // ignore
  }

  const newProfile: FanProfile = {
    name: "",
    team: "Simba SC",
    fingerprint: generateFingerprint(),
  };
  try {
    localStorage.setItem("sokabrain_fan_profile", JSON.stringify(newProfile));
  } catch {
    // ignore
  }
  cachedProfile = newProfile;
  return newProfile;
}

export function saveFanProfile(profile: Partial<FanProfile>): FanProfile {
  const current = getStoredFanProfile();
  const updated: FanProfile = {
    ...current,
    ...profile,
    fingerprint: current.fingerprint || generateFingerprint(),
  };
  try {
    localStorage.setItem("sokabrain_fan_profile", JSON.stringify(updated));
  } catch {
    // ignore
  }
  notifyFanProfile();
  return updated;
}

export function useFanProfile() {
  const profile = useSyncExternalStore(
    subscribeFanProfile,
    getStoredFanProfile,
    () => DEFAULT_PROFILE,
  );

  const update = useCallback((data: Partial<FanProfile>) => {
    saveFanProfile(data);
  }, []);

  return {
    profile,
    hasProfile: Boolean(profile.name.trim()),
    update,
  };
}
