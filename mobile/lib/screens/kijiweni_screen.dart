import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/kijiweni.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('KIJIWENI', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.amberBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'FAN ZONE',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Spaces Horizontal Bar
          if (_spaces.isNotEmpty)
            Container(
              height: 54,
              color: AppColors.background,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _buildSpaceChip('All Spaces', null, null),
                  ..._spaces.map((s) => _buildSpaceChip(s.nameSw, s.slug, s.icon)),
                ],
              ),
            ),

          const Divider(height: 1, color: AppColors.borderSubtle),

          // Threads Feed
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.emerald))
                : _threads.isEmpty
                    ? const Center(
                        child: Text(
                          'Hakuna mada zilizopatikana kwenye kijiwe hiki.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.emerald,
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _threads.length,
                          itemBuilder: (context, index) {
                            final thread = _threads[index];
                            return _buildThreadCard(thread);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceChip(String title, String? slug, String? icon) {
    final isSelected = _selectedSpaceSlug == slug;
    return GestureDetector(
      onTap: () => _filterBySpace(slug),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.emerald : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.emerald : AppColors.borderSubtle,
            width: 1,
          ),
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
                color: isSelected ? Colors.black : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadCard(KijiweThreadItem thread) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ThreadDetailScreen(threadId: thread.id),
            ),
          ).then((_) => _loadData());
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
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      thread.authorName.isNotEmpty ? thread.authorName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppColors.emerald,
                        fontSize: 11,
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
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (thread.authorTeamName != null)
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

              const SizedBox(height: 10),

              // Title
              Text(
                thread.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
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
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 12),

              // Bottom Actions Row: Likes, Comments, Date
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await ApiService.likeThread(thread.id);
                      _loadData();
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.thumb_up_outlined, size: 14, color: AppColors.emerald),
                        const SizedBox(width: 4),
                        Text(
                          "${thread.likesCount}",
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        "${thread.commentsCount}",
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (thread.createdAt != null)
                    Text(
                      DateFormat('d MMM, HH:mm').format(thread.createdAt!.toLocal()),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
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
