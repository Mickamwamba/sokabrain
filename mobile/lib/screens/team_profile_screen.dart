import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/match.dart';
import '../models/team_profile.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'match_detail_screen.dart';

class TeamProfileScreen extends StatefulWidget {
  final int teamId;
  final String? initialTeamName;
  final TeamProfileData? initialProfile;

  const TeamProfileScreen({
    super.key,
    required this.teamId,
    this.initialTeamName,
    this.initialProfile,
  });

  @override
  State<TeamProfileScreen> createState() => _TeamProfileScreenState();
}

class _TeamProfileScreenState extends State<TeamProfileScreen> with SingleTickerProviderStateMixin {
  late bool _isLoading;
  TeamProfileData? _profile;
  List<MatchItem> _upcomingMatches = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _profile = widget.initialProfile;
    _isLoading = widget.initialProfile == null;
    if (widget.initialProfile == null) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ApiService.fetchTeamProfile(widget.teamId),
      ApiService.fetchTeamUpcomingMatches(widget.teamId, limit: 5),
    ]);

    if (!mounted) return;
    setState(() {
      _profile = results[0] as TeamProfileData?;
      _upcomingMatches = results[1] as List<MatchItem>;
      _isLoading = false;
    });
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg => _isDark ? AppColors.surface : Colors.white;
  Color get _cardElevated => _isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated;
  Color get _borderColor => _isDark ? AppColors.borderSubtle : AppColors.lightBorder;
  Color get _textPrimary => _isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
  Color get _textSecondary => _isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
  Color get _textMuted => _isDark ? AppColors.textMuted : AppColors.lightTextMuted;

  @override
  Widget build(BuildContext context) {
    final title = _profile?.team.name ?? widget.initialTeamName ?? 'Team Profile';

    return Scaffold(
      backgroundColor: _isDark ? AppColors.background : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.emerald))
          : _profile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, size: 48, color: _textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'Taarifa za timu hazikupatikana.',
                        style: TextStyle(color: _textMuted, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _cardElevated,
                          foregroundColor: AppColors.emerald,
                        ),
                        onPressed: _loadData,
                        child: const Text('Jaribu Tena'),
                      ),
                    ],
                  ),
                )
              : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header banner
                            _buildTeamHeader(_profile!),
                            const SizedBox(height: 14),

                            // 6 Stat Tiles Grid
                            _buildStatGrid(_profile!),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _TabBarDelegate(
                          TabBar(
                            controller: _tabController,
                            indicatorColor: AppColors.emerald,
                            indicatorWeight: 3,
                            labelColor: AppColors.emerald,
                            unselectedLabelColor: _textMuted,
                            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            tabs: const [
                              Tab(text: 'Ujumla (Overview)'),
                              Tab(text: 'Wafungaji (Scorers)'),
                              Tab(text: 'Historia (Seasons)'),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(_profile!),
                      _buildScorersTab(_profile!),
                      _buildSeasonsTab(_profile!),
                    ],
                  ),
                ),
    );
  }

  // 1. HEADER SECTION
  Widget _buildTeamHeader(TeamProfileData p) {
    final team = p.team;
    final totalTitles = p.totalTitles;
    final country = team.country?.replaceAll(', United Republic of', '') ?? '';
    final identity = [
      team.type == 'NATIONAL' ? 'National team' : 'Club',
      if (country.isNotEmpty) country,
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team Crest Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _cardElevated,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: totalTitles > 0 ? AppColors.amber : AppColors.emerald.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                  style: TextStyle(
                    color: totalTitles > 0 ? AppColors.amber : AppColors.emerald,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name & Identity
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            team.name,
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (totalTitles > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.amberBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🏆', style: TextStyle(fontSize: 11)),
                                const SizedBox(width: 4),
                                Text(
                                  '$totalTitles ${totalTitles == 1 ? 'Title' : 'Titles'}',
                                  style: const TextStyle(
                                    color: AppColors.amber,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      identity,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (team.stadium != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.stadium_outlined, size: 13, color: _textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${team.stadium!.name}${team.stadium!.city != null ? ', ${team.stadium!.city}' : ''}${team.stadium!.capacity != null ? ' (${NumberFormat('#,###').format(team.stadium!.capacity)} cap)' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: _textMuted, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Recent Form Pills
          if (p.form.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(color: _borderColor, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'RECENT FORM:',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: p.form.take(6).map((f) {
                      final isWin = f.result == 'W';
                      final isDraw = f.result == 'D';
                      final bg = isWin
                          ? AppColors.emerald
                          : (isDraw ? AppColors.amber : AppColors.liveRed);
                      final textCol = isDraw ? Colors.black : Colors.white;

                      return Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          f.result,
                          style: TextStyle(
                            color: textCol,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 2. STATS GRID SECTION
  Widget _buildStatGrid(TeamProfileData p) {
    final r = p.record;
    final totalTitles = p.totalTitles;
    final seasonsCount = p.seasons.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  figure: '${r.played}',
                  label: 'PLAYED',
                  sub: '$seasonsCount seasons on record',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatTile(
                  figure: '${r.won}',
                  label: 'WON',
                  sub: '${r.drawn} drawn • ${r.lost} lost',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatTile(
                  figure: '${r.winRate}%',
                  label: 'WIN RATE',
                  sub: 'all competitions',
                  highlight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  figure: '${r.goalsFor}',
                  label: 'GOALS',
                  sub: '${r.goalsAgainst} conceded (${r.goalsPerGame}/g)',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatTile(
                  figure: '${r.cleanSheets}',
                  label: 'CLEAN SHEETS',
                  sub: '${(r.cleanSheets * 100 / (r.played > 0 ? r.played : 1)).round()}% of matches',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatTile(
                  figure: '$totalTitles',
                  label: totalTitles == 1 ? 'TITLE' : 'TITLES',
                  sub: totalTitles > 0 ? 'trophy count' : 'none on record',
                  gold: totalTitles > 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required String figure,
    required String label,
    required String sub,
    bool highlight = false,
    bool gold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: gold ? AppColors.amber.withValues(alpha: 0.3) : _borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            figure,
            style: TextStyle(
              color: gold
                  ? AppColors.amber
                  : (highlight ? AppColors.emerald : _textPrimary),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: _textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // 3. TAB 1: OVERVIEW (RESULTS, UPCOMING, MILESTONES)
  Widget _buildOverviewTab(TeamProfileData p) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      children: [
        // Milestone Cards: Biggest Win & Heaviest Defeat
        if (p.biggestWin != null || p.heaviestDefeat != null) ...[
          Row(
            children: [
              if (p.biggestWin != null)
                Expanded(
                  child: _buildMilestoneCard(
                    title: 'BIGGEST WIN',
                    m: p.biggestWin!,
                    isWin: true,
                  ),
                ),
              if (p.biggestWin != null && p.heaviestDefeat != null) const SizedBox(width: 10),
              if (p.heaviestDefeat != null)
                Expanded(
                  child: _buildMilestoneCard(
                    title: 'HEAVIEST DEFEAT',
                    m: p.heaviestDefeat!,
                    isWin: false,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Upcoming Fixtures
        if (_upcomingMatches.isNotEmpty) ...[
          _buildSectionHeader(
            icon: Icons.calendar_today_rounded,
            title: 'MECHI ZIJAZO (UPCOMING FIXTURES)',
            hint: '${_upcomingMatches.length} zilizopangwa',
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _upcomingMatches.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: _borderColor),
              itemBuilder: (context, i) => _buildUpcomingRow(_upcomingMatches[i]),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Recent Results
        if (p.form.isNotEmpty) ...[
          _buildSectionHeader(
            icon: Icons.history_rounded,
            title: 'MATOKEO YA HIVI KARIBUNI (RECENT RESULTS)',
            hint: 'Mechi za mwisho',
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: p.form.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: _borderColor),
              itemBuilder: (context, i) => _buildResultRow(p.form[i]),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title, String? hint}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.emerald),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (hint != null)
          Text(
            hint,
            style: TextStyle(color: _textMuted, fontSize: 10),
          ),
      ],
    );
  }

  Widget _buildMilestoneCard({required String title, required TeamFormMatch m, required bool isWin}) {
    final borderCol = isWin ? AppColors.emerald : AppColors.liveRed;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MatchDetailScreen(matchId: m.matchId)),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _borderColor),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  color: borderCol,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: borderCol,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${m.goalsFor} - ${m.goalsAgainst}',
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${m.home ? 'vs' : 'at'} ${m.opponent}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${m.competition} (${m.season})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(TeamFormMatch m) {
    final isWin = m.result == 'W';
    final isDraw = m.result == 'D';
    final badgeBg = isWin ? AppColors.emerald : (isDraw ? AppColors.amber : AppColors.liveRed);
    final badgeTextColor = isDraw ? Colors.black : Colors.white;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MatchDetailScreen(matchId: m.matchId)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            // Result pill
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                m.result,
                style: TextStyle(
                  color: badgeTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Opponent & Match metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: m.home ? 'vs ' : 'at ',
                          style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: m.opponent,
                          style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${m.kickoffAt != null ? DateFormat('d MMM yyyy').format(m.kickoffAt!.toLocal()) : '—'} • ${m.competition}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),

            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _cardElevated,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${m.goalsFor} - ${m.goalsAgainst}',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingRow(MatchItem m) {
    final isHome = m.homeTeam.id == widget.teamId;
    final opponent = isHome ? m.awayTeam : m.homeTeam;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MatchDetailScreen(matchId: m.id)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _cardElevated,
                shape: BoxShape.circle,
                border: Border.all(color: _borderColor),
              ),
              alignment: Alignment.center,
              child: Text(
                opponent.name.isNotEmpty ? opponent.name[0].toUpperCase() : 'O',
                style: const TextStyle(color: AppColors.emerald, fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: isHome ? 'vs ' : 'at ',
                          style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: opponent.name,
                          style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${m.competition.name}${m.round != null && m.round!.isNotEmpty ? ' • Round ${m.round}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (m.kickoffAt != null) ...[
                  Text(
                    DateFormat('d MMM').format(m.kickoffAt!.toLocal()),
                    style: TextStyle(color: _textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    DateFormat('HH:mm').format(m.kickoffAt!.toLocal()),
                    style: const TextStyle(color: AppColors.emerald, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ] else
                  Text('TBD', style: TextStyle(color: _textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 4. TAB 2: TOP SCORERS
  Widget _buildScorersTab(TeamProfileData p) {
    if (p.topScorers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 40, color: _textMuted),
            const SizedBox(height: 10),
            Text(
              'Hakuna takwimu za wafungaji wa ${p.team.name} kwenye kumbukumbu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: p.topScorers.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: _borderColor),
      itemBuilder: (context, i) {
        final scorer = p.topScorers[i];
        final rank = i + 1;
        final isTop3 = rank <= 3;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: i % 2 == 0 ? _cardBg : (_isDark ? AppColors.surface.withValues(alpha: 0.6) : const Color(0xFFF8FAFC)),
            borderRadius: i == 0
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : (i == p.topScorers.length - 1 ? const BorderRadius.vertical(bottom: Radius.circular(12)) : null),
          ),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isTop3 ? AppColors.amberBg : _cardElevated,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: isTop3 ? AppColors.amber : _textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scorer.playerName,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (scorer.position != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        scorer.position!,
                        style: const TextStyle(color: AppColors.emerald, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),

              // Assists (if any)
              if (scorer.assists != null && scorer.assists! > 0) ...[
                Text(
                  '${scorer.assists} ast',
                  style: TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 14),
              ],

              // Goals Count
              Container(
                constraints: const BoxConstraints(minWidth: 32),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isTop3 ? AppColors.emeraldDark : _cardElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${scorer.goals}',
                  style: TextStyle(
                    color: isTop3 ? AppColors.emerald : _textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 5. TAB 3: SEASONS HISTORICAL TABLE
  Widget _buildSeasonsTab(TeamProfileData p) {
    if (p.seasons.isEmpty) {
      return Center(
        child: Text(
          'Hakuna rekodi za misimu zilizopatikana.',
          style: TextStyle(color: _textMuted, fontSize: 13),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            horizontalMargin: 12,
            columnSpacing: 14,
            headingRowHeight: 40,
            dataRowMinHeight: 40,
            dataRowMaxHeight: 44,
            headingRowColor: WidgetStateProperty.all(_cardElevated),
            columns: [
              DataColumn(label: Text('SEASON', style: TextStyle(color: _textMuted, fontSize: 10, fontWeight: FontWeight.w800))),
              DataColumn(label: Text('COMPETITION', style: TextStyle(color: _textMuted, fontSize: 10, fontWeight: FontWeight.w800))),
              DataColumn(label: Text('P', style: TextStyle(color: _textMuted, fontSize: 10, fontWeight: FontWeight.w800))),
              DataColumn(label: Text('W', style: TextStyle(color: _textMuted, fontSize: 10, fontWeight: FontWeight.w800))),
              DataColumn(label: Text('D', style: TextStyle(color: _textMuted, fontSize: 10, fontWeight: FontWeight.w800))),
              DataColumn(label: Text('L', style: TextStyle(color: _textMuted, fontSize: 10, fontWeight: FontWeight.w800))),
              DataColumn(label: Text('GD', style: TextStyle(color: _textMuted, fontSize: 10, fontWeight: FontWeight.w800))),
              DataColumn(label: Text('PTS', style: TextStyle(color: _textMuted, fontSize: 10, fontWeight: FontWeight.w800))),
              DataColumn(label: Text('FINISH', style: TextStyle(color: _textMuted, fontSize: 10, fontWeight: FontWeight.w800))),
            ],
            rows: p.seasons.map((s) {
              final isChampion = s.champion == true;

              return DataRow(
                color: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (isChampion) return AppColors.amberBg.withValues(alpha: 0.2);
                  return null;
                }),
                cells: [
                  DataCell(Text(s.season, style: TextStyle(color: _textPrimary, fontSize: 12, fontWeight: FontWeight.w700))),
                  DataCell(Text(s.competition, style: TextStyle(color: _textSecondary, fontSize: 12))),
                  DataCell(Text('${s.played}', style: TextStyle(color: _textMuted, fontSize: 12))),
                  DataCell(Text('${s.won}', style: TextStyle(color: _textMuted, fontSize: 12))),
                  DataCell(Text('${s.drawn}', style: TextStyle(color: _textMuted, fontSize: 12))),
                  DataCell(Text('${s.lost}', style: TextStyle(color: _textMuted, fontSize: 12))),
                  DataCell(
                    Text(
                      s.goalDifference > 0 ? '+${s.goalDifference}' : '${s.goalDifference}',
                      style: TextStyle(
                        color: s.goalDifference > 0 ? AppColors.emerald : (s.goalDifference < 0 ? AppColors.liveRed : _textMuted),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      s.competitionType == 'LEAGUE' ? '${s.points}' : '—',
                      style: TextStyle(color: _textPrimary, fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                  ),
                  DataCell(
                    isChampion
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.amberBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '🏆 Champions',
                              style: TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w900),
                            ),
                          )
                        : Text(
                            s.finishText,
                            style: TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.background : AppColors.lightBackground,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
