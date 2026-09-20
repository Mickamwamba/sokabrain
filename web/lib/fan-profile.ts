"use client";

import { useState } from "react";

export interface FanProfile {
  name: string;
  team: string;
  fingerprint: string;
}

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

export function getStoredFanProfile(): FanProfile {
  if (typeof window === "undefined") {
    return { name: "", team: "Simba SC", fingerprint: "anon" };
  }
  try {
    const raw = localStorage.getItem("sokabrain_fan_profile");
    if (raw) {
      const parsed = JSON.parse(raw);
      if (parsed.name && parsed.fingerprint) return parsed;
    }
  } catch {
    // ignore
  }
  // create new guest profile
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
  return updated;
}

export function useFanProfile() {
  const [profile, setProfile] = useState<FanProfile>(() => {
    return getStoredFanProfile();
  });

  const update = (data: Partial<FanProfile>) => {
    const next = saveFanProfile(data);
    setProfile(next);
  };

  return {
    profile,
    hasProfile: Boolean(profile.name.trim()),
    update,
  };
}
