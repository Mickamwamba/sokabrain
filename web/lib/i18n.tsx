"use client";

import { createContext, useContext, useState, ReactNode } from "react";

export type Language = "sw" | "en";

export interface Translations {
  nav: {
    matches: string;
    table: string;
    stats: string;
    kijiweni: string;
    search: string;
  };
  kijiweni: {
    heroTitle: string;
    heroSub: string;
    allSpaces: string;
    filterByTag: string;
    allTags: string;
    sortLatest: string;
    sortPopular: string;
    startThread: string;
    startThreadSub: string;
    threadsCount: string;
    commentsCount: string;
    likesCount: string;
    noThreads: string;
    noThreadsSub: string;
    backToKijiweni: string;
    shareThread: string;
    copiedLink: string;
    shareWhatsapp: string;
    commentsTitle: string;
    noComments: string;
    noCommentsSub: string;
    addComment: string;
    commentPlaceholder: string;
    postComment: string;
    titlePlaceholder: string;
    contentPlaceholder: string;
    selectSpace: string;
    selectTag: string;
    postThread: string;
    cancel: string;
    fanHandle: string;
    chooseTeam: string;
    fanModalTitle: string;
    fanModalSub: string;
    saveProfile: string;
    changeProfile: string;
    anonymousFan: string;
  };
  tags: {
    UBISHI: string;
    CHOMBEZA: string;
    UTABIRI: string;
    MBINU: string;
  };
}

export const DICTIONARY: Record<Language, Translations> = {
  sw: {
    nav: {
      matches: "Mechi",
      table: "Msimamo",
      stats: "Takwimu",
      kijiweni: "Kijiweni 🔥",
      search: "Tafuta klabu, mchezaji...",
    },
    kijiweni: {
      heroTitle: "Kijiweni cha Soka",
      heroSub: "Kona ya mashabiki wa soka la Afrika Mashariki. Bisha, cheka, tambiana na chambua mbinu bila woga.",
      allSpaces: "Vijiwe Vyote",
      filterByTag: "Chagua Aina ya Mada",
      allTags: "Mada Zote",
      sortLatest: "Mpya Zaidi",
      sortPopular: "Zinazovuma 🔥",
      startThread: "Anzisha Mada ✍️",
      startThreadSub: "Weka ubishi, chombeza, au tabiri matokeo kijiweni",
      threadsCount: "mada",
      commentsCount: "maoni",
      likesCount: "sauti",
      noThreads: "Bado hakuna mada kwenye kijiwe hiki",
      noThreadsSub: "Kuwa wa kwanza kuanzisha ubishi au kutupia chombeza hapa!",
      backToKijiweni: "← Rudi Kijiweni",
      shareThread: "Sambaza Mada",
      copiedLink: "Link Imenakiliwa!",
      shareWhatsapp: "Tuma WhatsApp",
      commentsTitle: "Mawazo ya Wana-Kijiwe",
      noComments: "Bado hakuna maoni",
      noCommentsSub: "Tupia mtazamo wako kwanza, shabiki wa kweli hanyamazi!",
      addComment: "Tupia Maoni Yako",
      commentPlaceholder: "Andika mawazo yako hapa... chombeza kistaarabu!",
      postComment: "Tuma Maoni",
      titlePlaceholder: "Kichwa cha habari (mfano: Nani atabeba ubingwa msimu huu?)",
      contentPlaceholder: "Funguka hapa... toa hoja zako, takwimu au utani wa soka...",
      selectSpace: "Chagua Kijiwe",
      selectTag: "Aina ya Mada",
      postThread: "Weka Mada Kijiweni",
      cancel: "Ghairi",
      fanHandle: "Jina Lako Kijiweni",
      chooseTeam: "Klabu Unayoshabikia",
      fanModalTitle: "Wewe ni Nani Kijiweni?",
      fanModalSub: "Weka jina lako la ushabiki na klabu unayoipenda ili ikuonyeshe nembo rasmi ya timu yako.",
      saveProfile: "Hifadhi & Endelea",
      changeProfile: "Badili Wasifu",
      anonymousFan: "Shabiki wa Soka",
    },
    tags: {
      UBISHI: "Ubishi wa Jadi ⚔️",
      CHOMBEZA: "Chombeza & Utani 😂",
      UTABIRI: "Utabiri wa Mechi 🎯",
      MBINU: "Uchambuzi wa Mbinu 🧠",
    },
  },
  en: {
    nav: {
      matches: "Matches",
      table: "Table",
      stats: "Statistics",
      kijiweni: "Fan Zone 🔥",
      search: "Search clubs, players...",
    },
    kijiweni: {
      heroTitle: "Kijiweni (Fan Zone)",
      heroSub: "The authentic corner for East African football fans. Debate, banter, boast, and analyze matchdays together.",
      allSpaces: "All Corners",
      filterByTag: "Filter by Topic",
      allTags: "All Topics",
      sortLatest: "Latest",
      sortPopular: "Trending 🔥",
      startThread: "Start Topic ✍️",
      startThreadSub: "Kick off a debate, share banter, or predict scores",
      threadsCount: "topics",
      commentsCount: "replies",
      likesCount: "cheers",
      noThreads: "No topics found in this corner yet",
      noThreadsSub: "Be the first to ignite the debate or drop a matchday prediction!",
      backToKijiweni: "← Back to Fan Zone",
      shareThread: "Share Topic",
      copiedLink: "Link Copied!",
      shareWhatsapp: "Share on WhatsApp",
      commentsTitle: "Fan Discussion & Replies",
      noComments: "No replies yet",
      noCommentsSub: "Drop your take first — a true fan always has a point to make!",
      addComment: "Join the Conversation",
      commentPlaceholder: "Share your thoughts, banter, or tactical view...",
      postComment: "Post Reply",
      titlePlaceholder: "Topic title (e.g., Who takes the league title this season?)",
      contentPlaceholder: "Speak your mind... share stats, arguments, or good banter...",
      selectSpace: "Select Corner",
      selectTag: "Topic Category",
      postThread: "Post to Fan Zone",
      cancel: "Cancel",
      fanHandle: "Your Fan Nickname",
      chooseTeam: "Your Supported Club",
      fanModalTitle: "Who Are You in the Fan Zone?",
      fanModalSub: "Set your fan handle and supported club to display your team badge proudly next to your comments.",
      saveProfile: "Save & Continue",
      changeProfile: "Edit Profile",
      anonymousFan: "Football Fan",
    },
    tags: {
      UBISHI: "Derby Debate ⚔️",
      CHOMBEZA: "Banter & Memes 😂",
      UTABIRI: "Score Predictions 🎯",
      MBINU: "Tactics & Analysis 🧠",
    },
  },
};

const LanguageContext = createContext<{
  lang: Language;
  setLang: (lang: Language) => void;
  t: Translations;
}>({
  lang: "sw",
  setLang: () => {},
  t: DICTIONARY.sw,
});

function getInitialLanguage(): Language {
  if (typeof window === "undefined") return "sw";
  try {
    const saved = localStorage.getItem("sokabrain_kijiweni_lang") as Language | null;
    if (saved === "en" || saved === "sw") return saved;
  } catch {
    // ignore
  }
  return "sw";
}

export function LanguageProvider({ children }: { children: ReactNode }) {
  const [lang, setLangState] = useState<Language>(getInitialLanguage);

  const setLang = (newLang: Language) => {
    setLangState(newLang);
    try {
      localStorage.setItem("sokabrain_kijiweni_lang", newLang);
    } catch {
      // ignore
    }
  };

  return (
    <LanguageContext.Provider value={{ lang, setLang, t: DICTIONARY[lang] }}>
      {children}
    </LanguageContext.Provider>
  );
}

export function useLanguage() {
  return useContext(LanguageContext);
}
