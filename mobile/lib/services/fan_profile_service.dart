import 'dart:convert';
import 'dart:io';
import 'dart:math';

class FanProfileService {
  static final FanProfileService _instance = FanProfileService._internal();
  factory FanProfileService() => _instance;
  FanProfileService._internal();

  String _fingerprint = '';
  String _fanName = 'Shabiki Soka';
  String _favoriteTeam = 'Simba SC';
  final Set<int> _likedThreadIds = {};
  final Set<int> _likedCommentIds = {};
  bool _isInitialized = false;

  String get fingerprint => _fingerprint;
  String get fanName => _fanName;
  String get favoriteTeam => _favoriteTeam;
  Set<int> get likedThreadIds => _likedThreadIds;
  Set<int> get likedCommentIds => _likedCommentIds;

  File get _storageFile {
    final tempDir = Directory.systemTemp;
    return File('${tempDir.path}/sokabrain_fan_profile.json');
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final file = _storageFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        _fingerprint = data['fingerprint'] as String? ?? _generateFingerprint();
        _fanName = data['fanName'] as String? ?? 'Shabiki Soka';
        _favoriteTeam = data['favoriteTeam'] as String? ?? 'Simba SC';
        final likedThreads = (data['likedThreads'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [];
        final likedComments = (data['likedComments'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [];
        _likedThreadIds.addAll(likedThreads);
        _likedCommentIds.addAll(likedComments);
      } else {
        _fingerprint = _generateFingerprint();
        await _save();
      }
    } catch (_) {
      if (_fingerprint.isEmpty) {
        _fingerprint = _generateFingerprint();
      }
    }
    _isInitialized = true;
  }

  String _generateFingerprint() {
    final rand = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final r = rand.nextInt(999999);
    return 'fan_${timestamp}_$r';
  }

  Future<void> _save() async {
    try {
      final file = _storageFile;
      final data = {
        'fingerprint': _fingerprint,
        'fanName': _fanName,
        'favoriteTeam': _favoriteTeam,
        'likedThreads': _likedThreadIds.toList(),
        'likedComments': _likedCommentIds.toList(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  Future<void> updateProfile({required String name, String? team}) async {
    _fanName = name.trim().isEmpty ? 'Shabiki Soka' : name.trim();
    if (team != null && team.trim().isNotEmpty) {
      _favoriteTeam = team.trim();
    }
    await _save();
  }

  bool isThreadLiked(int id) => _likedThreadIds.contains(id);
  bool isCommentLiked(int id) => _likedCommentIds.contains(id);

  Future<void> setThreadLiked(int id, bool liked) async {
    if (liked) {
      _likedThreadIds.add(id);
    } else {
      _likedThreadIds.remove(id);
    }
    await _save();
  }

  Future<void> setCommentLiked(int id, bool liked) async {
    if (liked) {
      _likedCommentIds.add(id);
    } else {
      _likedCommentIds.remove(id);
    }
    await _save();
  }
}
