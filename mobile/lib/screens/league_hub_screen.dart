import 'package:flutter/material.dart';
import '../models/standings.dart';
import '../models/stats.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'competitions_screen.dart';

class LeagueHubScreen extends StatefulWidget {
  final int? initialCompetitionId;
  final int? initialEditionId;
  final int initialSubTab;

  const LeagueHubScreen({
    super.key,
    this.initialCompetitionId,
    this.initialEditionId,
    this.initialSubTab = 0,
  });

  @override
  State<LeagueHubScreen> createState() => _LeagueHubScreenState();
}

class _LeagueHubScreenState extends State<LeagueHubScreen> {
  // Navigation sub-tab: 0 = Msimamo (Table), 1 = Takwimu (Stats)
  late int _activeSubTab;

  bool _isLoading = true;
  List<CompetitionGroup> _competitions = [];
  CompetitionGroup? _selectedCompetition;
  LeagueEdition? _selectedEdition;
  bool _isAllTime = false;

  // Table Data
  List<StandingsRow> _standings = [];

  // Stats Data
  StatsOverview? _overview;
  List<TopScorerItem> _scorers = [];
  List<ClubStatItem> _clubs = [];
  String _clubStatFilter = 'wins'; // 'wins', 'goals', 'defense', 'winRate'

  @override
  void initState() {
    super.initState();
    _activeSubTab = widget.initialSubTab;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final editions = await ApiService.fetchEditions();
    if (!mounted) return;

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

    comps.sort((a, b) {
      if (a.country != null && b.country == null) return -1;
      if (a.country == null && b.country != null) return 1;
      return a.name.compareTo(b.name);
    });

    setState(() {
      _competitions = comps;
    });

    _applyInitialSelection();
  }

  void _applyInitialSelection() {
    if (_competitions.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    CompetitionGroup? targetComp;
    LeagueEdition? targetEdition;

    if (widget.initialEditionId != null) {
      for (final comp in _competitions) {
        final match = comp.editions.where((e) => e.editionId == widget.initialEditionId).firstOrNull;
        if (match != null) {
          targetComp = comp;
          targetEdition = match;
          break;
        }
      }
    }

    if (targetComp == null && widget.initialCompetitionId != null) {
      targetComp = _competitions.where((c) => c.competitionId == widget.initialCompetitionId).firstOrNull;
    }

    targetComp ??= _competitions.firstWhere(
      (c) => c.name.toLowerCase().contains('tanzania') && c.totalMatches > 0,
      orElse: () => _competitions.firstWhere(
        (c) => c.totalMatches > 0,
        orElse: () => _competitions.first,
      ),
    );

    targetEdition ??= targetComp.editions.isNotEmpty
        ? targetComp.editions.firstWhere(
            (e) => (e.matchCount ?? 0) > 0,
            orElse: () => targetComp!.editions.first,
          )
        : null;

    setState(() {
      _selectedCompetition = targetComp;
      _selectedEdition = targetEdition;
      _isAllTime = false;
    });

    _loadDataForCurrentSelection();
  }

  Future<void> _loadDataForCurrentSelection() async {
    setState(() => _isLoading = true);

    final compId = _selectedCompetition?.competitionId;
    final edId = _isAllTime ? null : _selectedEdition?.editionId;

    // Concurrently fetch standings and stats so switching sub-tabs is instantaneous
    final futures = <Future<dynamic>>[
      if (edId != null)
        ApiService.fetchStandings(edId)
      else
        Future.value(null),
      ApiService.fetchStatsOverview(competitionId: compId, editionId: edId),
      if (edId != null)
        ApiService.fetchTopScorers(edId, limit: 25)
      else
        ApiService.fetchPlayerStats(competitionId: compId, limit: 25),
      ApiService.fetchClubStats(competitionId: compId, editionId: edId),
    ];

    final results = await Future.wait(futures);
    if (!mounted) return;

    final standingsRes = results[0] as StandingsResponseData?;
    final overviewRes = results[1] as StatsOverview?;
    final scorersRes = results[2] as List<TopScorerItem>;
    final clubsRes = results[3] as List<ClubStatItem>;

    setState(() {
      _standings = standingsRes?.standings ?? [];
      _overview = overviewRes;
      _scorers = scorersRes;
      _clubs = clubsRes;
      _isLoading = false;
    });
  }

  void _onCompetitionChanged(CompetitionGroup comp) {
    if (_selectedCompetition?.competitionId == comp.competitionId) return;

    final newEdition = comp.editions.isNotEmpty
        ? comp.editions.firstWhere(
            (e) => (e.matchCount ?? 0) > 0,
            orElse: () => comp.editions.first,
          )
        : null;

    setState(() {
      _selectedCompetition = comp;
      _selectedEdition = newEdition;
      _isAllTime = false;
    });

    _loadDataForCurrentSelection();
  }

  void _onSeasonChanged(LeagueEdition edition) {
    if (_selectedEdition?.editionId == edition.editionId && !_isAllTime) return;
    setState(() {
      _selectedEdition = edition;
      _isAllTime = false;
    });
    _loadDataForCurrentSelection();
  }

  void _onAllTimeSelected() {
    if (_isAllTime) return;
    setState(() {
      _isAllTime = true;
    });
    _loadDataForCurrentSelection();
  }

  void _showCompetitionPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = _competitions.where((c) {
              if (query.trim().isEmpty) return true;
              final q = query.toLowerCase().trim();
              return c.name.toLowerCase().contains(q) || (c.country ?? '').toLowerCase().contains(q);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.72,
              minChildSize: 0.4,
              maxChildSize: 0.92,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Chagua Mashindano',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CompetitionsScreen()),
                              );
                            },
                            child: const Text(
                              'Orodha Kamili →',
                              style: TextStyle(color: AppColors.emerald, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          onChanged: (val) => setSheetState(() => query = val),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Tafuta ligi au nchi...',
                            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            icon: Icon(Icons.search, size: 18, color: AppColors.textMuted),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 16, color: AppColors.borderSubtle),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderSubtle),
                        itemBuilder: (_, index) {
                          final c = filtered[index];
                          final isSelected = c.competitionId == _selectedCompetition?.competitionId;

                          return ListTile(
                            onTap: () {
                              Navigator.pop(ctx);
                              _onCompetitionChanged(c);
                            },
                            leading: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.emerald.withValues(alpha: 0.15) : AppColors.surfaceElevated,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.emerald : AppColors.borderSubtle,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(c.flagEmoji, style: const TextStyle(fontSize: 16)),
                            ),
                            title: Text(
                              c.name,
                              style: TextStyle(
                                color: isSelected ? AppColors.emerald : AppColors.textPrimary,
                                fontSize: 13.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              "${c.country ?? 'Regional'} • ${c.editions.length} Seasons",
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: AppColors.emerald, size: 18)
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableSeasons = _selectedCompetition?.editions ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mashindano & Msimamo', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined, color: AppColors.textSecondary),
            tooltip: 'Ligi Zote',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CompetitionsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20, color: AppColors.textSecondary),
            onPressed: _loadDataForCurrentSelection,
          ),
        ],
      ),
      body: Column(
        children: [
          // Sticky Top Section: Competition + Season Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Competition Switcher Bar
                InkWell(
                  onTap: _showCompetitionPicker,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border, width: 0.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _selectedCompetition?.flagEmoji ?? '🏆',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'LIGI ILIYOCHAGULIWA',
                                style: TextStyle(
                                  color: AppColors.emerald,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                _selectedCompetition?.name ?? 'Chagua Mashindano',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Badili',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.swap_vert, size: 14, color: AppColors.emerald),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Season Selector Horizontal Pills + All-Time
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text(
                      'MSIMU:',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // All-time Pill
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: const Text('All-Time 🌟'),
                                selected: _isAllTime,
                                onSelected: (_) => _onAllTimeSelected(),
                                labelStyle: TextStyle(
                                  color: _isAllTime ? Colors.black : AppColors.amber,
                                  fontSize: 11.5,
                                  fontWeight: _isAllTime ? FontWeight.w800 : FontWeight.w700,
                                ),
                                selectedColor: AppColors.amber,
                                backgroundColor: AppColors.surfaceElevated,
                                side: BorderSide(
                                  color: _isAllTime ? AppColors.amber : AppColors.borderSubtle,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            // Season Pills
                            ...availableSeasons.map((ed) {
                              final isSelected = !_isAllTime && ed.editionId == _selectedEdition?.editionId;
                              final hasMatches = (ed.matchCount ?? 0) > 0;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(ed.season),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) _onSeasonChanged(ed);
                                  },
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.black
                                        : (hasMatches ? AppColors.textPrimary : AppColors.textMuted),
                                    fontSize: 11.5,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                  selectedColor: AppColors.emerald,
                                  backgroundColor: AppColors.surfaceElevated,
                                  side: BorderSide(
                                    color: isSelected ? AppColors.emerald : AppColors.borderSubtle,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  visualDensity: VisualDensity.compact,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Segmented Controller for [ Msimamo (Table) ] | [ Takwimu (Stats) ]
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _activeSubTab = 0),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _activeSubTab == 0 ? AppColors.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: _activeSubTab == 0
                                  ? Border.all(color: AppColors.emerald.withValues(alpha: 0.5), width: 1)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.format_list_numbered_rounded,
                                  size: 15,
                                  color: _activeSubTab == 0 ? AppColors.emerald : AppColors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Msimamo (Table)',
                                  style: TextStyle(
                                    color: _activeSubTab == 0 ? AppColors.textPrimary : AppColors.textMuted,
                                    fontSize: 12.5,
                                    fontWeight: _activeSubTab == 0 ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _activeSubTab = 1),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _activeSubTab == 1 ? AppColors.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: _activeSubTab == 1
                                  ? Border.all(color: AppColors.emerald.withValues(alpha: 0.5), width: 1)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bar_chart_rounded,
                                  size: 15,
                                  color: _activeSubTab == 1 ? AppColors.emerald : AppColors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Takwimu (Stats)',
                                  style: TextStyle(
                                    color: _activeSubTab == 1 ? AppColors.textPrimary : AppColors.textMuted,
                                    fontSize: 12.5,
                                    fontWeight: _activeSubTab == 1 ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Main Content View (Table or Stats)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.emerald))
                : _activeSubTab == 0
                    ? _buildTableView()
                    : _buildStatsView(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 1: STANDINGS TABLE VIEW
  // ==========================================
  Widget _buildTableView() {
    if (_isAllTime) {
      return _buildAllTimeTableView();
    }

    if (_standings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.table_chart_outlined, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Hakuna msimamo uliorekodiwa kwa msimu wa ${_selectedEdition?.season ?? ''}.',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Standings Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.background,
          child: const Row(
            children: [
              SizedBox(width: 28, child: Text('#', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
              Expanded(child: Text('CLUB', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
              SizedBox(width: 26, child: Text('P', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
              SizedBox(width: 26, child: Text('W', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
              SizedBox(width: 26, child: Text('D', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
              SizedBox(width: 26, child: Text('L', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
              SizedBox(width: 32, child: Text('GD', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
              SizedBox(width: 32, child: Text('PTS', textAlign: TextAlign.center, style: TextStyle(color: AppColors.emerald, fontSize: 11, fontWeight: FontWeight.w800))),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.borderSubtle),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.emerald,
            onRefresh: _loadDataForCurrentSelection,
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: _standings.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderSubtle),
              itemBuilder: (context, index) {
                final row = _standings[index];
                final isTopTier = row.position <= 2;
                final isRelegation = index >= _standings.length - 2;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: index % 2 == 0 ? AppColors.surface : AppColors.surface.withValues(alpha: 0.6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 16,
                              decoration: BoxDecoration(
                                color: isTopTier
                                    ? AppColors.emerald
                                    : (isRelegation ? AppColors.liveRed : Colors.transparent),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${row.position}",
                              style: TextStyle(
                                color: isTopTier ? AppColors.emerald : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border, width: 0.5),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                row.teamName.isNotEmpty ? row.teamName[0] : 'C',
                                style: const TextStyle(
                                  color: AppColors.emerald,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                row.teamName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 26, child: Text("${row.played}", textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                      SizedBox(width: 26, child: Text("${row.won}", textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                      SizedBox(width: 26, child: Text("${row.drawn}", textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                      SizedBox(width: 26, child: Text("${row.lost}", textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                      SizedBox(
                        width: 32,
                        child: Text(
                          row.goalDifference > 0 ? "+${row.goalDifference}" : "${row.goalDifference}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: row.goalDifference > 0 ? AppColors.textPrimary : AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        child: Text(
                          "${row.points}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.emerald,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // All-Time Club Table View
  Widget _buildAllTimeTableView() {
    if (_clubs.isEmpty) {
      return const Center(child: Text('Hakuna data ya kihistoria kwa ligi hii.', style: TextStyle(color: AppColors.textMuted)));
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.background,
          child: const Row(
            children: [
              SizedBox(width: 28, child: Text('#', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
              Expanded(child: Text('CLUB (ALL-TIME)', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
              SizedBox(width: 28, child: Text('P', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
              SizedBox(width: 28, child: Text('W', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
              SizedBox(width: 34, child: Text('GD', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
              SizedBox(width: 36, child: Text('PTS', textAlign: TextAlign.center, style: TextStyle(color: AppColors.emerald, fontSize: 11, fontWeight: FontWeight.w800))),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.borderSubtle),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: _clubs.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderSubtle),
            itemBuilder: (context, index) {
              final c = _clubs[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: index % 2 == 0 ? AppColors.surface : AppColors.surface.withValues(alpha: 0.6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        "${index + 1}",
                        style: TextStyle(
                          color: index < 3 ? AppColors.amber : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.teamName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            "${c.winRate.toStringAsFixed(1)}% win rate • ${c.cleanSheets} clean sheets",
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 28, child: Text("${c.played}", textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                    SizedBox(width: 28, child: Text("${c.won}", textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                    SizedBox(
                      width: 34,
                      child: Text(
                        c.goalDifference > 0 ? "+${c.goalDifference}" : "${c.goalDifference}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        "${c.points}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.emerald, fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // VIEW 2: RICH STATS VIEW (LIKE WEB)
  // ==========================================
  Widget _buildStatsView() {
    return RefreshIndicator(
      color: AppColors.emerald,
      onRefresh: _loadDataForCurrentSelection,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Overview Figures Banner
            if (_overview != null) ...[
              _buildOverviewCard(),
              const SizedBox(height: 16),
            ],

            // Section 2: Top Goalscorers Card
            _buildTopScorersSection(),
            const SizedBox(height: 16),

            // Section 3: Club Records & Performance
            _buildClubRecordsSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    final ov = _overview!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F273F).withValues(alpha: 0.8),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: AppColors.emerald, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isAllTime ? 'REKODI ZA KIHISTORIA (ALL-TIME)' : 'TAKWIMU ZA MSIMU',
                    style: const TextStyle(
                      color: AppColors.emerald,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                "${ov.clubs} Clubs",
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStatMetric('Mechi', '${ov.matches}', Icons.sports_soccer),
              _buildStatMetric('Magoli', '${ov.goals}', Icons.scoreboard_outlined),
              _buildStatMetric('Wastani', ov.goalsPerMatch.toStringAsFixed(2), Icons.speed),
              _buildStatMetric('Wachezaji', '${ov.players}', Icons.people_alt_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildTopScorersSection() {
    final maxGoals = _scorers.isNotEmpty ? _scorers.first.goals : 1;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.military_tech_outlined, size: 18, color: AppColors.amber),
                    SizedBox(width: 8),
                    Text(
                      'Wafungaji Bora (Top Scorers)',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Text(
                  _isAllTime ? 'All-Time' : (_selectedEdition?.season ?? ''),
                  style: const TextStyle(color: AppColors.emerald, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderSubtle),
          if (_scorers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Hakuna wafungaji waliorekodiwa.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _scorers.length > 8 ? 8 : _scorers.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderSubtle),
              itemBuilder: (context, index) {
                final s = _scorers[index];
                final isTop1 = s.rank == 1;
                final isTop3 = s.rank <= 3;
                final pct = maxGoals > 0 ? (s.goals / maxGoals) : 0.0;

                return Stack(
                  children: [
                    // Visual goal progress bar in background
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: MediaQuery.of(context).size.width * pct * 0.5,
                        color: isTop1
                            ? AppColors.amber.withValues(alpha: 0.08)
                            : AppColors.emerald.withValues(alpha: 0.05),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isTop1
                                  ? AppColors.amberBg
                                  : (isTop3 ? AppColors.surfaceElevated : Colors.transparent),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "${s.rank}",
                              style: TextStyle(
                                color: isTop1 ? AppColors.amber : (isTop3 ? AppColors.textPrimary : AppColors.textMuted),
                                fontSize: 11,
                                fontWeight: isTop3 ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.playerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isTop1 ? AppColors.emerald : AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: isTop3 ? FontWeight.w700 : FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  s.teamName ?? 'Club',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          if (s.penalties > 0)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Text(
                                "(${s.penalties} pen)",
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ),
                          Text(
                            "${s.goals}",
                            style: TextStyle(
                              color: isTop1 ? AppColors.amber : AppColors.emerald,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildClubRecordsSection() {
    List<ClubStatItem> sortedClubs = List.from(_clubs);

    if (_clubStatFilter == 'wins') {
      sortedClubs.sort((a, b) => b.won.compareTo(a.won));
    } else if (_clubStatFilter == 'goals') {
      sortedClubs.sort((a, b) => b.goalsFor.compareTo(a.goalsFor));
    } else if (_clubStatFilter == 'defense') {
      sortedClubs.sort((a, b) => b.cleanSheets.compareTo(a.cleanSheets));
    } else if (_clubStatFilter == 'winRate') {
      sortedClubs.sort((a, b) => b.winRate.compareTo(a.winRate));
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rekodi za Vilabu (Club Leaderboards)',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                // Filter chips: Wins, Goals, Clean Sheets, Win Rate
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildClubFilterChip('Ushindi Mwingi', 'wins'),
                      _buildClubFilterChip('Magoli Mengi', 'goals'),
                      _buildClubFilterChip('Clean Sheets', 'defense'),
                      _buildClubFilterChip('Win Rate %', 'winRate'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderSubtle),
          if (sortedClubs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Hakuna rekodi za vilabu zilizorekodiwa.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedClubs.length > 8 ? 8 : sortedClubs.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderSubtle),
              itemBuilder: (context, index) {
                final c = sortedClubs[index];
                String statValue = "${c.won}";
                if (_clubStatFilter == 'goals') statValue = "${c.goalsFor}";
                if (_clubStatFilter == 'defense') statValue = "${c.cleanSheets}";
                if (_clubStatFilter == 'winRate') statValue = "${c.winRate.toStringAsFixed(1)}%";

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(
                    children: [
                      Text(
                        "${index + 1}.",
                        style: TextStyle(
                          color: index < 3 ? AppColors.amber : AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 0.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          c.teamName.isNotEmpty ? c.teamName[0] : 'C',
                          style: const TextStyle(color: AppColors.emerald, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.teamName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              "${c.played} Mechi • ${c.won}W ${c.drawn}D ${c.lost}L",
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        statValue,
                        style: const TextStyle(
                          color: AppColors.emerald,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildClubFilterChip(String label, String value) {
    final isSelected = _clubStatFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _clubStatFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.emerald : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.emerald : AppColors.borderSubtle,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
