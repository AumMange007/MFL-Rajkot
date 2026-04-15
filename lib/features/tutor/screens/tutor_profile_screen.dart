import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/tutor_model.dart';
import '../providers/tutor_profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/providers/profile_photo_provider.dart';
import '../../../widgets/common_widgets.dart';

class TutorProfileScreen extends ConsumerStatefulWidget {
  const TutorProfileScreen({super.key});

  @override
  ConsumerState<TutorProfileScreen> createState() => _TutorProfileScreenState();
}

class _TutorProfileScreenState extends ConsumerState<TutorProfileScreen> {
  final _mobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _specCtrl = TextEditingController();
  final _qualCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    _bioCtrl.dispose();
    _expCtrl.dispose();
    _specCtrl.dispose();
    _qualCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(tutorProfileProvider);
    final theme = Theme.of(context);

    ref.listen(tutorProfileProvider, (prev, next) {
      next.whenData((tutor) {
        if (tutor != null) {
          _mobileCtrl.text = tutor.mobile ?? "";
          _addressCtrl.text = tutor.address ?? "";
          _bioCtrl.text = tutor.bio ?? "";
          _expCtrl.text = tutor.experience ?? "";
          _specCtrl.text = tutor.specialization ?? "";
          _qualCtrl.text = tutor.qualification ?? "";
          _dobCtrl.text = tutor.dob ?? "";
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
          if (profileState.hasValue)
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
        data: (tutor) {
          // If tutor exists, use its data. If not, it means profile isn't created yet in 'tutors' table.
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: _buildHeader(tutor, ref),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isEditing) ...[
                      _buildField('Mobile Number', _mobileCtrl, Icons.phone_android_rounded),
                      _buildField('Address', _addressCtrl, Icons.home_rounded),
                      _buildField('Bio / About Me', _bioCtrl, Icons.info_outline_rounded, maxLines: 3),
                      _buildField('Experience', _expCtrl, Icons.work_history_rounded),
                      _buildField('Specialization', _specCtrl, Icons.stars_rounded),
                      _buildField('Qualification', _qualCtrl, Icons.school_rounded),
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
                        _buildViewField('Mobile Number', tutor?.mobile, Icons.phone_android_rounded),
                        _buildViewField('Address', tutor?.address, Icons.home_rounded),
                        _buildViewField('Bio', tutor?.bio, Icons.info_outline_rounded),
                        _buildViewField('Experience', tutor?.experience, Icons.work_history_rounded),
                        _buildViewField('Specialization', tutor?.specialization, Icons.stars_rounded),
                        _buildViewField('Qualification', tutor?.qualification, Icons.school_rounded),
                        _buildViewField('Date of Birth', tutor?.dob, Icons.cake_rounded),
                      ],
                    ],
                  ),
                ),
                ],
              ),
              ),
              if (ref.watch(profilePhotoProvider).isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
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

  Widget _buildHeader(TutorModel? tutor, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final photoState = ref.watch(profilePhotoProvider);
    final avatarUrl = photoState.maybeWhen(data: (url) => url ?? tutor?.tutorAvatarUrl ?? user?.avatarUrl, orElse: () => tutor?.tutorAvatarUrl ?? user?.avatarUrl);

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
                    ? Text(tutor?.tutorName?[0].toUpperCase() ?? user?.name[0].toUpperCase() ?? "T", 
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
              Text(tutor?.tutorName ?? user?.name ?? "Tutor", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Text(tutor?.tutorEmail ?? user?.email ?? "", style: TextStyle(color: theme.colorScheme.outline)),
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
      await ref.read(tutorProfileProvider.notifier).updateProfile(
        mobile: _mobileCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        experience: _expCtrl.text.trim(),
        specialization: _specCtrl.text.trim(),
        qualification: _qualCtrl.text.trim(),
        dob: _dobCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
      setState(() => _isEditing = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
