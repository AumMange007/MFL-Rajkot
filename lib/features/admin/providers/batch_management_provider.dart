import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/batch_model.dart';
import '../../../models/user_model.dart';
import 'admin_stats_provider.dart';
import '../../auth/providers/auth_provider.dart';

// ── Batch Management State ───────────────────────────────────────────────────
class BatchManagementNotifier extends StateNotifier<AsyncValue<List<BatchModel>>> {
  final SupabaseClient _supabase;
  final UserModel? _admin;
  final Ref _ref;

  BatchManagementNotifier(this._supabase, this._admin, this._ref) : super(const AsyncValue.loading()) {
    fetchBatches();
  }

  Future<void> fetchBatches() async {
    if (_admin == null) return;
    state = const AsyncValue.loading();
    _ref.invalidate(adminStatsProvider);
    try {
      final data = await _supabase
          .from(AppConstants.batchesTable)
          .select('*, batch_tutors(tutor_id, users:tutor_id(name))')
          .eq('institute_id', _admin!.instituteId)
          .order('name');
      
      final batches = (data as List).map((e) => BatchModel.fromJson(e)).toList();
      state = AsyncValue.data(batches);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addBatch({
    required String name,
    required List<String> tutorIds,
  }) async {
    if (_admin == null) return;
    try {
      // 1. Insert Batch
      final batchRes = await _supabase.from(AppConstants.batchesTable).insert({
        'name': name,
        'institute_id': _admin!.instituteId,
      }).select().single();

      final batchId = batchRes['id'] as String;

      // 2. Insert Junction records
      if (tutorIds.isNotEmpty) {
        final junctionRecords = tutorIds.map((tid) => {
          'batch_id': batchId,
          'tutor_id': tid,
          'institute_id': _admin!.instituteId,
        }).toList();

        await _supabase.from('batch_tutors').insert(junctionRecords);
      }

      await fetchBatches();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBatch({
    required String batchId,
    required String name,
    required List<String> tutorIds,
  }) async {
    try {
      // 1. Update Batch name
      await _supabase.from(AppConstants.batchesTable).update({
        'name': name,
      }).eq('id', batchId);

      // 2. Sync Junction records (easiest way: delete all and re-insert)
      await _supabase.from('batch_tutors').delete().eq('batch_id', batchId);
      
      if (tutorIds.isNotEmpty) {
        final junctionRecords = tutorIds.map((tid) => {
          'batch_id': batchId,
          'tutor_id': tid,
          'institute_id': _admin!.instituteId,
        }).toList();

        await _supabase.from('batch_tutors').insert(junctionRecords);
      }

      await fetchBatches();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBatch(BatchModel batch) async {
    try {
      await _supabase.from(AppConstants.batchesTable).delete().eq('id', batch.id);
      await fetchBatches();
    } catch (e) {
      rethrow;
    }
  }
}

final batchManagementProvider = 
    StateNotifierProvider<BatchManagementNotifier, AsyncValue<List<BatchModel>>>((ref) {
  return BatchManagementNotifier(
    ref.watch(supabaseProvider),
    ref.watch(currentUserProvider),
    ref,
  );
});
