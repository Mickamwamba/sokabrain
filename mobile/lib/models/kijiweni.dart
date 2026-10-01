class KijiweSpaceItem {
  final String slug;
  final String nameSw;
  final String nameEn;
  final String? icon;
  final String? description;
  final String? badgeColor;
  final int threadsCount;
  final int commentsCount;

  KijiweSpaceItem({
    required this.slug,
    required this.nameSw,
    required this.nameEn,
    this.icon,
    this.description,
    this.badgeColor,
    required this.threadsCount,
    required this.commentsCount,
  });

  factory KijiweSpaceItem.fromJson(Map<String, dynamic> json) {
    return KijiweSpaceItem(
      slug: json['slug'] as String? ?? '',
      nameSw: json['nameSw'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      icon: json['icon'] as String?,
      description: json['description'] as String?,
      badgeColor: json['badgeColor'] as String?,
      threadsCount: json['threadsCount'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? 0,
    );
  }
}

class KijiweThreadItem {
  final int id;
  final String title;
  final String content;
  final String authorName;
  final String? authorTeamName;
  final String? tag;
  final bool isPinned;
  final int likesCount;
  final int commentsCount;
  final DateTime? createdAt;
  final String? spaceSlug;

  KijiweThreadItem({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    this.authorTeamName,
    this.tag,
    required this.isPinned,
    required this.likesCount,
    required this.commentsCount,
    this.createdAt,
    this.spaceSlug,
  });

  KijiweThreadItem copyWith({
    int? id,
    String? title,
    String? content,
    String? authorName,
    String? authorTeamName,
    String? tag,
    bool? isPinned,
    int? likesCount,
    int? commentsCount,
    DateTime? createdAt,
    String? spaceSlug,
  }) {
    return KijiweThreadItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorName: authorName ?? this.authorName,
      authorTeamName: authorTeamName ?? this.authorTeamName,
      tag: tag ?? this.tag,
      isPinned: isPinned ?? this.isPinned,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
      spaceSlug: spaceSlug ?? this.spaceSlug,
    );
  }

  factory KijiweThreadItem.fromJson(Map<String, dynamic> json) {
    final kijiwe = json['kijiwe'] as Map<String, dynamic>? ?? json['space'] as Map<String, dynamic>? ?? {};
    return KijiweThreadItem(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Shabiki',
      authorTeamName: json['authorTeamName'] as String?,
      tag: json['tag'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
      likesCount: json['likesCount'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      spaceSlug: kijiwe['slug'] as String?,
    );
  }
}

class KijiweCommentItem {
  final int id;
  final String content;
  final String authorName;
  final String? authorTeamName;
  final int likesCount;
  final DateTime? createdAt;

  KijiweCommentItem({
    required this.id,
    required this.content,
    required this.authorName,
    this.authorTeamName,
    required this.likesCount,
    this.createdAt,
  });

  KijiweCommentItem copyWith({
    int? id,
    String? content,
    String? authorName,
    String? authorTeamName,
    int? likesCount,
    DateTime? createdAt,
  }) {
    return KijiweCommentItem(
      id: id ?? this.id,
      content: content ?? this.content,
      authorName: authorName ?? this.authorName,
      authorTeamName: authorTeamName ?? this.authorTeamName,
      likesCount: likesCount ?? this.likesCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory KijiweCommentItem.fromJson(Map<String, dynamic> json) {
    return KijiweCommentItem(
      id: json['id'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Shabiki',
      authorTeamName: json['authorTeamName'] as String?,
      likesCount: json['likesCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}

class KijiweThreadDetailItem {
  final KijiweThreadItem thread;
  final List<KijiweCommentItem> comments;

  KijiweThreadDetailItem({
    required this.thread,
    required this.comments,
  });

  factory KijiweThreadDetailItem.fromJson(Map<String, dynamic> json) {
    final threadJson = json['thread'] as Map<String, dynamic>? ?? json;
    final commentsList = (threadJson['comments'] as List<dynamic>?) ?? [];

    return KijiweThreadDetailItem(
      thread: KijiweThreadItem.fromJson(threadJson),
      comments: commentsList.map((c) => KijiweCommentItem.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }
}
