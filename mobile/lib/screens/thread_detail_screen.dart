import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/kijiweni.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

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
  final TextEditingController _nameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _nameController.dispose();
    super.dispose();
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

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Shabiki_Wa_Soka';

    setState(() => _isSubmitting = true);
    final success = await ApiService.postComment(
      threadId: widget.threadId,
      content: text,
      authorName: name,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maoni yametumwa kikamilifu!'),
          backgroundColor: AppColors.emeraldDark,
        ),
      );
      _loadDetail();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imeshindwa kutuma maoni. Jaribu tena.'),
          backgroundColor: AppColors.liveRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mjadala', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
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
                              padding: const EdgeInsets.all(24),
                              alignment: Alignment.center,
                              child: const Text(
                                'Kuwa wa kwanza kutoa maoni kwenye mjadala huu!',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
                ),
                alignment: Alignment.center,
                child: Text(
                  thread.authorName.isNotEmpty ? thread.authorName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: AppColors.emerald,
                    fontSize: 13,
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
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (thread.authorTeamName != null)
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
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    thread.tag!,
                    style: const TextStyle(
                      color: AppColors.textMuted,
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
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            thread.content,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 14),

          // Likes & Engagement
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  await ApiService.likeThread(thread.id);
                  _loadDetail();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.thumb_up_outlined, size: 13, color: AppColors.emerald),
                      const SizedBox(width: 5),
                      Text(
                        "${thread.likesCount} Likes",
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
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
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(KijiweCommentItem c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  c.authorName.isNotEmpty ? c.authorName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: AppColors.emerald,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                c.authorName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (c.authorTeamName != null) ...[
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
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            c.content,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: AppColors.surface,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Andika maoni yako hapa...',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
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
      ),
    );
  }
}
