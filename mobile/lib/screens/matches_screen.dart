import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/match.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/match_card.dart';
import '../widgets/date_selector.dart';
import 'match_detail_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  List<MatchItem> _matches = [];
  String? _selectedFilter; // null = all, 'LIVE', 'FT', 'UPCOMING'

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final matches = await ApiService.fetchMatches(date: dateStr);
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

  // Group by competition
  Map<String, List<MatchItem>> get _groupedMatches {
    final map = <String, List<MatchItem>>{};
    for (final m in _filteredMatches) {
      final compName = m.competition.name ?? 'Other Competitions';
      map.putIfAbsent(compName, () => []).add(m);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final liveCount = _matches.where((m) => m.isLive).length;

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
            const Text(
              'BRAIN',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20, color: AppColors.textSecondary),
            onPressed: _loadMatches,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Selector
          DateSelectorBar(
            selectedDate: _selectedDate,
            onDateSelected: (date) {
              setState(() => _selectedDate = date);
              _loadMatches();
            },
          ),

          // Quick Filter Tabs (All, Live, Finished, Upcoming)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', null),
                const SizedBox(width: 8),
                _buildFilterChip(
                  liveCount > 0 ? 'Live ($liveCount)' : 'Live',
                  'LIVE',
                  isLive: liveCount > 0,
                ),
                const SizedBox(width: 8),
                _buildFilterChip('Finished', 'FT'),
                const SizedBox(width: 8),
                _buildFilterChip('Upcoming', 'UPCOMING'),
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
                        backgroundColor: AppColors.surface,
                        onRefresh: _loadMatches,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _groupedMatches.keys.length,
                          itemBuilder: (context, compIndex) {
                            final compName = _groupedMatches.keys.elementAt(compIndex);
                            final compMatches = _groupedMatches[compName]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Competition Header
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
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
                                        child: Text(
                                          compName.toUpperCase(),
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Match Cards
                                ...compMatches.map(
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
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isLive ? AppColors.liveRed : AppColors.surfaceElevated)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isLive ? AppColors.liveRed : AppColors.emerald)
                : AppColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isLive ? Colors.white : AppColors.emerald)
                : AppColors.textMuted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text(
            'Hakuna Mechi Zilizopangwa',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chagua tarehe nyingine au rudi baadaye.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
