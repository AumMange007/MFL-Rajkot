import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/permission_service.dart';
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

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;
    state = const AsyncValue.loading();

    try {
      final file = File(result.files.single.path!);
      final fileExtension = result.files.single.extension ?? 'jpg';
      final fileName = '$_userId.${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      
      await _supabase.storage.from(AppConstants.profilesBucket).upload(fileName, file);
      final imageUrl = _supabase.storage.from(AppConstants.profilesBucket).getPublicUrl(fileName);

      await _supabase.from('users').update({'avatar_url': imageUrl}).eq('id', _userId);

      await _ref.read(authNotifierProvider.notifier).refreshUser();
      
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
      await _supabase.from('users').update({'avatar_url': null}).eq('id', uid);

      if (uid == _userId) await _ref.read(authNotifierProvider.notifier).refreshUser();
      
      _ref.invalidate(studentProfileProvider);
      _ref.invalidate(tutorProfileProvider);
      _ref.invalidate(studentManagementProvider);
      _ref.invalidate(tutorManagementProvider);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> uploadForUser(String targetUserId) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
    if (result == null || result.files.isEmpty) return;

    state = const AsyncValue.loading();
    try {
      final file = File(result.files.single.path!);
      final fileExtension = result.files.single.extension ?? 'jpg';
      final fileName = '$targetUserId.${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      
      await _supabase.storage.from(AppConstants.profilesBucket).upload(fileName, file);
      final imageUrl = _supabase.storage.from(AppConstants.profilesBucket).getPublicUrl(fileName);

      await _supabase.from('users').update({'avatar_url': imageUrl}).eq('id', targetUserId);
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
