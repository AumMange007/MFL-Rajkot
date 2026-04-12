import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/announcement_model.dart';
import '../../../models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

class AnnouncementNotifier extends StateNotifier<AsyncValue<List<AnnouncementModel>>> {
  final SupabaseClient _supabase;
  final UserModel? _admin;

  DateTime? _lastSeenAt;

  AnnouncementNotifier(this._supabase, this._admin) : super(const AsyncValue.loading()) {
    fetchAnnouncements();
  }

  void markAsSeen() {
    _lastSeenAt = DateTime.now();
    // Refresh to update unread status
    if (state.hasValue) {
      final list = state.value!;
      state = AsyncValue.data([...list]);
    }
  }

  bool hasUnread(List<AnnouncementModel> list) {
    if (list.isEmpty) return false;
    if (_lastSeenAt == null) return true;
    return list.any((e) => e.createdAt.isAfter(_lastSeenAt!));
  }

  Future<void> fetchAnnouncements() async {
    if (_admin == null) return;
    state = const AsyncValue.loading();
    try {
      // 1. Fetch raw announcements. Using exact SQL names: title, message, created_by, institute_id
      final data = await _supabase
          .from(AppConstants.announcementsTable)
          .select()
          .eq('institute_id', _admin!.instituteId)
          .order('created_at', ascending: false);
      
      final rawList = data as List;
      if (rawList.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }

      // 2. Fetch creator names from 'created_by' column
      final creatorIds = rawList
          .where((e) => e['created_by'] != null)
          .map((e) => e['created_by'] as String)
          .toSet()
          .toList();
      
      final usersRes = await _supabase
          .from(AppConstants.usersTable)
          .select('id, name')
          .inFilter('id', creatorIds);
      
      final creatorMap = {for (var u in usersRes as List) u['id']: u['name']};

      // 3. Map back to objects
      final announcements = rawList.map((e) {
        final creatorId = e['created_by'] as String?;
        final creatorName = creatorMap[creatorId] ?? 'Unknown Admin';
        return AnnouncementModel(
          id: e['id'] as String,
          title: e['title'] as String,
          message: e['message'] as String,
          instituteId: e['institute_id'] as String,
          createdBy: creatorId,
          creatorName: creatorName as String,
          createdAt: DateTime.parse(e['created_at'] as String),
        );
      }).toList();

      state = AsyncValue.data(announcements);
    } catch (e, st) {
      print('DEBUG: Announcement fetch error: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createAnnouncement({
    required String title,
    required String content, // In UI called 'content', maps to SQL 'message'
  }) async {
    if (_admin == null) return;
    try {
      // 🎯 THE FIX: Use 'message' and 'created_by' column names from SQL
      await _supabase.from(AppConstants.announcementsTable).insert({
        'title': title,
        'message': content,
        'institute_id': _admin!.instituteId,
        'created_by': _admin!.id,
      });
      await fetchAnnouncements();
    } catch (e, st) {
      print('DEBUG: Announcement create error: $e');
      rethrow;
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    try {
      await _supabase.from(AppConstants.announcementsTable).delete().eq('id', id);
      await fetchAnnouncements();
    } catch (e) {
      rethrow;
    }
  }
}

final announcementProvider = 
    StateNotifierProvider<AnnouncementNotifier, AsyncValue<List<AnnouncementModel>>>((ref) {
  return AnnouncementNotifier(
    ref.watch(supabaseProvider),
    ref.watch(currentUserProvider),
  );
});
