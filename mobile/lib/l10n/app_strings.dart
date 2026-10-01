import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class AppStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    // Primary Navigation
    'nav_matches': {
      'sw': 'Mechi',
      'en': 'Matches',
    },
    'nav_table_stats': {
      'sw': 'Msimamo & Takwimu',
      'en': 'Table & Stats',
    },
    'nav_leagues': {
      'sw': 'Ligi',
      'en': 'Leagues',
    },
    'nav_kijiweni': {
      'sw': 'Kijiweni',
      'en': 'Kijiweni',
    },
    'nav_more': {
      'sw': 'Zaidi',
      'en': 'More',
    },

    // Matches Screen Filters
    'filter_all': {
      'sw': 'Zote',
      'en': 'All',
    },
    'filter_live': {
      'sw': 'Moja kwa Moja',
      'en': 'Live',
    },
    'filter_finished': {
      'sw': 'Zilizokwisha',
      'en': 'Finished',
    },
    'filter_upcoming': {
      'sw': 'Zinazokuja',
      'en': 'Upcoming',
    },
    'day_today': {
      'sw': 'LEO',
      'en': 'TODAY',
    },
    'no_matches_scheduled': {
      'sw': 'Hakuna Mechi Zilizopangwa',
      'en': 'No Matches Scheduled',
    },
    'no_matches_desc': {
      'sw': 'Chagua tarehe nyingine kwenye kalenda hapo juu kuona ratiba.',
      'en': 'Select another date in the calendar above to view fixtures.',
    },
    'matches_suffix': {
      'sw': 'mechi',
      'en': 'matches',
    },
    'match_suffix_single': {
      'sw': 'mechi',
      'en': 'match',
    },

    // More Screen Header & Profile
    'more_title': {
      'sw': 'Zaidi (More)',
      'en': 'More & Settings',
    },
    'fan_badge': {
      'sw': 'SHABIKI',
      'en': 'FAN',
    },
    'club_label': {
      'sw': 'Klabu',
      'en': 'Club',
    },
    'edit': {
      'sw': 'Hariri',
      'en': 'Edit',
    },

    // Favourite Teams
    'fav_teams_title': {
      'sw': 'TIMU PENDWA',
      'en': 'FAVOURITE TEAMS',
    },
    'following': {
      'sw': 'Unazofuatilia',
      'en': 'Following',
    },
    'manage': {
      'sw': 'Dhibiti',
      'en': 'Manage',
    },
    'add_team': {
      'sw': 'Ongeza Timu',
      'en': 'Add Team',
    },

    // Appearance & Theme
    'appearance_title': {
      'sw': 'MANDHARI YA PROGRAMU',
      'en': 'APPEARANCE',
    },
    'dark_mode_title': {
      'sw': 'Hali ya Giza (Dark Mode)',
      'en': 'Dark Mode',
    },
    'dark_mode_desc': {
      'sw': 'Mandhari ya giza yaliyokolea',
      'en': 'Deep dark theme',
    },
    'light_mode_title': {
      'sw': 'Hali ya Mwanga (Light Mode)',
      'en': 'Light Mode',
    },
    'light_mode_desc': {
      'sw': 'Mandhari safi na laini isiyo na giza',
      'en': 'Clean, balanced soft light theme',
    },

    // Language Section
    'language_title': {
      'sw': 'LUGHA YA PROGRAMU (LANGUAGE)',
      'en': 'APP LANGUAGE',
    },
    'language_sw': {
      'sw': 'Kiswahili',
      'en': 'Kiswahili',
    },
    'language_sw_sub': {
      'sw': 'Afrika Mashariki (Tanzania, Kenya, Uganda)',
      'en': 'East Africa default',
    },
    'language_en': {
      'sw': 'English (Kiingereza)',
      'en': 'English',
    },
    'language_en_sub': {
      'sw': 'Lugha ya Kiingereza kimataifa',
      'en': 'International English',
    },

    // Notifications
    'notifications_title': {
      'sw': 'ARIFA (NOTIFICATIONS)',
      'en': 'NOTIFICATIONS',
    },
    'notifications_master': {
      'sw': 'Wezesha Arifa Zote',
      'en': 'Enable All Notifications',
    },
    'notifications_master_desc': {
      'sw': 'Pokea taarifa za mechi na matukio muhimu',
      'en': 'Receive real-time match and event alerts',
    },
    'notifications_goals': {
      'sw': 'Mabao Papo kwa Papo (Goal Alerts)',
      'en': 'Live Goal Alerts',
    },
    'notifications_kickoff': {
      'sw': 'Vikumbusho vya Kuanza Mechi (Kickoff)',
      'en': 'Match Kickoff Reminders',
    },
    'notifications_kijiweni': {
      'sw': 'Mijadala na Majibu ya Kijiweni',
      'en': 'Kijiweni Community Discussions',
    },

    // Legal & Info
    'legal_info_title': {
      'sw': 'KISHERIA NA TAARIFA',
      'en': 'LEGAL & INFORMATION',
    },
    'terms_conditions': {
      'sw': 'Vigezo na Masharti',
      'en': 'Terms & Conditions',
    },
    'terms_subtitle': {
      'sw': 'Sheria za jamii na matumizi ya huduma',
      'en': 'Community guidelines & terms of use',
    },
    'privacy_policy': {
      'sw': 'Sera ya Faragha (Privacy)',
      'en': 'Privacy Policy',
    },
    'privacy_subtitle': {
      'sw': 'Ulinzi wa data na taarifa zako',
      'en': 'Data protection and anonymous identity',
    },
    'share_app': {
      'sw': 'Shiriki SokaBrain na Marafiki',
      'en': 'Share SokaBrain with Friends',
    },
    'share_subtitle': {
      'sw': 'Sambaza programu kwa wapenzi wengine wa soka',
      'en': 'Spread the word to fellow football lovers',
    },
    'about_sokabrain': {
      'sw': 'Kuhusu SokaBrain',
      'en': 'About SokaBrain',
    },
    'about_subtitle': {
      'sw': 'Toleo 1.0.0 • Ubunifu wa Michezo Afrika',
      'en': 'Version 1.0.0 • African Football Intelligence',
    },

    // Competitions & League Hub
    'competitions_title': {
      'sw': 'Mashindano & Ligi',
      'en': 'Competitions & Leagues',
    },
    'search_league_hint': {
      'sw': 'Tafuta ligi au nchi (mf. Tanzania, Kenya)...',
      'en': 'Search league or country (e.g. Tanzania, Kenya)...',
    },
    'no_league_found': {
      'sw': 'Hakuna ligi iliyopatikana.',
      'en': 'No competitions found.',
    },
    'selected_league': {
      'sw': 'LIGI ILIYOCHAGULIWA',
      'en': 'SELECTED LEAGUE',
    },
    'change': {
      'sw': 'Badili',
      'en': 'Change',
    },
    'all_time': {
      'sw': 'HISTORIA (ALL-TIME)',
      'en': 'ALL-TIME STATS',
    },
    'tab_table': {
      'sw': 'Msimamo',
      'en': 'Table',
    },
    'tab_stats': {
      'sw': 'Takwimu',
      'en': 'Stats',
    },
    'tab_overview': {
      'sw': 'Ujumla',
      'en': 'Overview',
    },
    'tab_clubs': {
      'sw': 'Vilabu',
      'en': 'Clubs',
    },

    // Kijiweni
    'kijiweni_title': {
      'sw': 'Kijiweni',
      'en': 'Kijiweni',
    },
    'kijiweni_subtitle': {
      'sw': 'Mjadala na Ushabiki wa Soka Afrika Mashariki',
      'en': 'East African Football Banter & Discussions',
    },
    'new_thread': {
      'sw': 'Anzisha Mada',
      'en': 'Start Discussion',
    },
    'share': {
      'sw': 'Shiriki',
      'en': 'Share',
    },
    'comments': {
      'sw': 'Maoni',
      'en': 'Comments',
    },
    'send': {
      'sw': 'Tuma',
      'en': 'Send',
    },
    'close': {
      'sw': 'Funga',
      'en': 'Close',
    },
    'save': {
      'sw': 'Hifadhi',
      'en': 'Save',
    },
    'cancel': {
      'sw': 'Ghairi',
      'en': 'Cancel',
    },
  };

  static String get(String key, {String? lang}) {
    final activeLang = lang ?? PreferencesService().language;
    final dict = _localizedValues[key];
    if (dict == null) return key;
    return dict[activeLang] ?? dict['sw'] ?? dict['en'] ?? key;
  }

  static String tr(BuildContext context, String key) {
    return get(key);
  }

  static String formatMatches(int count, {String? lang}) {
    final activeLang = lang ?? PreferencesService().language;
    if (activeLang == 'en') {
      return '$count ${count == 1 ? "match" : "matches"}';
    }
    return '$count mechi';
  }
}

extension AppStringsExtension on BuildContext {
  String tr(String key) => AppStrings.get(key);
  bool get isSwahili => PreferencesService().language == 'sw';
}
