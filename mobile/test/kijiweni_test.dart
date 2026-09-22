import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sokabrain_mobile/models/kijiweni.dart';
import 'package:sokabrain_mobile/services/api_service.dart';
import 'package:sokabrain_mobile/services/fan_profile_service.dart';
import 'package:sokabrain_mobile/widgets/create_thread_sheet.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  group('FanProfileService Tests', () {
    test('Initializes profile and generates valid fingerprint', () async {
      final profile = FanProfileService();
      await profile.init();

      expect(profile.fingerprint.isNotEmpty, isTrue);
      expect(profile.fingerprint.startsWith('fan_'), isTrue);
      expect(profile.fanName.isNotEmpty, isTrue);

      await profile.updateProfile(name: 'Shabiki Shujaa', team: 'Yanga SC');
      expect(profile.fanName, 'Shabiki Shujaa');
      expect(profile.favoriteTeam, 'Yanga SC');

      final testThreadId = DateTime.now().millisecondsSinceEpoch % 100000;
      expect(profile.isThreadLiked(testThreadId), isFalse);
      await profile.setThreadLiked(testThreadId, true);
      expect(profile.isThreadLiked(testThreadId), isTrue);
      await profile.setThreadLiked(testThreadId, false);
      expect(profile.isThreadLiked(testThreadId), isFalse);

      final testCommentId = (testThreadId + 1);
      expect(profile.isCommentLiked(testCommentId), isFalse);
      await profile.setCommentLiked(testCommentId, true);
      expect(profile.isCommentLiked(testCommentId), isTrue);
      await profile.setCommentLiked(testCommentId, false);
      expect(profile.isCommentLiked(testCommentId), isFalse);
    });
  });

  group('Kijiweni Backend API Integration Tests', () {
    test('createThread, likeThread, postComment, and likeComment via API', () async {
      final profile = FanProfileService();
      await profile.init();

      // 1. Create thread
      final threadId = await ApiService.createThread(
        spaceSlug: 'kariakoo-derby',
        title: 'Mada ya Jaribio la Kiotomatiki',
        content: 'Mada hii inathibitisha kwamba watumiaji wanaweza kuanzisha mada kijiweni bila tatizo.',
        authorName: 'Mchambuzi Mtihani',
        authorTeamName: 'Simba SC',
        tag: 'UBISHI',
      );

      expect(threadId, isNotNull);
      expect(threadId! > 0, isTrue);

      // 2. Like thread
      final likeResult = await ApiService.likeThread(threadId, fanFingerprint: profile.fingerprint);
      expect(likeResult, isNotNull);
      expect(likeResult!['liked'], isTrue);
      expect(likeResult['likesCount'] >= 1, isTrue);

      // Unlike thread
      final unlikeResult = await ApiService.likeThread(threadId, fanFingerprint: profile.fingerprint);
      expect(unlikeResult, isNotNull);
      expect(unlikeResult!['liked'], isFalse);

      // 3. Post comment
      final comment = await ApiService.postComment(
        threadId: threadId,
        content: 'Huu ni mtihani wa kutoa maoni kwenye mada.',
        authorName: 'Shabiki Mtihani',
        authorTeamName: 'Simba SC',
      );

      expect(comment, isNotNull);
      expect(comment!.content, 'Huu ni mtihani wa kutoa maoni kwenye mada.');
      expect(comment.id > 0, isTrue);

      // 4. Like comment
      final commentLike = await ApiService.likeComment(comment.id, fanFingerprint: profile.fingerprint);
      expect(commentLike, isNotNull);
      expect(commentLike!['liked'], isTrue);
      expect(commentLike['likesCount'] >= 1, isTrue);
    });
  });

  group('UI Widgets Tests', () {
    testWidgets('CreateThreadSheet renders all fields properly', (tester) async {
      final spaces = [
        KijiweSpaceItem(
          slug: 'kariakoo-derby',
          nameSw: 'Kijiwe cha Kariakoo',
          nameEn: 'Kariakoo Corner',
          threadsCount: 5,
          commentsCount: 10,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreateThreadSheet(spaces: spaces),
          ),
        ),
      );

      expect(find.text('Anzisha Mada Mpya'), findsOneWidget);
      expect(find.text('CHAGUA KIJIWE'), findsOneWidget);
      expect(find.text('Kijiwe cha Kariakoo'), findsOneWidget);
      expect(find.text('AINA YA MJADALA (TAG)'), findsOneWidget);
      expect(find.text('UBISHI'), findsOneWidget);
      expect(find.text('KICHWA CHA MADA'), findsOneWidget);
      expect(find.text('MAELEZO YA MJADALA'), findsOneWidget);
      expect(find.text('Chapisha Mada Kijiweni'), findsOneWidget);
    });
  });
}
