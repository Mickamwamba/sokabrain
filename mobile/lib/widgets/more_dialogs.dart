import 'package:flutter/material.dart';
import '../services/fan_profile_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_colors.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EditProfileSheet(),
    );
  }

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late TextEditingController _nameController;
  late String _selectedClub;
  bool _isSaving = false;

  final List<String> _popularClubs = [
    'Simba SC',
    'Yanga SC',
    'Azam FC',
    'Singida Black Stars',
    'Coastal Union',
    'Dodoma Jiji FC',
    'Mashujaa FC',
    'Tanzania Prisons',
    'KMC FC',
    'Geita Gold FC',
  ];

  @override
  void initState() {
    super.initState();
    final profile = FanProfileService();
    _nameController = TextEditingController(text: profile.fanName);
    _selectedClub = profile.favoriteTeam;
    if (!_popularClubs.contains(_selectedClub)) {
      _popularClubs.insert(0, _selectedClub);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    await FanProfileService().updateProfile(name: name, team: _selectedClub);
    await PreferencesService().addFavoriteTeam(_selectedClub);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface : Colors.white;
    final borderCol = isDark ? AppColors.border : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimary : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.textMuted : const Color(0xFF64748B);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: borderCol),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: borderCol,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Hariri Wasifu wa Shabiki',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('edit_profile_close_button'),
                  icon: Icon(Icons.close, size: 20, color: textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'JINA LA UTANI / SHABIKI',
              style: TextStyle(
                color: textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderCol),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _nameController,
                style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Mfano: Mnyama_Damu, MwambaWaKigoma',
                  hintStyle: TextStyle(color: textMuted, fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'TIMU YAKO PENDWA',
              style: TextStyle(
                color: textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _popularClubs.map((club) {
                final isSelected = club == _selectedClub;
                return ChoiceChip(
                  label: Text(club),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedClub = club);
                  },
                  selectedColor: AppColors.emerald,
                  backgroundColor: isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : textPrimary,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.emerald : borderCol,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text(
                        'Hifadhi Mabadiliko',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ManageFavoriteTeamsSheet extends StatefulWidget {
  const ManageFavoriteTeamsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ManageFavoriteTeamsSheet(),
    );
  }

  @override
  State<ManageFavoriteTeamsSheet> createState() => _ManageFavoriteTeamsSheetState();
}

class _ManageFavoriteTeamsSheetState extends State<ManageFavoriteTeamsSheet> {
  final TextEditingController _customTeamController = TextEditingController();
  final PreferencesService _prefs = PreferencesService();

  final List<String> _availableTeams = [
    'Simba SC',
    'Yanga SC',
    'Azam FC',
    'Singida Black Stars',
    'Coastal Union',
    'Dodoma Jiji FC',
    'Mashujaa FC',
    'Tanzania Prisons',
    'KMC FC',
    'Geita Gold FC',
    'Mbeya City',
    'JKT Tanzania',
    'Gor Mahia',
    'AFC Leopards',
    'Orlando Pirates',
    'Mamelodi Sundowns',
  ];

  @override
  void dispose() {
    _customTeamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface : Colors.white;
    final borderCol = isDark ? AppColors.border : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimary : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.textMuted : const Color(0xFF64748B);
    final favorites = _prefs.favoriteTeams;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: borderCol),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: borderCol,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Dhibiti Timu Pendwa',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('fav_teams_close_button'),
                  icon: Icon(Icons.close, size: 20, color: textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              'Chagua timu unazopenda kufuatilia kwa urahisi matokeo na ratiba zake.',
              style: TextStyle(color: textMuted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            // Custom Team Input
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderCol),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: _customTeamController,
                      style: TextStyle(color: textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Ongeza timu nyingine...',
                        hintStyle: TextStyle(color: textMuted, fontSize: 12.5),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final t = _customTeamController.text.trim();
                    if (t.isNotEmpty) {
                      await _prefs.addFavoriteTeam(t);
                      _customTeamController.clear();
                      setState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Ongeza',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'TIMU ZA LIGI (${favorites.length} Zimechaguliwa)',
              style: TextStyle(
                color: textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _availableTeams.length,
                itemBuilder: (context, index) {
                  final team = _availableTeams[index];
                  final isFav = favorites.contains(team);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: isFav
                          ? (isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9))
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isFav ? AppColors.emerald.withValues(alpha: 0.5) : borderCol.withValues(alpha: 0.5),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: isFav ? AppColors.emerald : borderCol,
                        child: Text(
                          team[0],
                          style: TextStyle(
                            color: isFav ? Colors.black : textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        team,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13.5,
                          fontWeight: isFav ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          isFav ? Icons.star_rounded : Icons.star_border_rounded,
                          color: isFav ? AppColors.amber : textMuted,
                        ),
                        onPressed: () async {
                          if (isFav) {
                            await _prefs.removeFavoriteTeam(team);
                          } else {
                            await _prefs.addFavoriteTeam(team);
                          }
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                );
              },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TermsConditionsSheet extends StatelessWidget {
  const TermsConditionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TermsConditionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface : Colors.white;
    final borderCol = isDark ? AppColors.border : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimary : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.textMuted : const Color(0xFF64748B);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: borderCol),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: borderCol,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Vigezo na Masharti',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                key: const Key('terms_close_button'),
                icon: Icon(Icons.close, size: 20, color: textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    '1. Utangulizi na Makubaliano',
                    'Karibu SokaBrain. Kwa kutumia programu hii, unakubaliana kuzingatia sheria zote za jamii, maadili ya michezo, na masharti yaliyowekwa hapa chini.',
                    textPrimary,
                    textMuted,
                  ),
                  _buildSection(
                    '2. Matumizi ya Kijiweni na Mijadala',
                    'Kijiweni ni jukwaa la wapenzi wa soka kutoa maoni kwa staha na heshima. Huruhusiwi kutumia lugha ya matusi, ubaguzi, uchochezi au maudhui yasiyofaa. Timu ya usimamizi ina mamlaka ya kufuta mada au kutoa adhabu kwa anayekiuka.',
                    textPrimary,
                    textMuted,
                  ),
                  _buildSection(
                    '3. Hakimiliki na Takwimu za Soka',
                    'Takwimu zote za mechi, wafungaji, na matokeo zinatolewa kwa madhumuni ya habari na uchambuzi wa michezo. Alama na nembo za klabu zinabaki kuwa mali ya klabu husika.',
                    textPrimary,
                    textMuted,
                  ),
                  _buildSection(
                    '4. Marekebisho ya Masharti',
                    'SokaBrain inahifadhi haki ya kuboresha au kurekebisha masharti haya mara kwa mara ili kulinda usalama na uzoefu bora wa mashabiki wote.',
                    textPrimary,
                    textMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String body, Color titleCol, Color bodyCol) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: titleCol, fontSize: 13.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(body, style: TextStyle(color: bodyCol, fontSize: 12.5, height: 1.45)),
        ],
      ),
    );
  }
}

class PrivacyPolicySheet extends StatelessWidget {
  const PrivacyPolicySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PrivacyPolicySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface : Colors.white;
    final borderCol = isDark ? AppColors.border : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimary : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.textMuted : const Color(0xFF64748B);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: borderCol),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: borderCol,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Sera ya Faragha (Privacy)',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                key: const Key('privacy_close_button'),
                icon: Icon(Icons.close, size: 20, color: textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    '1. Ulinzi wa Taarifa Zako',
                    'Tunathamini faragha yako kwa asilimia mia moja. SokaBrain haikusanyi taarifa binafsi kama namba za siri, kadi za benki, au anwani za makazi.',
                    textPrimary,
                    textMuted,
                  ),
                  _buildSection(
                    '2. Utambulisho Bila Kuingia (Anonymous Fingerprint)',
                    'Ili kukuwezesha kushiriki Kijiweni bila usumbufu wa kusajili akaunti au kukumbuka nenosiri, programu inatumia kitambulisho fiche (Device Fingerprint) kinachohifadhiwa ndani ya kifaa chako.',
                    textPrimary,
                    textMuted,
                  ),
                  _buildSection(
                    '3. Uhifadhi wa Mapendeleo ya Ndani',
                    'Mapendeleo yako kama timu unazopenda, hali ya mandhari (Dark/Light), na arifa yanahifadhiwa kwenye kifaa chako tu na hayatolewi kwa makampuni ya matangazo.',
                    textPrimary,
                    textMuted,
                  ),
                  _buildSection(
                    '4. Mawasiliano',
                    'Ukiwa na swali lolote kuhusu sera hii ya faragha au usalama wa taarifa zako, wasiliana nasi kupitia support@sokabrain.com.',
                    textPrimary,
                    textMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String body, Color titleCol, Color bodyCol) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: titleCol, fontSize: 13.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(body, style: TextStyle(color: bodyCol, fontSize: 12.5, height: 1.45)),
        ],
      ),
    );
  }
}

class AboutSokaBrainSheet extends StatelessWidget {
  const AboutSokaBrainSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AboutSokaBrainSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface : Colors.white;
    final borderCol = isDark ? AppColors.border : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimary : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.textMuted : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: borderCol),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: borderCol,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.emerald,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Text(
              'SB',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'SokaBrain',
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'Toleo 1.0.0 (Build 2026.09)',
            style: TextStyle(color: textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'SokaBrain ni jukwaa la kwanza Afrika Mashariki linaloleta takwimu za kina, matokeo papo kwa papo, na mijadala ya mashabiki wa soka kuanzia Tanzania Premier League hadi ligi zote za Afrika.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textMuted, fontSize: 12.5, height: 1.4),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '© 2026 SokaBrain. Haki zote zimehifadhiwa.',
              style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
