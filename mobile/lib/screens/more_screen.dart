import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/fan_profile_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_colors.dart';
import '../widgets/more_dialogs.dart';
import '../widgets/share_sheet.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final FanProfileService _fanProfile = FanProfileService();
  final PreferencesService _prefs = PreferencesService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _fanProfile.init();
    await _prefs.init();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.surface : AppColors.lightSurface;
    final borderCol = isDark ? AppColors.border : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    final fanName = _fanProfile.fanName;
    final favoriteTeam = _fanProfile.favoriteTeam;
    final fingerprint = _fanProfile.fingerprint;
    final favTeams = _prefs.favoriteTeams;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          AppStrings.get('more_title'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // 1. User Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol),
              boxShadow: isDark
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.emerald,
                      child: Text(
                        fanName.isNotEmpty ? fanName[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  fanName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  AppStrings.get('fan_badge'),
                                  style: const TextStyle(
                                    color: AppColors.emerald,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${AppStrings.get("club_label")}: $favoriteTeam',
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${fingerprint.length > 16 ? "${fingerprint.substring(0, 16)}..." : fingerprint}',
                            style: TextStyle(
                              color: textMuted.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        final changed = await EditProfileSheet.show(context);
                        if (changed == true) {
                          setState(() {});
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: borderCol),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        AppStrings.get('edit'),
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Favourite Teams Section
          _buildSectionHeader(AppStrings.get('fav_teams_title'), textMuted),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderCol),
              boxShadow: isDark
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${AppStrings.get("following")} (${favTeams.length})',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await ManageFavoriteTeamsSheet.show(context);
                        setState(() {});
                      },
                      icon: const Icon(Icons.tune_rounded, size: 14, color: AppColors.emerald),
                      label: Text(
                        AppStrings.get('manage'),
                        style: const TextStyle(color: AppColors.emerald, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...favTeams.map(
                      (team) => Chip(
                        avatar: CircleAvatar(
                          backgroundColor: AppColors.emerald,
                          child: Text(
                            team[0],
                            style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                        label: Text(team),
                        labelStyle: TextStyle(
                          color: textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: isDark ? AppColors.surfaceElevated : AppColors.lightBackground,
                        side: BorderSide(color: borderCol),
                        deleteIcon: Icon(Icons.close, size: 14, color: textMuted),
                        onDeleted: () async {
                          await _prefs.removeFavoriteTeam(team);
                          setState(() {});
                        },
                      ),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16, color: AppColors.emerald),
                      label: Text(AppStrings.get('add_team')),
                      labelStyle: const TextStyle(
                        color: AppColors.emerald,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(color: AppColors.emerald, width: 1),
                      onPressed: () async {
                        await ManageFavoriteTeamsSheet.show(context);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Theme & Appearance
          _buildSectionHeader(AppStrings.get('appearance_title'), textMuted),
          Material(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: borderCol),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    _prefs.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: _prefs.isDarkMode ? AppColors.emerald : AppColors.amber,
                  ),
                  title: Text(
                    _prefs.isDarkMode
                        ? AppStrings.get('dark_mode_title')
                        : AppStrings.get('light_mode_title'),
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    _prefs.isDarkMode
                        ? AppStrings.get('dark_mode_desc')
                        : AppStrings.get('light_mode_desc'),
                    style: TextStyle(color: textMuted, fontSize: 12),
                  ),
                  value: _prefs.isDarkMode,
                  activeTrackColor: AppColors.emerald,
                  onChanged: (val) async {
                    await _prefs.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Language Translation Section (English / Swahili)
          _buildSectionHeader(AppStrings.get('language_title'), textMuted),
          Material(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: borderCol),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  onTap: () async {
                    await _prefs.setLanguage('sw');
                    setState(() {});
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceElevated : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('🇹🇿', style: TextStyle(fontSize: 18)),
                  ),
                  title: Text(
                    AppStrings.get('language_sw'),
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: _prefs.language == 'sw' ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    AppStrings.get('language_sw_sub'),
                    style: TextStyle(color: textMuted, fontSize: 11.5),
                  ),
                  trailing: _prefs.language == 'sw'
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 22)
                      : Icon(Icons.radio_button_unchecked_rounded, color: textMuted, size: 22),
                ),
                Divider(color: borderCol, height: 1),
                ListTile(
                  onTap: () async {
                    await _prefs.setLanguage('en');
                    setState(() {});
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceElevated : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('🇬🇧', style: TextStyle(fontSize: 18)),
                  ),
                  title: Text(
                    AppStrings.get('language_en'),
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: _prefs.language == 'en' ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    AppStrings.get('language_en_sub'),
                    style: TextStyle(color: textMuted, fontSize: 11.5),
                  ),
                  trailing: _prefs.language == 'en'
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 22)
                      : Icon(Icons.radio_button_unchecked_rounded, color: textMuted, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. Notifications Section
          _buildSectionHeader(AppStrings.get('notifications_title'), textMuted),
          Material(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: borderCol),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.emerald),
                  title: Text(
                    AppStrings.get('notifications_master'),
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    AppStrings.get('notifications_master_desc'),
                    style: TextStyle(color: textMuted, fontSize: 12),
                  ),
                  value: _prefs.notificationsEnabled,
                  activeTrackColor: AppColors.emerald,
                  onChanged: (val) async {
                    await _prefs.setNotificationsEnabled(val);
                    setState(() {});
                  },
                ),
                if (_prefs.notificationsEnabled) ...[
                  Divider(color: borderCol, height: 1),
                  CheckboxListTile(
                    title: Text(
                      AppStrings.get('notifications_goals'),
                      style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    value: _prefs.notifyGoals,
                    activeColor: AppColors.emerald,
                    checkColor: Colors.black,
                    dense: true,
                    onChanged: (val) async {
                      await _prefs.setNotificationOption(goals: val ?? true);
                      setState(() {});
                    },
                  ),
                  CheckboxListTile(
                    title: Text(
                      AppStrings.get('notifications_kickoff'),
                      style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    value: _prefs.notifyKickoff,
                    activeColor: AppColors.emerald,
                    checkColor: Colors.black,
                    dense: true,
                    onChanged: (val) async {
                      await _prefs.setNotificationOption(kickoff: val ?? true);
                      setState(() {});
                    },
                  ),
                  CheckboxListTile(
                    title: Text(
                      AppStrings.get('notifications_kijiweni'),
                      style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    value: _prefs.notifyKijiweni,
                    activeColor: AppColors.emerald,
                    checkColor: Colors.black,
                    dense: true,
                    onChanged: (val) async {
                      await _prefs.setNotificationOption(kijiweni: val ?? true);
                      setState(() {});
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 6. Legal & Info Section
          _buildSectionHeader(AppStrings.get('legal_info_title'), textMuted),
          Material(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: borderCol),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildMenuTile(
                  icon: Icons.description_outlined,
                  title: AppStrings.get('terms_conditions'),
                  subtitle: AppStrings.get('terms_subtitle'),
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  borderCol: borderCol,
                  onTap: () => TermsConditionsSheet.show(context),
                ),
                Divider(color: borderCol, height: 1),
                _buildMenuTile(
                  icon: Icons.shield_outlined,
                  title: AppStrings.get('privacy_policy'),
                  subtitle: AppStrings.get('privacy_subtitle'),
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  borderCol: borderCol,
                  onTap: () => PrivacyPolicySheet.show(context),
                ),
                Divider(color: borderCol, height: 1),
                _buildMenuTile(
                  icon: Icons.info_outline_rounded,
                  title: AppStrings.get('about_sokabrain'),
                  subtitle: AppStrings.get('about_subtitle'),
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  borderCol: borderCol,
                  onTap: () => AboutSokaBrainSheet.show(context),
                ),
                Divider(color: borderCol, height: 1),
                _buildMenuTile(
                  icon: Icons.share_outlined,
                  title: AppStrings.get('share_app'),
                  subtitle: AppStrings.get('share_subtitle'),
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  borderCol: borderCol,
                  onTap: () {
                    ShareSheet.showGeneric(
                      context,
                      title: 'SokaBrain - Matokeo, Takwimu & Kijiweni',
                      url: 'https://sokabrain.com',
                      summary: 'Pata matokeo ya soka la Afrika Mashariki, msimamo wa ligi na uchambuzi wa kina.',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Footer
          Center(
            child: Column(
              children: [
                Text(
                  'SokaBrain v1.0.0 (Build 2026.09)',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kiwanda cha Takwimu za Soka Afrika',
                  style: TextStyle(
                    color: textMuted.withValues(alpha: 0.7),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          color: textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textPrimary,
    required Color textMuted,
    required Color borderCol,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: const Icon(Icons.circle, color: Colors.transparent, size: 0),
      leadingAndTrailingTextStyle: null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Row(
        children: [
          Icon(icon, color: AppColors.emerald, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: textMuted, size: 20),
      onTap: onTap,
    );
  }
}
