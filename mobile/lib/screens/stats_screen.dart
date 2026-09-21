import 'package:flutter/material.dart';
import '../models/standings.dart';
import '../models/stats.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  List<LeagueEdition> _editions = [];
  LeagueEdition? _selectedEdition;
  List<TopScorerItem> _scorers = [];

  @override
  void initState() {
    super.initState();
    _loadEditions();
  }

  Future<void> _loadEditions() async {
    setState(() => _isLoading = true);
    final editions = await ApiService.fetchEditions();
    if (!mounted) return;

    final validEditions = editions.where((e) => (e.matchCount ?? 0) > 0).toList();
    final defaultEdition = validEditions.isNotEmpty
        ? validEditions.firstWhere(
            (e) => e.competition.contains('Tanzania') && e.season.contains('2018/2019'),
            orElse: () => validEditions.first,
          )
        : (editions.isNotEmpty ? editions.first : null);

    setState(() {
      _editions = validEditions.isNotEmpty ? validEditions : editions;
      _selectedEdition = defaultEdition;
    });

    if (defaultEdition != null) {
      await _loadScorers(defaultEdition.editionId);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadScorers(int editionId) async {
    setState(() => _isLoading = true);
    final scorers = await ApiService.fetchTopScorers(editionId, limit: 30);
    if (!mounted) return;
    setState(() {
      _scorers = scorers;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Scorers & Stats', style: TextStyle(fontWeight: FontWeight.w800)),
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
                        _loadScorers(ed.editionId);
                      }
                    },
                  ),
                ),
              ),
            ),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.background,
            child: const Row(
              children: [
                SizedBox(width: 36, child: Text('RANK', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
                Expanded(child: Text('PLAYER & CLUB', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
                SizedBox(width: 44, child: Text('PENS', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700))),
                SizedBox(width: 44, child: Text('GOALS', textAlign: TextAlign.center, style: TextStyle(color: AppColors.emerald, fontSize: 11, fontWeight: FontWeight.w800))),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Scorers List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.emerald))
                : _scorers.isEmpty
                    ? const Center(
                        child: Text(
                          'No goalscorer records available for this edition.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.emerald,
                        onRefresh: () => _selectedEdition != null
                            ? _loadScorers(_selectedEdition!.editionId)
                            : Future.value(),
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _scorers.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: AppColors.borderSubtle),
                          itemBuilder: (context, index) {
                            final s = _scorers[index];
                            final isTop1 = s.rank == 1;
                            final isTop3 = s.rank <= 3;

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              color: index % 2 == 0 ? AppColors.surface : AppColors.surface.withValues(alpha: 0.6),
                              child: Row(
                                children: [
                                  // Rank badge
                                  SizedBox(
                                    width: 36,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isTop1
                                            ? AppColors.amberBg
                                            : (isTop3 ? AppColors.surfaceLight : Colors.transparent),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        "${s.rank}",
                                        style: TextStyle(
                                          color: isTop1
                                              ? AppColors.amber
                                              : (isTop3 ? AppColors.textPrimary : AppColors.textMuted),
                                          fontSize: 12,
                                          fontWeight: isTop3 ? FontWeight.w800 : FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Player & Club
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
                                            fontSize: 13.5,
                                            fontWeight: isTop3 ? FontWeight.w700 : FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          s.teamName ?? 'Club',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Penalties
                                  SizedBox(
                                    width: 44,
                                    child: Text(
                                      "${s.penalties}",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                    ),
                                  ),

                                  // Goals
                                  SizedBox(
                                    width: 44,
                                    child: Text(
                                      "${s.goals}",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isTop1 ? AppColors.amber : AppColors.emerald,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
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
