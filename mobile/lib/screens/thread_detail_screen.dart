import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/kijiweni.dart';
import '../services/api_service.dart';
import '../services/fan_profile_service.dart';
import '../theme/app_colors.dart';
import '../widgets/share_sheet.dart';

class ThreadDetailScreen extends StatefulWidget {
  final int threadId;

  const ThreadDetailScreen({super.key, required this.threadId});

  @override
  State<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<ThreadDetailScreen> {
  bool _isLoading = true;
  KijiweThreadDetailItem? _detail;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FanProfileService _fanProfile = FanProfileService();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initAndLoad() async {
    await _fanProfile.init();
    await _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    final detail = await ApiService.fetchKijiweniThreadDetail(widget.threadId);
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _isLoading = false;
    });
  }

  Future<void> _toggleThreadLike() async {
    if (_detail == null) return;
    final thread = _detail!.thread;
    final isLiked = _fanProfile.isThreadLiked(thread.id);
    final nextLiked = !isLiked;
    final nextCount = nextLiked ? (thread.likesCount + 1) : (thread.likesCount > 0 ? thread.likesCount - 1 : 0);

    await _fanProfile.setThreadLiked(thread.id, nextLiked);
    setState(() {
      _detail = KijiweThreadDetailItem(
        thread: thread.copyWith(likesCount: nextCount),
        comments: _detail!.comments,
      );
    });

    final res = await ApiService.likeThread(thread.id, fanFingerprint: _fanProfile.fingerprint);
    if (!mounted) return;

    if (res != null) {
      final serverLiked = res['liked'] as bool? ?? nextLiked;
      final serverCount = res['likesCount'] as int? ?? nextCount;
      await _fanProfile.setThreadLiked(thread.id, serverLiked);
      setState(() {
        _detail = KijiweThreadDetailItem(
          thread: thread.copyWith(likesCount: serverCount),
          comments: _detail!.comments,
        );
      });
    } else {
      // Revert on error
      await _fanProfile.setThreadLiked(thread.id, isLiked);
      setState(() {
        _detail = KijiweThreadDetailItem(
          thread: thread,
          comments: _detail!.comments,
        );
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

  Future<void> _toggleCommentLike(KijiweCommentItem comment) async {
    if (_detail == null) return;
    final isLiked = _fanProfile.isCommentLiked(comment.id);
    final nextLiked = !isLiked;
    final nextCount = nextLiked ? (comment.likesCount + 1) : (comment.likesCount > 0 ? comment.likesCount - 1 : 0);

    // Optimistic update
    await _fanProfile.setCommentLiked(comment.id, nextLiked);
    setState(() {
      final updatedComments = _detail!.comments.map((c) {
        if (c.id == comment.id) {
          return c.copyWith(likesCount: nextCount);
        }
        return c;
      }).toList();
      _detail = KijiweThreadDetailItem(
        thread: _detail!.thread,
        comments: updatedComments,
      );
    });

    final res = await ApiService.likeComment(comment.id, fanFingerprint: _fanProfile.fingerprint);
    if (!mounted) return;

    if (res != null) {
      final serverLiked = res['liked'] as bool? ?? nextLiked;
      final serverCount = res['likesCount'] as int? ?? nextCount;
      await _fanProfile.setCommentLiked(comment.id, serverLiked);
      setState(() {
        final updatedComments = _detail!.comments.map((c) {
          if (c.id == comment.id) {
            return c.copyWith(likesCount: serverCount);
          }
          return c;
        }).toList();
        _detail = KijiweThreadDetailItem(
          thread: _detail!.thread,
          comments: updatedComments,
        );
      });
    } else {
      // Revert on failure
      await _fanProfile.setCommentLiked(comment.id, isLiked);
      setState(() {
        final updatedComments = _detail!.comments.map((c) {
          if (c.id == comment.id) {
            return comment;
          }
          return c;
        }).toList();
        _detail = KijiweThreadDetailItem(
          thread: _detail!.thread,
          comments: updatedComments,
        );
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imeshindwa kubadili like ya maoni.'),
          backgroundColor: AppColors.liveRed,
        ),
      );
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Andika maoni yenye angalau herufi 2.'),
          backgroundColor: AppColors.liveRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final createdComment = await ApiService.postComment(
      threadId: widget.threadId,
      content: text,
      authorName: _fanProfile.fanName,
      authorTeamName: _fanProfile.favoriteTeam,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (createdComment != null) {
      _commentController.clear();
      FocusScope.of(context).unfocus();

      setState(() {
        final updatedComments = [..._detail!.comments, createdComment];
        final updatedThread = _detail!.thread.copyWith(
          commentsCount: _detail!.thread.commentsCount + 1,
        );
        _detail = KijiweThreadDetailItem(
          thread: updatedThread,
          comments: updatedComments,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.emerald, size: 18),
              SizedBox(width: 8),
              Text('Maoni yako yametumwa kikamilifu!'),
            ],
          ),
          backgroundColor: AppColors.surfaceElevated,
          duration: Duration(seconds: 2),
        ),
      );

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imeshindwa kutuma maoni. Jaribu tena.'),
          backgroundColor: AppColors.liveRed,
        ),
      );
    }
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _fanProfile.fanName);
    final popularTeams = ['Simba SC', 'Yanga SC', 'Azam FC', 'Singida BS', 'Tanzania Prisons', 'KMC FC', 'Nyingine'];
    String selectedTeam = popularTeams.contains(_fanProfile.favoriteTeam) ? _fanProfile.favoriteTeam : popularTeams.first;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final sheetBg = isDark ? AppColors.surface : Colors.white;
          final inputBg = isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9);
          final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
          final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
          final borderCol = isDark ? AppColors.borderSubtle : AppColors.lightBorder;

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(top: BorderSide(color: borderCol)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Wasifu wa Shabiki',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Badilisha jina na timu itakayoonekana kwenye maoni yako',
                  style: TextStyle(color: textMuted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  style: TextStyle(color: textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Jina lako / Utambulisho',
                    labelStyle: TextStyle(color: textMuted, fontSize: 12),
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderCol),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderCol),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedTeam,
                  dropdownColor: sheetBg,
                  style: TextStyle(color: textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Timu unayoshabikia',
                    labelStyle: TextStyle(color: textMuted, fontSize: 12),
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderCol),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderCol),
                    ),
                  ),
                  items: popularTeams.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedTeam = val);
                  },
                ),
                const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await _fanProfile.updateProfile(name: nameCtrl.text, team: selectedTeam);
                    if (ctx.mounted) Navigator.pop(ctx);
                    setState(() {});
                  },
                  child: const Text('Hifadhi Wasifu', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mjadala', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          if (_detail != null)
            IconButton(
              icon: const Icon(Icons.share_outlined, size: 20),
              onPressed: () => ShareSheet.show(context, _detail!.thread),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadDetail,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.emerald))
          : _detail == null
              ? const Center(child: Text('Mjadala haukupatikana'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(14),
                        children: [
                          // Main Thread Card
                          _buildThreadPost(_detail!.thread),

                          const SizedBox(height: 18),

                          // Comments Header
                          Row(
                            children: [
                              const Icon(Icons.forum_outlined, size: 16, color: AppColors.emerald),
                              const SizedBox(width: 6),
                              Text(
                                "MAONI YA MASHABIKI (${_detail!.comments.length})",
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Comments List
                          if (_detail!.comments.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(28),
                              alignment: Alignment.center,
                              child: const Column(
                                children: [
                                  Icon(Icons.chat_bubble_outline, color: AppColors.textMuted, size: 32),
                                  SizedBox(height: 8),
                                  Text(
                                    'Kuwa wa kwanza kutoa maoni kwenye mjadala huu!',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                  ),
                                ],
                              ),
                            )
                          else
                            ..._detail!.comments.map((c) => _buildCommentCard(c)),
                        ],
                      ),
                    ),

                    // Comment Input Bar
                    _buildCommentInputBar(),
                  ],
                ),
    );
  }

  Widget _buildThreadPost(KijiweThreadItem thread) {
    final isLiked = _fanProfile.isThreadLiked(thread.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.border : AppColors.lightBorder, width: 1),
        boxShadow: isDark ? null : const [BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Row
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceElevated : const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
                ),
                alignment: Alignment.center,
                child: Text(
                  thread.authorName.isNotEmpty ? thread.authorName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: AppColors.emerald,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.authorName,
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (thread.authorTeamName != null && thread.authorTeamName!.isNotEmpty)
                      Text(
                        thread.authorTeamName!,
                        style: const TextStyle(
                          color: AppColors.emerald,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              if (thread.tag != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceElevated : const Color(0xFFFEF3C7),
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

          const SizedBox(height: 12),

          Text(
            thread.title,
            style: TextStyle(
              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            thread.content,
            style: TextStyle(
              color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 14),

          // Likes, Share & Engagement Bar
          Row(
            children: [
              // Like Button
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleThreadLike,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isLiked
                        ? AppColors.emerald.withValues(alpha: 0.15)
                        : (isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isLiked ? AppColors.emerald : (isDark ? AppColors.borderSubtle : AppColors.lightBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                        size: 14,
                        color: isLiked ? AppColors.emerald : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${thread.likesCount} Likes",
                        style: TextStyle(
                          color: isLiked ? AppColors.emerald : (isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
                          fontSize: 11.5,
                          fontWeight: isLiked ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Share Button
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => ShareSheet.show(context, thread),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? AppColors.borderSubtle : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.share_outlined, size: 14, color: isDark ? AppColors.textMuted : AppColors.lightTextMuted),
                      const SizedBox(width: 6),
                      Text(
                        "Shiriki",
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              if (thread.createdAt != null)
                Text(
                  DateFormat('d MMM yyyy, HH:mm').format(thread.createdAt!.toLocal()),
                  style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.lightTextMuted, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(KijiweCommentItem c) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLiked = _fanProfile.isCommentLiked(c.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderSubtle : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surface : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  c.authorName.isNotEmpty ? c.authorName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: AppColors.emerald,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                c.authorName,
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (c.authorTeamName != null && c.authorTeamName!.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  "• ${c.authorTeamName}",
                  style: const TextStyle(color: AppColors.emerald, fontSize: 10),
                ),
              ],
              const Spacer(),
              if (c.createdAt != null)
                Text(
                  DateFormat('HH:mm').format(c.createdAt!.toLocal()),
                  style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.lightTextMuted, fontSize: 10),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            c.content,
            style: TextStyle(
              color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          // Like Comment Button
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _toggleCommentLike(c),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                        size: 13,
                        color: isLiked ? AppColors.emerald : (isDark ? AppColors.textMuted : AppColors.lightTextMuted),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${c.likesCount}",
                        style: TextStyle(
                          color: isLiked ? AppColors.emerald : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                          fontSize: 11,
                          fontWeight: isLiked ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInputBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        border: Border(top: BorderSide(color: isDark ? AppColors.borderSubtle : AppColors.lightBorder)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fan profile identity indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
              child: Row(
                children: [
                  const Icon(Icons.person_pin, size: 14, color: AppColors.emerald),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Kama: ${_fanProfile.fanName} (${_fanProfile.favoriteTeam})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.lightTextMuted, fontSize: 11),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _showEditProfileDialog,
                    child: const Text(
                      'Badili',
                      style: TextStyle(
                        color: AppColors.emerald,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? AppColors.border : AppColors.lightBorder),
                    ),
                    child: TextField(
                      controller: _commentController,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Andika maoni yako hapa...',
                        hintStyle: TextStyle(color: isDark ? AppColors.textMuted : AppColors.lightTextMuted, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: AppColors.emerald, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, color: AppColors.emerald),
                  onPressed: _isSubmitting ? null : _submitComment,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
