import 'package:flutter/material.dart';
import '../models/standings.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'competitions_screen.dart';
import 'team_profile_screen.dart';

class StandingsScreen extends StatefulWidget {
  final int? initialCompetitionId;
  final int? initialEditionId;

  const StandingsScreen({
    super.key,
    this.initialCompetitionId,
    this.initialEditionId,
  });

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  bool _isLoading = true;
  List<CompetitionGroup> _competitions = [];
  CompetitionGroup? _selectedCompetition;
  LeagueEdition? _selectedEdition;
  List<StandingsRow> _standings = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void didUpdateWidget(covariant StandingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCompetitionId != oldWidget.initialCompetitionId ||
        widget.initialEditionId != oldWidget.initialEditionId) {
      _applyInitialSelection();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final editions = await ApiService.fetchEditions();
    if (!mounted) return;

    // Group editions by competition
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

    // Sort: Premier leagues first, then country/name
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

    // 1. If explicit initialEditionId provided
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

    // 2. If initialCompetitionId provided
    if (targetComp == null && widget.initialCompetitionId != null) {
      targetComp = _competitions.where((c) => c.competitionId == widget.initialCompetitionId).firstOrNull;
    }

    // 3. Fallback: Tanzania Premier League or first competition with matches
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
    });

    if (targetEdition != null) {
      _loadStandings(targetEdition.editionId);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStandings(int editionId) async {
    setState(() => _isLoading = true);
    final response = await ApiService.fetchStandings(editionId);
    if (!mounted) return;
    setState(() {
      _standings = response?.standings ?? [];
      _isLoading = false;
    });
  }

  void _onCompetitionChanged(CompetitionGroup comp) {
    if (_selectedCompetition?.competitionId == comp.competitionId) return;

    // Choose best edition for this competition
    final newEdition = comp.editions.isNotEmpty
        ? comp.editions.firstWhere(
            (e) => (e.matchCount ?? 0) > 0,
            orElse: () => comp.editions.first,
          )
        : null;

    setState(() {
      _selectedCompetition = comp;
      _selectedEdition = newEdition;
    });

    if (newEdition != null) {
      _loadStandings(newEdition.editionId);
    } else {
      setState(() {
        _standings = [];
        _isLoading = false;
      });
    }
  }

  void _onSeasonChanged(LeagueEdition edition) {
    if (_selectedEdition?.editionId == edition.editionId) return;
    setState(() => _selectedEdition = edition);
    _loadStandings(edition.editionId);
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
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.92,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    // Sheet Handle
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
                    // Search in Modal
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
        title: const Text('League Tables', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined, color: AppColors.textSecondary),
            tooltip: 'Mashindano Yote',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CompetitionsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20, color: AppColors.textSecondary),
            onPressed: () {
              if (_selectedEdition != null) {
                _loadStandings(_selectedEdition!.editionId);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Step 1: Separate Competition Picker Header
          if (_competitions.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Competition Bar
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
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border, width: 0.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _selectedCompetition?.flagEmoji ?? '🏆',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'COMPETITION',
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
                                    fontSize: 13.5,
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

                  // Step 2: Separate Season Selector Pills
                  if (availableSeasons.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text(
                          'SEASON:',
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
                              children: availableSeasons.map((ed) {
                                final isSelected = ed.editionId == _selectedEdition?.editionId;
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
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

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

          const Divider(height: 1, color: AppColors.border),

          // Standings List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.emerald))
                : _standings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.table_chart_outlined, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'Hakuna msimamo kwa msimu wa ${_selectedEdition?.season ?? ''}.',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.emerald,
                        onRefresh: () => _selectedEdition != null
                            ? _loadStandings(_selectedEdition!.editionId)
                            : Future.value(),
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _standings.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: AppColors.borderSubtle),
                          itemBuilder: (context, index) {
                            final row = _standings[index];
                            final isTopTier = row.position <= 2;
                            final isRelegation = index >= _standings.length - 2;

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TeamProfileScreen(
                                      teamId: row.teamId,
                                      initialTeamName: row.teamName,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                color: index % 2 == 0 ? AppColors.surface : AppColors.surface.withValues(alpha: 0.6),
                              child: Row(
                                children: [
                                  // Position with color bar indicator
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

                                  // Club Name & Initial
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

                                  // Stats Numbers
                                  SizedBox(
                                    width: 26,
                                    child: Text(
                                      "${row.played}",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 26,
                                    child: Text(
                                      "${row.won}",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 26,
                                    child: Text(
                                      "${row.drawn}",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 26,
                                    child: Text(
                                      "${row.lost}",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                  ),
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
                            ),
                          );
                        },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
