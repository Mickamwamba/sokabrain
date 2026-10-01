import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_strings.dart';
import '../models/match.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/match_card.dart';
import '../widgets/date_selector.dart';
import 'match_detail_screen.dart';
import 'competitions_screen.dart';
import 'league_hub_screen.dart';

class CompetitionMatchGroup {
  final int? id;
  final int? editionId;
  final String name;
  final List<MatchItem> matches;

  CompetitionMatchGroup({
    this.id,
    this.editionId,
    required this.name,
    required this.matches,
  });
}

class MatchesScreen extends StatefulWidget {
  final List<MatchDayItem>? initialDays;
  final List<MatchItem>? initialMatches;
  final String? initialSelectedDate;

  const MatchesScreen({
    super.key,
    this.initialDays,
    this.initialMatches,
    this.initialSelectedDate,
  });

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<MatchDayItem> _matchDays = [];
  String _selectedDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool _isLoading = true;
  List<MatchItem> _matches = [];
  String? _selectedFilter; // null = all, 'LIVE', 'FT', 'UPCOMING'

  @override
  void initState() {
    super.initState();
    if (widget.initialDays != null) {
      _matchDays = widget.initialDays!;
      _selectedDateStr = widget.initialSelectedDate ??
          (_matchDays.isNotEmpty ? _matchDays.first.date : DateFormat('yyyy-MM-dd').format(DateTime.now()));
      _matches = widget.initialMatches ?? [];
      _isLoading = false;
    } else {
      _loadInitialSchedule();
    }
  }

  Future<void> _loadInitialSchedule() async {
    setState(() => _isLoading = true);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final result = await ApiService.fetchMatchDays(around: todayStr, before: 15, after: 25);

    String chosenDate = todayStr;
    if (result.days.isNotEmpty) {
      if (result.days.any((d) => d.date == todayStr)) {
        chosenDate = todayStr;
      } else {
        // Find the closest match day to today among valid match days
        final today = DateTime.now();
        MatchDayItem? closest;
        int minDiff = 999999;
        for (final day in result.days) {
          final dt = day.dateTime;
          if (dt != null) {
            final diff = dt.difference(today).inDays.abs();
            if (diff < minDiff) {
              minDiff = diff;
              closest = day;
            }
          }
        }
        chosenDate = closest?.date ?? result.nearest ?? result.days.first.date;
      }
    }

    if (!mounted) return;
    setState(() {
      _matchDays = result.days;
      _selectedDateStr = chosenDate;
    });

    await _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    final matches = await ApiService.fetchMatches(date: _selectedDateStr);
    if (!mounted) return;
    setState(() {
      _matches = matches;
      _isLoading = false;
    });
  }

  List<MatchItem> get _filteredMatches {
    if (_selectedFilter == null) return _matches;
    if (_selectedFilter == 'LIVE') return _matches.where((m) => m.isLive).toList();
    if (_selectedFilter == 'FT') return _matches.where((m) => m.isFinished).toList();
    if (_selectedFilter == 'UPCOMING') return _matches.where((m) => m.isUpcoming).toList();
    return _matches;
  }

  List<CompetitionMatchGroup> get _groupedMatches {
    final Map<String, CompetitionMatchGroup> groups = {};

    for (final match in _filteredMatches) {
      final compName = match.competition.name ?? 'Unknown Competition';
      final compId = match.competition.id;
      final editionId = match.competition.editionId;
      final key = "${compId ?? compName}";

      if (!groups.containsKey(key)) {
        groups[key] = CompetitionMatchGroup(
          id: compId,
          editionId: editionId,
          name: compName,
          matches: [],
        );
      }
      groups[key]!.matches.add(match);
    }

    return groups.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final liveCount = _matches.where((m) => m.isLive).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.emerald,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'SOKA',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'BRAIN',
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.emoji_events_outlined, size: 20, color: textSecondary),
            tooltip: AppStrings.get('competitions_title'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CompetitionsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, size: 20, color: textSecondary),
            tooltip: AppStrings.get('refresh'),
            onPressed: () {
              _loadInitialSchedule();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Selector (renders only dates with matches)
          DateSelectorBar(
            days: _matchDays,
            selectedDate: _selectedDateStr,
            onDateSelected: (date) {
              if (_selectedDateStr == date) return;
              setState(() => _selectedDateStr = date);
              _loadMatches();
            },
          ),

          // Quick Filter Tabs (All, Live, Finished, Upcoming)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(AppStrings.get('filter_all'), null),
                const SizedBox(width: 8),
                _buildFilterChip(
                  liveCount > 0 ? '${AppStrings.get("filter_live")} ($liveCount)' : AppStrings.get('filter_live'),
                  'LIVE',
                  isLive: liveCount > 0,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(AppStrings.get('filter_finished'), 'FT'),
                const SizedBox(width: 8),
                _buildFilterChip(AppStrings.get('filter_upcoming'), 'UPCOMING'),
              ],
            ),
          ),

          // Matches List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.emerald))
                : _filteredMatches.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: AppColors.emerald,
                        backgroundColor: isDark ? AppColors.surface : AppColors.lightSurface,
                        onRefresh: _loadMatches,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _groupedMatches.length,
                          itemBuilder: (context, compIndex) {
                            final group = _groupedMatches[compIndex];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Clickable Competition Header -> LeagueHubScreen
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 6),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => LeagueHubScreen(
                                              initialCompetitionId: group.id,
                                              initialEditionId: group.editionId,
                                              initialSubTab: 0,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 3,
                                              height: 14,
                                              decoration: BoxDecoration(
                                                color: AppColors.emerald,
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      group.name.toUpperCase(),
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: textPrimary,
                                                        fontSize: 11.5,
                                                        fontWeight: FontWeight.w800,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  const Icon(
                                                    Icons.arrow_forward_ios_rounded,
                                                    color: AppColors.emerald,
                                                    size: 11,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceLight,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isDark ? AppColors.borderSubtle : AppColors.lightBorder,
                                                ),
                                              ),
                                              child: Text(
                                                '${group.matches.length} ${group.matches.length == 1 ? AppStrings.get("match_suffix_single") : AppStrings.get("matches_suffix")}',
                                                style: TextStyle(
                                                  color: isDark ? AppColors.textMuted : AppColors.lightTextSecondary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Match Cards
                                ...group.matches.map(
                                  (m) => MatchCard(
                                    match: m,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MatchDetailScreen(matchId: m.id),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? filterValue, {bool isLive = false}) {
    final isSelected = _selectedFilter == filterValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color chipBg;
    Color borderCol;
    Color textColor;

    if (isSelected) {
      if (isLive) {
        chipBg = AppColors.liveRed;
        borderCol = AppColors.liveRed;
        textColor = Colors.white;
      } else {
        chipBg = isDark ? AppColors.surfaceElevated : const Color(0xFFECFDF5);
        borderCol = AppColors.emerald;
        textColor = isDark ? AppColors.emerald : AppColors.emeraldDark;
      }
    } else {
      chipBg = isDark ? AppColors.surface : AppColors.lightSurface;
      borderCol = isDark ? AppColors.borderSubtle : AppColors.lightBorder;
      textColor = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderCol,
            width: 1,
          ),
          boxShadow: isDark || isSelected
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 48, color: textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              AppStrings.get('no_matches_scheduled'),
              style: TextStyle(
                color: textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.get('no_matches_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(color: textMuted, fontSize: 12),
            ),
            if (_selectedFilter != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _selectedFilter = null),
                child: Text(
                  AppStrings.get('filter_all'),
                  style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
