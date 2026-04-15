import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/student_model.dart';
import '../providers/student_profile_provider.dart';
import '../../common/providers/profile_photo_provider.dart';
import '../../../widgets/common_widgets.dart';

class StudentProfileScreen extends ConsumerStatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  ConsumerState<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen> {
  final _mobileCtrl = TextEditingController();
  final _parentMobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _parentMobileCtrl.dispose();
    _addressCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(studentProfileProvider);
    final theme = Theme.of(context);

    ref.listen(studentProfileProvider, (prev, next) {
      next.whenData((student) {
        if (student != null) {
          _mobileCtrl.text = student.mobile ?? "";
          _parentMobileCtrl.text = student.parentMobile ?? "";
          _addressCtrl.text = student.address ?? "";
          _dobCtrl.text = student.dateOfBirth ?? "";
        }
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        title: Text('My Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          if (profileState.hasValue && profileState.value != null)
            TextButton.icon(
              onPressed: () => setState(() => _isEditing = !_isEditing),
              icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded, size: 18),
              label: Text(_isEditing ? 'Cancel' : 'Edit', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          if (_isEditing && !_isSaving)
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: profileState.when(
        data: (student) => Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: _buildHeader(student, ref),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isEditing) ...[
                    _buildField('My Mobile Number', _mobileCtrl, Icons.phone_android_rounded),
                    _buildField('Parent\'s Mobile Number', _parentMobileCtrl, Icons.family_restroom_rounded),
                    _buildField('My Address', _addressCtrl, Icons.home_rounded, maxLines: 2),
                    _buildField('Date of Birth', _dobCtrl, Icons.cake_rounded),
                    
                    const SizedBox(height: 40),
                    if (_isSaving)
                      const Center(child: CircularProgressIndicator())
                    else
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.save_rounded),
                            label: const Text('Update Profile Details'),
                          ),
                        ),
                    ] else ...[
                      _buildViewField('Mobile Number', student?.mobile, Icons.phone_android_rounded),
                      _buildViewField('Parent\'s Mobile', student?.parentMobile, Icons.family_restroom_rounded),
                      _buildViewField('Address', student?.address, Icons.home_rounded),
                      _buildViewField('Date of Birth', student?.dateOfBirth, Icons.cake_rounded),
                    ],
                  ],
                ),
              ),
                const SizedBox(height: 24),
                if (!_isEditing) Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    
                    Text('Academic Progress', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildViewField('Current Level', student?.level, Icons.layers_rounded),
                    _buildViewField('Language', student?.language, Icons.translate_rounded),
                    
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.5,
                      children: [
                        _progressCard('Vocab', student?.vocabChap),
                        _progressCard('Grammar', student?.grammarChap),
                        _progressCard('Kursbuch', student?.kbChap),
                        _progressCard('Workbook', student?.ubChap),
                      ],
                    ),
                  ],
                )),
                ],
              ),
            ),
            if (ref.watch(profilePhotoProvider).isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading profile: $err')),
      ),
    );
  }

  Widget _buildViewField(String label, String? value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                Text(value != null && value.isNotEmpty ? value : 'Not provided', 
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressCard(String label, String? value) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          Text('Chapter ${value ?? "0"}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHeader(StudentModel? student, WidgetRef ref) {
    final theme = Theme.of(context);
    final photoState = ref.watch(profilePhotoProvider);
    final avatarUrl = photoState.maybeWhen(data: (url) => url ?? student?.studentAvatarUrl, orElse: () => student?.studentAvatarUrl);

    // Listen for photo update success to show snackbar
    ref.listen(profilePhotoProvider, (prev, next) {
      next.whenData((url) {
        if (prev?.value != url && url != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated successfully!'), behavior: SnackBarBehavior.floating),
          );
        }
      });
    });

    return Row(
      children: [
        GestureDetector(
          onTap: () => ProfilePhotoActions.showOptions(
            context: context,
            ref: ref,
            currentImageUrl: avatarUrl,
          ),
          child: Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(student?.studentName?[0].toUpperCase() ?? "S", 
                        style: theme.textTheme.headlineLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer))
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(student?.studentName ?? "Student", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Text(student?.studentEmail ?? "", style: TextStyle(color: theme.colorScheme.outline)),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 22),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(studentProfileProvider.notifier).updateProfile(
        mobile: _mobileCtrl.text.trim(),
        parentMobile: _parentMobileCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        dob: _dobCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
      
      // Auto redirect back to dashboard
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) context.pop();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
