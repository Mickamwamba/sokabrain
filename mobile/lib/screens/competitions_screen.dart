import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/standings.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'league_hub_screen.dart';

class CompetitionsScreen extends StatefulWidget {
  const CompetitionsScreen({super.key});

  @override
  State<CompetitionsScreen> createState() => _CompetitionsScreenState();
}

class _CompetitionsScreenState extends State<CompetitionsScreen> {
  bool _isLoading = true;
  List<CompetitionGroup> _competitions = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCompetitions();
  }

  Future<void> _loadCompetitions() async {
    setState(() => _isLoading = true);
    final editions = await ApiService.fetchEditions();
    if (!mounted) return;

    // Group editions by competitionId or competition name
    final Map<String, List<LeagueEdition>> grouped = {};
    for (final ed in editions) {
      final key = "${ed.competitionId ?? ed.competition}";
      grouped.putIfAbsent(key, () => []).add(ed);
    }

    final List<CompetitionGroup> comps = [];
    for (final entry in grouped.entries) {
      final list = entry.value;
      if (list.isEmpty) continue;
      final first = list.first;
      // Sort seasons descending (e.g. 2026/2027 first)
      list.sort((a, b) => b.season.compareTo(a.season));

      comps.add(
        CompetitionGroup(
          competitionId: first.competitionId ?? 0,
          name: first.competition,
          country: first.country,
          type: first.competitionType,
          tier: first.tier,
          editions: list,
        ),
      );
    }

    // Sort: Premier leagues first, then by country
    comps.sort((a, b) {
      if (a.country != null && b.country == null) return -1;
      if (a.country == null && b.country != null) return 1;
      return a.name.compareTo(b.name);
    });

    setState(() {
      _competitions = comps;
      _isLoading = false;
    });
  }

  List<CompetitionGroup> get _filteredCompetitions {
    if (_searchQuery.trim().isEmpty) return _competitions;
    final q = _searchQuery.toLowerCase().trim();
    return _competitions.where((c) {
      final name = c.name.toLowerCase();
      final country = (c.country ?? '').toLowerCase();
      return name.contains(q) || country.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final searchBg = isDark ? AppColors.surface : Colors.white;
    final searchBorder = isDark ? AppColors.border : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('competitions_title'), style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 20, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
            tooltip: AppStrings.get('refresh'),
            onPressed: _loadCompetitions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: searchBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: searchBorder),
                boxShadow: isDark
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(color: textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: AppStrings.get('search_league_hint'),
                  hintStyle: TextStyle(color: textMuted, fontSize: 13),
                  icon: Icon(Icons.search, size: 18, color: textMuted),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Competitions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.emerald))
                : _filteredCompetitions.isEmpty
                    ? Center(
                        child: Text(
                          AppStrings.get('no_league_found'),
                          style: TextStyle(color: textMuted),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.emerald,
                        backgroundColor: isDark ? AppColors.surface : AppColors.lightSurface,
                        onRefresh: _loadCompetitions,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _filteredCompetitions.length,
                          itemBuilder: (context, index) {
                            final comp = _filteredCompetitions[index];
                            return _buildCompetitionCard(comp);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitionCard(CompetitionGroup comp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surface : Colors.white;
    final borderCol = isDark ? AppColors.borderSubtle : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final avatarBg = isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LeagueHubScreen(
                  initialCompetitionId: comp.competitionId,
                  initialSubTab: 0,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Flag / Region Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: avatarBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? AppColors.border : AppColors.lightBorder),
                  ),
                  alignment: Alignment.center,
                  child: Text(comp.flagEmoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comp.name,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        "${comp.displayCountry} • ${comp.editions.length} Seasons${comp.tier != null ? ' • Tier ${comp.tier}' : ''}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: textMuted, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
