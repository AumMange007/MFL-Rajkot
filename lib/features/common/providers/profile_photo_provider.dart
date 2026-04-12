import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../student/providers/student_profile_provider.dart';
import '../../tutor/providers/tutor_profile_provider.dart';
import '../../admin/providers/student_management_provider.dart';
import '../../admin/providers/tutor_management_provider.dart';

class ProfilePhotoNotifier extends StateNotifier<AsyncValue<String?>> {
  final SupabaseClient _supabase;
  final String? _userId;
  final Ref _ref;

  ProfilePhotoNotifier(this._supabase, this._userId, this._ref) : super(const AsyncValue.data(null));

  Future<void> pickAndUploadImage() async {
    if (_userId == null) return;
    
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (image == null) return;

    state = const AsyncValue.loading();

    try {
      final file = File(image.path);
      final fileExtension = image.path.split('.').last;
      final fileName = '$_userId.${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final path = fileName;

      // 1. Upload to Supabase Storage
      await _supabase.storage.from(AppConstants.profilesBucket).upload(path, file);
 
      // 2. Get Public URL
      final imageUrl = _supabase.storage.from(AppConstants.profilesBucket).getPublicUrl(path);

      // 3. Update User Table
      await _supabase.from('users').update({
        'avatar_url': imageUrl,
      }).eq('id', _userId!);

      // 4. Force refresh the global user state
      await _ref.read(authNotifierProvider.notifier).refreshUser();
      
      // 5. Invalidate relevant providers to force UI refresh
      _ref.invalidate(studentProfileProvider);
      _ref.invalidate(tutorProfileProvider);
      _ref.invalidate(studentManagementProvider);
      _ref.invalidate(tutorManagementProvider);

      state = AsyncValue.data(imageUrl);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deletePhoto([String? targetUserId]) async {
    final uid = targetUserId ?? _userId;
    if (uid == null) return;

    state = const AsyncValue.loading();
    try {
      // 1. Set avatar_url to null in users table
      await _supabase.from('users').update({
        'avatar_url': null,
      }).eq('id', uid);

      // 2. Force refresh states
      if (uid == _userId) {
        await _ref.read(authNotifierProvider.notifier).refreshUser();
      }
      
      _ref.invalidate(studentProfileProvider);
      _ref.invalidate(tutorProfileProvider);
      _ref.invalidate(studentManagementProvider);
      _ref.invalidate(tutorManagementProvider);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Admin/Tutor can use this to upload for ANOTHER user
  Future<void> uploadForUser(String targetUserId) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image == null) return;

    state = const AsyncValue.loading();
    try {
      final file = File(image.path);
      final fileExtension = image.path.split('.').last;
      final fileName = '$targetUserId.${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final path = fileName;
      
      await _supabase.storage.from(AppConstants.profilesBucket).upload(path, file);
      final imageUrl = _supabase.storage.from(AppConstants.profilesBucket).getPublicUrl(path);

      await _supabase.from('users').update({'avatar_url': imageUrl}).eq('id', targetUserId);
      
      // Force refresh management lists
      _ref.invalidate(studentManagementProvider);
      _ref.invalidate(tutorManagementProvider);
      
      state = AsyncValue.data(imageUrl);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final profilePhotoProvider = StateNotifierProvider<ProfilePhotoNotifier, AsyncValue<String?>>((ref) {
  final user = ref.watch(currentUserProvider);
  return ProfilePhotoNotifier(ref.watch(supabaseProvider), user?.id, ref);
});
