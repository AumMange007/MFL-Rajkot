import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/permission_service.dart';
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
          .eq('user_id', _userId)
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
      // 1. Unified Permission Request (Fixes "Permission Gap")
      final hasPermission = await PermissionService.requestLocationPermission();
      if (!hasPermission) {
        throw 'Location permission is required to verify your attendance at the institute.';
      }
      
      final Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      
      // 🔄 Secure Institute Identification
      String? instId = user.instituteId;
      if (instId.isEmpty) {
        throw 'Authentication Error: Profile not linked to an institute. Contact Admin.';
      }

      // 2. Verified Geofencing
      final instData = await _supabase.from(AppConstants.institutesTable).select('latitude, longitude, radius_meters').eq('id', instId).maybeSingle();
      
      // Rajkot MFL Studio Defaults
      final double instLat = instData?['latitude']?.toDouble() ?? 22.287233;
      final double instLng = instData?['longitude']?.toDouble() ?? 70.778848;
      final int radius = instData?['radius_meters'] as int? ?? 500; // Expanded for better reliability

      final double distance = Geolocator.distanceBetween(pos.latitude, pos.longitude, instLat, instLng);
      final bool isOnPremise = distance <= radius;

      // Geofencing Restored only for manager
      if (!isOnPremise && user.isManager) {
        throw 'Attendance Restricted: Managers must be within ${radius}m to punch in. Currently at: ${distance.toInt()}m';
      }

      // 3. Secure Insert
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
      state = const AsyncValue.data(null);
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
      state = AsyncValue.data(current);
      rethrow;
    }
  }
}

final tutorAttendanceProvider = 
    StateNotifierProvider<StaffAttendanceNotifier, AsyncValue<StaffAttendanceModel?>>((ref) {
  final user = ref.watch(currentUserProvider);
  return StaffAttendanceNotifier(ref.watch(supabaseProvider), user?.id, ref);
});
