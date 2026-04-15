import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coaching_app/models/lead_model.dart';
import 'package:coaching_app/features/auth/providers/auth_provider.dart';

final leadsProvider =
    StateNotifierProvider<LeadsNotifier, AsyncValue<List<LeadModel>>>((ref) {
  final supabase = ref.watch(supabaseProvider);
  // Use Future.microtask to avoid calling async during widget build
  final notifier = LeadsNotifier(supabase);
  Future.microtask(() => notifier.fetchLeads());
  return notifier;
});

class LeadsNotifier extends StateNotifier<AsyncValue<List<LeadModel>>> {
  final SupabaseClient _supabase;

  LeadsNotifier(this._supabase) : super(const AsyncValue.loading());

  Future<void> fetchLeads() async {
    state = const AsyncValue.loading();
    try {
      final data = await _supabase
          .from('leads')
          .select()
          .order('created_at', ascending: false);
      state = AsyncValue.data(
          (data as List).map((e) => LeadModel.fromMap(e)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addLead(LeadModel lead) async {
    try {
      await _supabase.from('leads').insert(lead.toMap());
      await fetchLeads();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      await _supabase.from('leads').update({'status': status}).eq('id', id);
      await fetchLeads();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateLead(String id, Map<String, dynamic> updates) async {
    try {
      await _supabase.from('leads').update(updates).eq('id', id);
      await fetchLeads();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> seedDummyLeads() async {
    final dummyLeads = [
      {'name': 'Aum', 'phone': '9265480160', 'email': 'aum@example.com', 'interested_in': 'Advanced Flutter', 'source': 'Developer Direct', 'status': 'potential', 'notes': 'Primary stakeholder'},
      {'name': 'Rajesh Kumar', 'phone': '9876543210', 'email': 'rajesh@example.com', 'interested_in': 'Mathematics JEE', 'source': 'Google Search', 'status': 'new', 'notes': 'Looking for evening batches'},
      {'name': 'Priya Sharma', 'phone': '8765432109', 'email': 'priya@example.com', 'interested_in': 'Physics Intensive', 'source': 'Word of Mouth', 'status': 'contacted', 'notes': 'Interested in crash course'},
      {'name': 'Amit Patel', 'phone': '7654321098', 'email': 'amit@example.com', 'interested_in': 'Chemistry NEET', 'source': 'Instagram Ad', 'status': 'potential', 'notes': 'Demo class scheduled for Saturday'},
      {'name': 'Sneha Gupta', 'phone': '6543210987', 'email': 'sneha@example.com', 'interested_in': 'Foundation Course', 'source': 'Flyer', 'status': 'enrolled', 'notes': 'Paid full fees upfront'},
      {'name': 'Anil Verma', 'phone': '5432109876', 'email': 'anil@example.com', 'interested_in': 'Biology Advanced', 'source': 'Newspaper', 'status': 'dropped', 'notes': 'Joined another institute closer to home'},
    ];

    try {
      await _supabase.from('leads').insert(dummyLeads);
      await fetchLeads();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteLead(String id) async {
    try {
      await _supabase.from('leads').delete().eq('id', id);
      await fetchLeads();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
