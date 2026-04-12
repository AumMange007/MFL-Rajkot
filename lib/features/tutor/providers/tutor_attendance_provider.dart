import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/tutor_attendance_model.dart';
import '../../auth/providers/auth_provider.dart';

class StaffAttendanceNotifier extends StateNotifier<AsyncValue<StaffAttendanceModel?>> {
  final SupabaseClient _supabase;
  final String? _userId;
  final Ref _ref;

  StaffAttendanceNotifier(this._supabase, this._userId, this._ref) : super(const AsyncValue.loading()) {
    checkCurrentStatus();
  }

  Future<void> checkCurrentStatus() async {
    if (_userId == null) return;
    try {
      final data = await _supabase
          .from(AppConstants.staffAttendanceTable)
          .select()
          .eq('user_id', _userId!)
          .isFilter('punch_out_at', null)
          .maybeSingle();

      if (data == null) {
        state = const AsyncValue.data(null);
        return;
      }

      state = AsyncValue.data(StaffAttendanceModel.fromJson(data));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> punchIn() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      // 1. Get current location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      final Position pos = await Geolocator.getCurrentPosition();
      
      // 🔄 SELF-HEALING: If user has no institute_id, auto-link to the first available one
      String? instId = user.instituteId;
      if (instId == null || instId.isEmpty) {
        final firstInst = await _supabase.from(AppConstants.institutesTable).select('id').limit(1).maybeSingle();
        if (firstInst != null) {
          instId = firstInst['id'];
          await _supabase.from(AppConstants.usersTable).update({'institute_id': instId}).eq('id', user.id);
          // 🔄 Force refresh the user profile so the app knows it's fixed
          _ref.invalidate(currentUserProvider);
        }
      }

      // 2. Get institute location (Fallback to hardcoded MFL Studio if DB is empty or missing data)
      final instData = instId != null 
          ? await _supabase.from(AppConstants.institutesTable).select('latitude, longitude, radius_meters').eq('id', instId).maybeSingle()
          : null;
      
      // 🎯 MASTER FALLBACK: Use MFL Studio Rajkot coordinates as safety net
      final double instLat = instData?['latitude']?.toDouble() ?? 22.2831511;
      final double instLng = instData?['longitude']?.toDouble() ?? 70.7741323;
      final int radius = instData?['radius_meters'] as int? ?? 150;

      final double distance = Geolocator.distanceBetween(pos.latitude, pos.longitude, instLat, instLng);
      final bool isOnPremise = distance <= radius;

      if (!isOnPremise) {
        throw 'Attendance Denied: Please ensure you are inside the MFL English Studio premises to punch in. (Distance: ${distance.toStringAsFixed(0)}m)';
      }

      // 3. Insert record
      final now = DateTime.now();
      final data = await _supabase.from(AppConstants.staffAttendanceTable).insert({
        'user_id': user.id,
        'institute_id': user.instituteId,
        'punch_in_at': now.toIso8601String(),
        'date': now.toIso8601String().split('T')[0],
        'location_lat': pos.latitude,
        'location_lng': pos.longitude,
        'is_on_premise': isOnPremise,
      }).select().single();

      state = AsyncValue.data(StaffAttendanceModel.fromJson(data));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> punchOut() async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      await _supabase.from(AppConstants.staffAttendanceTable).update({
        'punch_out_at': now.toIso8601String(),
      }).eq('id', current.id);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final tutorAttendanceProvider = 
    StateNotifierProvider<StaffAttendanceNotifier, AsyncValue<StaffAttendanceModel?>>((ref) {
  final user = ref.watch(currentUserProvider);
  return StaffAttendanceNotifier(ref.watch(supabaseProvider), user?.id, ref);
});
