import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/kijiweni.dart';
import '../theme/app_colors.dart';

class ShareSheet {
  static void show(BuildContext context, KijiweThreadItem thread) {
    final threadUrl = 'https://sokabrain.com/kijiweni/threads/${thread.id}';
    final shareMessage = '⚽ *${thread.title}*\n\n'
        '${thread.content}\n\n'
        '💬 Jiunge na mjadala kwenye Kijiweni cha SokaBrain:\n$threadUrl';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final sheetBg = isDark ? AppColors.surface : Colors.white;
        final borderCol = isDark ? AppColors.borderSubtle : AppColors.lightBorder;
        final previewBg = isDark ? AppColors.surfaceElevated : const Color(0xFFF8FAFC);
        final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
        final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
        final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: borderCol, width: 1)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
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
                const SizedBox(height: 16),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.share_rounded, color: AppColors.emerald, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shiriki Mjadala',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Sambaza habari na maoni kwa wadau wa soka',
                            style: TextStyle(color: textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Thread snippet preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: previewBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thread.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        thread.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action 1: Copy Link
                _buildShareAction(
                  context: ctx,
                  icon: Icons.link_rounded,
                  title: 'Nakili Kiungo (Copy Link)',
                  subtitle: threadUrl,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: threadUrl));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.emerald, size: 18),
                            SizedBox(width: 8),
                            Text('Kiungo kimenakiliwa kwenye clipboard! 📋'),
                          ],
                        ),
                        backgroundColor: isDark ? AppColors.surfaceElevated : const Color(0xFF1E293B),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Action 2: Copy full message for WhatsApp / SMS
                _buildShareAction(
                  context: ctx,
                  icon: Icons.copy_all_rounded,
                  title: 'Nakili Ujumbe Kamili (Copy Discussion)',
                  subtitle: 'Yote: Kichwa, maelezo na kiungo cha kujiunga',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: shareMessage));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.emerald, size: 18),
                            SizedBox(width: 8),
                            Text('Ujumbe wote umenakiliwa kikamilifu! 📋'),
                          ],
                        ),
                        backgroundColor: isDark ? AppColors.surfaceElevated : const Color(0xFF1E293B),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showGeneric(
    BuildContext context, {
    required String title,
    required String url,
    required String summary,
  }) {
    final shareMessage = '⚽ *$title*\n\n$summary\n\n🔗 $url';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final sheetBg = isDark ? AppColors.surface : Colors.white;
        final borderCol = isDark ? AppColors.borderSubtle : AppColors.lightBorder;
        final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
        final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: borderCol, width: 1)),
          ),
          child: SafeArea(
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.share_rounded, color: AppColors.emerald, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildShareAction(
                  context: ctx,
                  icon: Icons.link_rounded,
                  title: 'Nakili Kiungo (Copy Link)',
                  subtitle: url,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: url));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.emerald, size: 18),
                            SizedBox(width: 8),
                            Text('Kiungo kimenakiliwa! 📋'),
                          ],
                        ),
                        backgroundColor: isDark ? AppColors.surfaceElevated : const Color(0xFF1E293B),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildShareAction(
                  context: ctx,
                  icon: Icons.copy_all_rounded,
                  title: 'Nakili Ujumbe Kamili',
                  subtitle: 'Kichwa, maelezo na kiungo cha programu',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: shareMessage));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.emerald, size: 18),
                            SizedBox(width: 8),
                            Text('Ujumbe umenakiliwa! Tayari kwa kushiriki 📲'),
                          ],
                        ),
                        backgroundColor: isDark ? AppColors.surfaceElevated : const Color(0xFF1E293B),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildShareAction({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemBg = isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9);
    final borderCol = isDark ? AppColors.borderSubtle : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: itemBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderCol),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.emerald, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
