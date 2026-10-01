import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/match_detail.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/live_badge.dart';
import 'team_profile_screen.dart';

class MatchDetailScreen extends StatefulWidget {
  final int matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  bool _isLoading = true;
  MatchDetailItem? _match;

  @override
  void initState() {
    super.initState();
    _loadMatch();
  }

  Future<void> _loadMatch() async {
    setState(() => _isLoading = true);
    final match = await ApiService.fetchMatchDetail(widget.matchId);
    if (!mounted) return;
    setState(() {
      _match = match;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        title: Text(
          _match?.competitionName ?? 'Match Center',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 20, color: textPrimary),
            onPressed: _loadMatch,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.emerald))
          : _match == null
              ? Center(child: Text('Match not found', style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.lightTextMuted)))
              : RefreshIndicator(
                  color: AppColors.emerald,
                  onRefresh: _loadMatch,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      // Scoreboard Header
                      _buildScoreboard(_match!, isDark),

                      // Timeline Events
                      _buildTimelineSection(_match!, isDark),

                      // Head to Head Summary
                      if (_match!.headToHead != null && _match!.headToHead!.played > 0)
                        _buildHeadToHeadSection(_match!, isDark),
                    ],
                  ),
                ),
    );
  }

  Widget _buildScoreboard(MatchDetailItem m, bool isDark) {
    final cardBg = isDark ? AppColors.surface : Colors.white;
    final borderCol = isDark ? AppColors.border : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final badgeBg = isDark ? AppColors.surfaceLight : AppColors.lightSurfaceLight;
    final avatarBg = isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated;

    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: isDark ? null : const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Competition & Round
          if (m.season != null || m.round != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                [
                  if (m.season != null) m.season,
                  if (m.round != null) "Round ${m.round}",
                ].join(' • '),
                style: TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // Teams & Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Home Team
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeamProfileScreen(
                          teamId: m.homeTeamId,
                          initialTeamName: m.homeTeamName,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: avatarBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3), width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          m.homeTeamName.isNotEmpty ? m.homeTeamName[0] : 'H',
                          style: const TextStyle(
                            color: AppColors.emerald,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m.homeTeamName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Score Center
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    if (m.homeScore != null && m.awayScore != null)
                      Text(
                        "${m.homeScore} - ${m.awayScore}",
                        style: TextStyle(
                          color: m.isLive ? AppColors.liveRed : textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      )
                    else if (m.kickoffAt != null)
                      Text(
                        DateFormat('HH:mm').format(m.kickoffAt!.toLocal()),
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    else
                      Text(
                        "- : -",
                        style: TextStyle(color: textMuted, fontSize: 22),
                      ),
                    const SizedBox(height: 6),
                    if (m.isLive)
                      LiveBadge(minute: m.liveMinute, status: m.status)
                    else if (m.isFinished)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'FULL TIME',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    else if (m.kickoffAt != null)
                      Text(
                        DateFormat('d MMM yyyy').format(m.kickoffAt!.toLocal()),
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),

              // Away Team
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeamProfileScreen(
                          teamId: m.awayTeamId,
                          initialTeamName: m.awayTeamName,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: avatarBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3), width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          m.awayTeamName.isNotEmpty ? m.awayTeamName[0] : 'A',
                          style: const TextStyle(
                            color: AppColors.emerald,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m.awayTeamName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Venue
          if (m.venue != null && m.venue!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: textMuted),
                const SizedBox(width: 4),
                Text(
                  m.venue!,
                  style: TextStyle(color: textMuted, fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineSection(MatchDetailItem m, bool isDark) {
    final events = m.events;
    final cardBg = isDark ? AppColors.surface : Colors.white;
    final borderCol = isDark ? AppColors.border : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final badgeBg = isDark ? AppColors.surfaceLight : AppColors.lightSurfaceLight;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: isDark ? null : const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MATCH TIMELINE',
            style: TextStyle(
              color: textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No match events recorded yet.',
                  style: TextStyle(color: textMuted, fontSize: 12),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (_, __) => Divider(height: 16, color: isDark ? AppColors.borderSubtle : AppColors.lightBorder),
              itemBuilder: (context, index) {
                final ev = events[index];
                final isHome = ev.side != null
                    ? ev.isHomeSide
                    : (ev.teamId != null && ev.teamId == m.homeTeamId);

                return Row(
                  children: [
                    // Home Side Event
                    Expanded(
                      child: isHome
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Text(
                                    ev.playerName ?? 'Goal',
                                    textAlign: TextAlign.end,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (ev.isOwnGoal) ...[
                                  const SizedBox(width: 4),
                                  const Text(
                                    '(O.G)',
                                    style: TextStyle(
                                      color: AppColors.liveRed,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ] else if (ev.isPenalty) ...[
                                  const SizedBox(width: 4),
                                  const Text(
                                    '(pen)',
                                    style: TextStyle(
                                      color: AppColors.emerald,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                _buildEventIcon(ev),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),

                    // Minute Badge in Center
                    Container(
                      width: 48,
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          ev.displayMinute,
                          style: const TextStyle(
                            color: AppColors.emerald,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    // Away Side Event
                    Expanded(
                      child: !isHome
                          ? Row(
                              children: [
                                _buildEventIcon(ev),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    ev.playerName ?? 'Goal',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (ev.isOwnGoal) ...[
                                  const SizedBox(width: 4),
                                  const Text(
                                    '(O.G)',
                                    style: TextStyle(
                                      color: AppColors.liveRed,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ] else if (ev.isPenalty) ...[
                                  const SizedBox(width: 4),
                                  const Text(
                                    '(pen)',
                                    style: TextStyle(
                                      color: AppColors.emerald,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEventIcon(MatchEventItem ev) {
    if (ev.isGoal || ev.isOwnGoal) {
      return Text(
        '⚽',
        style: TextStyle(
          fontSize: 13,
          color: ev.isOwnGoal ? AppColors.liveRed : null,
        ),
      );
    }
    if (ev.isRedCard) {
      return Container(
        width: 10,
        height: 14,
        decoration: BoxDecoration(
          color: AppColors.liveRed,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    if (ev.isCard) {
      return Container(
        width: 10,
        height: 14,
        decoration: BoxDecoration(
          color: AppColors.amber,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    return const Icon(Icons.star, size: 14, color: AppColors.textMuted);
  }

  Widget _buildHeadToHeadSection(MatchDetailItem m, bool isDark) {
    final h2h = m.headToHead!;
    final cardBg = isDark ? AppColors.surface : Colors.white;
    final borderCol = isDark ? AppColors.border : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: isDark ? null : const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HEAD TO HEAD',
            style: TextStyle(
              color: textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatMetric(m.homeTeamShortName ?? m.homeTeamName, "${h2h.homeWins} Wins", textPrimary, textMuted),
              _buildStatMetric("Draws", "${h2h.draws}", textPrimary, textMuted),
              _buildStatMetric(m.awayTeamShortName ?? m.awayTeamName, "${h2h.awayWins} Wins", textPrimary, textMuted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric(String label, String value, Color textPrimary, Color textMuted) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: textMuted, fontSize: 11),
        ),
      ],
    );
  }
}
