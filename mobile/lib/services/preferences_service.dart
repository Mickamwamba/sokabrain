import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'fan_profile_service.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);
  final ValueNotifier<String> languageNotifier = ValueNotifier<String>('sw');

  bool _isInitialized = false;
  bool _notificationsEnabled = true;
  bool _notifyGoals = true;
  bool _notifyKickoff = true;
  bool _notifyKijiweni = true;
  String _language = 'sw'; // 'sw' or 'en'
  final List<String> _favoriteTeams = ['Simba SC', 'Yanga SC'];

  bool get isDarkMode => themeNotifier.value == ThemeMode.dark;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get notifyGoals => _notifyGoals;
  bool get notifyKickoff => _notifyKickoff;
  bool get notifyKijiweni => _notifyKijiweni;
  String get language => _language;
  bool get isSwahili => _language == 'sw';
  List<String> get favoriteTeams => List.unmodifiable(_favoriteTeams);

  File get _storageFile {
    final tempDir = Directory.systemTemp;
    return File('${tempDir.path}/sokabrain_preferences.json');
  }

  Future<void> init() async {
    if (_isInitialized) return;
    await FanProfileService().init();
    try {
      final file = _storageFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final isDark = data['isDarkMode'] as bool? ?? true;
        themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
        _notificationsEnabled = data['notificationsEnabled'] as bool? ?? true;
        _notifyGoals = data['notifyGoals'] as bool? ?? true;
        _notifyKickoff = data['notifyKickoff'] as bool? ?? true;
        _notifyKijiweni = data['notifyKijiweni'] as bool? ?? true;
        _language = data['language'] as String? ?? 'sw';
        languageNotifier.value = _language;
        final teams = (data['favoriteTeams'] as List<dynamic>?)?.map((e) => e.toString()).toList();
        if (teams != null && teams.isNotEmpty) {
          _favoriteTeams.clear();
          _favoriteTeams.addAll(teams);
        }
      } else {
        await _save();
      }
    } catch (_) {}
    _isInitialized = true;
  }

  Future<void> _save() async {
    try {
      final file = _storageFile;
      final data = {
        'isDarkMode': isDarkMode,
        'notificationsEnabled': _notificationsEnabled,
        'notifyGoals': _notifyGoals,
        'notifyKickoff': _notifyKickoff,
        'notifyKijiweni': _notifyKijiweni,
        'language': _language,
        'favoriteTeams': _favoriteTeams,
      };
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeNotifier.value = mode;
    await _save();
  }

  Future<void> toggleThemeMode() async {
    final newMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _save();
  }

  Future<void> setNotificationOption({bool? goals, bool? kickoff, bool? kijiweni}) async {
    if (goals != null) _notifyGoals = goals;
    if (kickoff != null) _notifyKickoff = kickoff;
    if (kijiweni != null) _notifyKijiweni = kijiweni;
    await _save();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    languageNotifier.value = lang;
    await _save();
  }

  Future<void> addFavoriteTeam(String team) async {
    final trimmed = team.trim();
    if (trimmed.isNotEmpty && !_favoriteTeams.contains(trimmed)) {
      _favoriteTeams.add(trimmed);
      await _save();
    }
  }

  Future<void> removeFavoriteTeam(String team) async {
    if (_favoriteTeams.remove(team)) {
      await _save();
    }
  }

  Future<void> setFavoriteTeams(List<String> teams) async {
    _favoriteTeams.clear();
    _favoriteTeams.addAll(teams);
    await _save();
  }
}
