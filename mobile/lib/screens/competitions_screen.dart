import 'package:flutter/material.dart';
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
    final query = _searchQuery.toLowerCase().trim();
    return _competitions.where((c) {
      final matchName = c.name.toLowerCase().contains(query);
      final matchCountry = (c.country ?? '').toLowerCase().contains(query);
      return matchName || matchCountry;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mashindano & Ligi', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Tafuta ligi au nchi (mf. Tanzania, Kenya)...',
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  icon: Icon(Icons.search, size: 18, color: AppColors.textMuted),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Competitions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.emerald))
                : _filteredCompetitions.isEmpty
                    ? const Center(
                        child: Text(
                          'Hakuna ligi iliyopatikana.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.emerald,
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
    final latestEdition = comp.editions.isNotEmpty ? comp.editions.first : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Flag / Region Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: Text(comp.flagEmoji, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comp.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (comp.country != null) ...[
                            Text(
                              comp.country!,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                            const Text(' • ', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          ],
                          Text(
                            "${comp.editions.length} Seasons",
                            style: const TextStyle(
                              color: AppColors.emerald,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (comp.tier != null) ...[
                            const Text(' • ', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            Text(
                              "Tier ${comp.tier}",
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: 10),

            // Action Buttons (Table, Top Scorers)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
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
                    icon: const Icon(Icons.format_list_numbered, size: 14, color: AppColors.emerald),
                    label: const Text(
                      'Msimamo',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LeagueHubScreen(
                            initialCompetitionId: comp.competitionId,
                            initialEditionId: latestEdition?.editionId,
                            initialSubTab: 1,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bar_chart_rounded, size: 14, color: AppColors.amber),
                    label: const Text(
                      'Takwimu',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
