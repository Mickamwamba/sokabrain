import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_strings.dart';
import '../models/kijiweni.dart';
import '../services/api_service.dart';
import '../services/fan_profile_service.dart';
import '../theme/app_colors.dart';
import '../widgets/create_thread_sheet.dart';
import '../widgets/share_sheet.dart';
import 'thread_detail_screen.dart';

class KijiweniScreen extends StatefulWidget {
  const KijiweniScreen({super.key});

  @override
  State<KijiweniScreen> createState() => _KijiweniScreenState();
}

class _KijiweniScreenState extends State<KijiweniScreen> {
  bool _isLoading = true;
  List<KijiweSpaceItem> _spaces = [];
  String? _selectedSpaceSlug;
  List<KijiweThreadItem> _threads = [];
  final FanProfileService _fanProfile = FanProfileService();

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    await _fanProfile.init();
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final spaces = await ApiService.fetchKijiweniSpaces();
    final threads = await ApiService.fetchKijiweniThreads(spaceSlug: _selectedSpaceSlug);
    if (!mounted) return;
    setState(() {
      _spaces = spaces;
      _threads = threads;
      _isLoading = false;
    });
  }

  Future<void> _filterBySpace(String? slug) async {
    setState(() {
      _selectedSpaceSlug = slug;
      _isLoading = true;
    });
    final threads = await ApiService.fetchKijiweniThreads(spaceSlug: slug);
    if (!mounted) return;
    setState(() {
      _threads = threads;
      _isLoading = false;
    });
  }

  Future<void> _toggleThreadLike(KijiweThreadItem thread) async {
    final isLiked = _fanProfile.isThreadLiked(thread.id);
    final nextLiked = !isLiked;
    final nextCount = nextLiked ? (thread.likesCount + 1) : (thread.likesCount > 0 ? thread.likesCount - 1 : 0);

    // Optimistic UI update
    await _fanProfile.setThreadLiked(thread.id, nextLiked);
    setState(() {
      final index = _threads.indexWhere((t) => t.id == thread.id);
      if (index != -1) {
        _threads[index] = thread.copyWith(likesCount: nextCount);
      }
    });

    final res = await ApiService.likeThread(thread.id, fanFingerprint: _fanProfile.fingerprint);
    if (!mounted) return;

    if (res != null) {
      final serverLiked = res['liked'] as bool? ?? nextLiked;
      final serverCount = res['likesCount'] as int? ?? nextCount;
      await _fanProfile.setThreadLiked(thread.id, serverLiked);
      setState(() {
        final index = _threads.indexWhere((t) => t.id == thread.id);
        if (index != -1) {
          _threads[index] = thread.copyWith(likesCount: serverCount);
        }
      });
    } else {
      // Revert if error
      await _fanProfile.setThreadLiked(thread.id, isLiked);
      setState(() {
        final index = _threads.indexWhere((t) => t.id == thread.id);
        if (index != -1) {
          _threads[index] = thread;
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imeshindwa kubadili like. Jaribu tena.'),
          backgroundColor: AppColors.liveRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final borderCol = isDark ? AppColors.borderSubtle : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.emerald,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'KIJIWENI',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'SOKA',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              AppStrings.get('kijiweni_subtitle'),
              style: TextStyle(color: textMuted, fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 20, color: textSecondary),
            tooltip: AppStrings.get('refresh'),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.emerald,
        elevation: 4,
        onPressed: () async {
          final created = await CreateThreadSheet.show(
            context,
            spaces: _spaces,
            initialSpaceSlug: _selectedSpaceSlug,
          );
          if (created == true) {
            _loadData();
          }
        },
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
      ),
      body: Column(
        children: [
          // Spaces Horizontal Bar
          if (_spaces.isNotEmpty)
            Container(
              height: 54,
              color: bg,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _buildSpaceChip('All Spaces', null, null, isDark),
                  ..._spaces.map((s) => _buildSpaceChip(s.nameSw, s.slug, s.icon, isDark)),
                ],
              ),
            ),

          Divider(height: 1, color: borderCol),

          // Threads Feed
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.emerald))
                : _threads.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.forum_outlined, size: 48, color: textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'Hakuna mada zilizopatikana kwenye kijiwe hiki.',
                              style: TextStyle(color: textMuted, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? AppColors.surfaceElevated : const Color(0xFFECFDF5),
                                foregroundColor: AppColors.emeraldDark,
                                side: const BorderSide(color: AppColors.emerald),
                              ),
                              onPressed: () async {
                                final created = await CreateThreadSheet.show(
                                  context,
                                  spaces: _spaces,
                                  initialSpaceSlug: _selectedSpaceSlug,
                                );
                                if (created == true) _loadData();
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: Text(AppStrings.get('new_thread')),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.emerald,
                        backgroundColor: isDark ? AppColors.surface : Colors.white,
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
                          itemCount: _threads.length,
                          itemBuilder: (context, index) {
                            final thread = _threads[index];
                            return _buildThreadCard(thread, isDark);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceChip(String title, String? slug, String? icon, bool isDark) {
    final isSelected = _selectedSpaceSlug == slug;
    final chipBg = isSelected
        ? AppColors.emerald
        : (isDark ? AppColors.surface : Colors.white);
    final borderCol = isSelected
        ? AppColors.emerald
        : (isDark ? AppColors.borderSubtle : AppColors.lightBorder);
    final textColor = isSelected
        ? Colors.black
        : (isDark ? AppColors.textPrimary : AppColors.lightTextPrimary);

    return GestureDetector(
      onTap: () => _filterBySpace(slug),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Text(icon, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadCard(KijiweThreadItem thread, bool isDark) {
    final isLiked = _fanProfile.isThreadLiked(thread.id);
    final cardBg = isDark ? AppColors.surface : Colors.white;
    final borderCol = isDark ? AppColors.borderSubtle : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final avatarBg = isDark ? AppColors.surfaceElevated : const Color(0xFFECFDF5);
    final tagBg = isDark ? AppColors.surfaceElevated : const Color(0xFFFEF3C7);

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
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ThreadDetailScreen(threadId: thread.id),
            ),
          ).then((_) {
            _loadData();
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author and Tag Row
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: avatarBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.border : AppColors.emerald.withValues(alpha: 0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      thread.authorName.isNotEmpty ? thread.authorName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppColors.emerald,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          thread.authorName,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (thread.authorTeamName != null && thread.authorTeamName!.isNotEmpty)
                          Text(
                            thread.authorTeamName!,
                            style: const TextStyle(
                              color: AppColors.emerald,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (thread.tag != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        thread.tag!,
                        style: const TextStyle(
                          color: AppColors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // Title
              Text(
                thread.title,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 6),

              // Content snippet
              Text(
                thread.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 12),

              // Bottom Actions Row: Likes, Comments, Share, Date
              Row(
                children: [
                  // Like action
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _toggleThreadLike(thread),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                            size: 15,
                            color: isLiked ? AppColors.emerald : textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${thread.likesCount}",
                            style: TextStyle(
                              color: isLiked ? AppColors.emerald : textMuted,
                              fontSize: 11.5,
                              fontWeight: isLiked ? FontWeight.w800 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Comments count
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 15, color: textMuted),
                      const SizedBox(width: 4),
                      Text(
                        "${thread.commentsCount}",
                        style: TextStyle(color: textMuted, fontSize: 11.5, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Share action
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      ShareSheet.show(context, thread);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, size: 15, color: textMuted),
                          const SizedBox(width: 4),
                          Text(
                            AppStrings.get('share'),
                            style: TextStyle(color: textMuted, fontSize: 11.5, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Created time
                  if (thread.createdAt != null)
                    Text(
                      DateFormat('d MMM, HH:mm').format(thread.createdAt!.toLocal()),
                      style: TextStyle(color: textMuted.withValues(alpha: 0.8), fontSize: 10.5),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
