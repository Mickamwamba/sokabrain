import 'package:flutter/material.dart';
import '../models/kijiweni.dart';
import '../services/api_service.dart';
import '../services/fan_profile_service.dart';
import '../theme/app_colors.dart';

class CreateThreadSheet extends StatefulWidget {
  final List<KijiweSpaceItem> spaces;
  final String? initialSpaceSlug;

  const CreateThreadSheet({
    super.key,
    required this.spaces,
    this.initialSpaceSlug,
  });

  static Future<bool?> show(BuildContext context, {required List<KijiweSpaceItem> spaces, String? initialSpaceSlug}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: CreateThreadSheet(spaces: spaces, initialSpaceSlug: initialSpaceSlug),
      ),
    );
  }

  @override
  State<CreateThreadSheet> createState() => _CreateThreadSheetState();
}

class _CreateThreadSheetState extends State<CreateThreadSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _nameController = TextEditingController();
  final _teamController = TextEditingController();

  late String _selectedSpaceSlug;
  String _selectedTag = 'UBISHI';
  bool _isSubmitting = false;

  final List<String> _availableTags = ['UBISHI', 'CHOMBEZA', 'UTABIRI', 'MBINU'];
  final List<String> _popularTeams = ['Simba SC', 'Yanga SC', 'Azam FC', 'Singida BS', 'Tanzania Prisons', 'KMC FC', 'Nyingine'];

  @override
  void initState() {
    super.initState();
    final fanProfile = FanProfileService();
    _nameController.text = fanProfile.fanName;
    _teamController.text = fanProfile.favoriteTeam;

    if (widget.initialSpaceSlug != null && widget.spaces.any((s) => s.slug == widget.initialSpaceSlug)) {
      _selectedSpaceSlug = widget.initialSpaceSlug!;
    } else if (widget.spaces.isNotEmpty) {
      _selectedSpaceSlug = widget.spaces.first.slug;
    } else {
      _selectedSpaceSlug = 'kariakoo-derby';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _nameController.dispose();
    _teamController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final authorName = _nameController.text.trim().isEmpty ? 'Shabiki Soka' : _nameController.text.trim();
    final authorTeam = _teamController.text.trim();

    setState(() => _isSubmitting = true);

    final threadId = await ApiService.createThread(
      spaceSlug: _selectedSpaceSlug,
      title: title,
      content: content,
      authorName: authorName,
      authorTeamName: authorTeam.isNotEmpty ? authorTeam : null,
      tag: _selectedTag,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (threadId != null) {
      // Save updated fan info
      await FanProfileService().updateProfile(
        name: authorName,
        team: authorTeam.isNotEmpty ? authorTeam : null,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.emerald, size: 18),
                SizedBox(width: 8),
                Text('Mjadala wako umechapishwa kikamilifu! 🔥'),
              ],
            ),
            backgroundColor: AppColors.surfaceElevated,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imeshindwa kuanzisha mada. Hakikisha maelezo ni sahihi kisha jaribu tena.'),
          backgroundColor: AppColors.liveRed,
        ),
      );
    }
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _sheetBg => _isDark ? AppColors.surface : Colors.white;
  Color get _inputBg => _isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9);
  Color get _chipBg => _isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9);
  Color get _borderColor => _isDark ? AppColors.borderSubtle : AppColors.lightBorder;
  Color get _textPrimary => _isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
  Color get _textSecondary => _isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
  Color get _textMuted => _isDark ? AppColors.textMuted : AppColors.lightTextMuted;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: BoxDecoration(
        color: _sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: _borderColor, width: 1)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle & Header
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.rate_review_rounded, color: AppColors.emerald, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anzisha Mada Mpya',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Tupia mada kijiweni kwa mashabiki wenzako',
                        style: TextStyle(color: _textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: _textMuted, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(color: _borderColor, height: 1),

            // Scrollable Content Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Space Selector
                    Text(
                      'CHAGUA KIJIWE',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: widget.spaces.map((space) {
                          final isSelected = _selectedSpaceSlug == space.slug;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (space.icon != null) ...[
                                    Text(space.icon!, style: const TextStyle(fontSize: 12)),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(space.nameSw),
                                ],
                              ),
                              selected: isSelected,
                              selectedColor: AppColors.emerald,
                              backgroundColor: _chipBg,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.black : _textPrimary,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              ),
                              side: BorderSide(
                                color: isSelected ? AppColors.emerald : _borderColor,
                              ),
                              onSelected: (_) {
                                setState(() => _selectedSpaceSlug = space.slug);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Tag Selector
                    Text(
                      'AINA YA MJADALA (TAG)',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availableTags.map((tag) {
                        final isSelected = _selectedTag == tag;
                        return ChoiceChip(
                          label: Text(tag),
                          selected: isSelected,
                          selectedColor: AppColors.amberBg,
                          backgroundColor: _chipBg,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.amber : _textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          side: BorderSide(
                            color: isSelected ? AppColors.amber : _borderColor,
                          ),
                          onSelected: (_) {
                            setState(() => _selectedTag = tag);
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 18),

                    // Title Field
                    Text(
                      'KICHWA CHA MADA',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      maxLength: 150,
                      style: TextStyle(color: _textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Mfano: Simba vs Yanga - Nani anastahili ubingwa msimu huu?',
                        hintStyle: TextStyle(color: _textMuted, fontSize: 13),
                        filled: true,
                        fillColor: _inputBg,
                        counterStyle: TextStyle(color: _textMuted, fontSize: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.emerald, width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().length < 4) {
                          return 'Kichwa cha mada kiwe na herufi angalau 4';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Content Field
                    Text(
                      'MAELEZO YA MJADALA',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _contentController,
                      maxLines: 4,
                      maxLength: 2000,
                      style: TextStyle(color: _textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Tiririka hapa kwa kina. Weka hoja zako na takwimu kuwasha moto kijiweni...',
                        hintStyle: TextStyle(color: _textMuted, fontSize: 13),
                        filled: true,
                        fillColor: _inputBg,
                        counterStyle: TextStyle(color: _textMuted, fontSize: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.emerald, width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().length < 10) {
                          return 'Maelezo ya mada yawe na herufi angalau 10';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Author Name & Team Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'JINA LAKO',
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _nameController,
                                style: TextStyle(color: _textPrimary, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Jina / Lakabu',
                                  hintStyle: TextStyle(color: _textMuted, fontSize: 12),
                                  filled: true,
                                  fillColor: _inputBg,
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: _borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: _borderColor),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide(color: AppColors.emerald),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().length < 2) {
                                    return 'Weka jina (angalau herufi 2)';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TIMU YAKO',
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _popularTeams.contains(_teamController.text) ? _teamController.text : _popularTeams.first,
                                dropdownColor: _sheetBg,
                                style: TextStyle(color: _textPrimary, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: _inputBg,
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: _borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: _borderColor),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide(color: AppColors.emerald),
                                  ),
                                ),
                                items: _popularTeams.map((team) {
                                  return DropdownMenuItem(value: team, child: Text(team));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _teamController.text = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded, size: 18, color: Colors.black),
                                  SizedBox(width: 8),
                                  Text(
                                    'Chapisha Mada Kijiweni',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
