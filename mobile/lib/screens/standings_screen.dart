import 'package:flutter/material.dart';
import '../models/standings.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  bool _isLoading = true;
  List<LeagueEdition> _editions = [];
  LeagueEdition? _selectedEdition;
  List<StandingsRow> _standings = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final editions = await ApiService.fetchEditions();
    if (!mounted) return;

    final validEditions = editions.where((e) => (e.matchCount ?? 0) > 0).toList();
    final defaultEdition = validEditions.isNotEmpty
        ? validEditions.firstWhere(
            (e) => e.competition.contains('Tanzania') && e.season.contains('2020/2021'),
            orElse: () => validEditions.first,
          )
        : (editions.isNotEmpty ? editions.first : null);

    setState(() {
      _editions = validEditions.isNotEmpty ? validEditions : editions;
      _selectedEdition = defaultEdition;
    });

    if (defaultEdition != null) {
      await _loadStandings(defaultEdition.editionId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('League Tables', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          // Edition Selector
          if (_editions.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: AppColors.surface,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<LeagueEdition>(
                    value: _selectedEdition,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceElevated,
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.emerald),
                    items: _editions.map((ed) {
                      return DropdownMenuItem<LeagueEdition>(
                        value: ed,
                        child: Text(
                          "${ed.competition} (${ed.season})",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (ed) {
                      if (ed != null) {
                        setState(() => _selectedEdition = ed);
                        _loadStandings(ed.editionId);
                      }
                    },
                  ),
                ),
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
                    ? const Center(
                        child: Text(
                          'No standings available for this edition.',
                          style: TextStyle(color: AppColors.textMuted),
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

                            return Container(
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
