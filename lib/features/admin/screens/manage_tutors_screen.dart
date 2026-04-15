import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/common_widgets.dart';
import '../../../models/user_model.dart';
import '../providers/tutor_management_provider.dart';
import '../../common/providers/profile_photo_provider.dart';
import '../../common/providers/attendance_summary_provider.dart';

// ─── Role colour ────────────────────────────────────────────────
const _kAccent  = Color(0xFF0891B2);  // Tutor cyan
const _kAccent2 = Color(0xFF0D5B78);
const _kBg      = Color(0xFFF0F9FF);

class ManageTutorsScreen extends ConsumerWidget {
  const ManageTutorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutorsState = ref.watch(tutorManagementProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: _kAccent,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [_kAccent, _kAccent2],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 90, 24, 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Manage Tutors', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                        tutorsState.maybeWhen(
                          data: (list) => Text('${list.length} educators', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: () => ref.refresh(tutorManagementProvider)),
            ],
          ),

          // ── Body ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: tutorsState.when(
              data: (tutors) {
                if (tutors.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: EmptyState(
                      icon: Icons.person_add_disabled_outlined,
                      title: 'No tutors yet',
                      subtitle: 'Add tutors to start creating batches.',
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: tutors.map((t) => _TutorCard(tutor: t)).toList(),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(child: CircularProgressIndicator(color: _kAccent)),
              ),
              error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.refresh(tutorManagementProvider)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTutorSheet(context, ref),
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Add Tutor', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showAddTutorSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTutorSheet(),
    );
  }
}

// ─── Tutor Card ───────────────────────────────────────────────────────────────
class _TutorCard extends ConsumerWidget {
  final UserModel tutor;
  const _TutorCard({required this.tutor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            GestureDetector(
              onTap: () => _showProfile(context, ref, tutor),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: _kAccent.withOpacity(0.1),
                backgroundImage: tutor.avatarUrl != null && tutor.avatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(tutor.avatarUrl!)
                    : null,
                child: tutor.avatarUrl == null || tutor.avatarUrl!.isEmpty
                    ? Text(tutor.name[0].toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: _kAccent, fontSize: 18))
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tutor.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(tutor.email, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  if (tutor.phone != null && tutor.phone!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(tutor.phone!, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                  ],
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                _ActionBtn(
                  icon: Icons.camera_alt_rounded,
                  color: _kAccent,
                  onTap: () => ProfilePhotoActions.showOptions(context: context, ref: ref, currentImageUrl: tutor.avatarUrl, targetUserId: tutor.id),
                ),
                const SizedBox(height: 6),
                _ActionBtn(
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFEF4444),
                  onTap: () => _confirmDelete(context, ref, tutor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, UserModel tutor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove Tutor?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Remove ${tutor.name}? This may affect associated batches.', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(tutorManagementProvider.notifier).deleteTutor(tutor);
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
      }
    }
  }

  void _showProfile(BuildContext context, WidgetRef ref, UserModel tutor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TutorProfileSheet(tutor: tutor),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

// ─── Tutor Profile Sheet ─────────────────────────────────────────────────────
class TutorProfileSheet extends ConsumerWidget {
  final UserModel tutor;
  const TutorProfileSheet({super.key, required this.tutor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attState = ref.watch(weeklyTutorAttendanceProvider(tutor.id));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 20),
          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: _kAccent.withOpacity(0.1),
            backgroundImage: tutor.avatarUrl != null && tutor.avatarUrl!.isNotEmpty
                ? CachedNetworkImageProvider(tutor.avatarUrl!)
                : null,
            child: tutor.avatarUrl == null || tutor.avatarUrl!.isEmpty
                ? Text(tutor.name[0].toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: _kAccent, fontSize: 28))
                : null,
          ),
          const SizedBox(height: 12),
          Text(tutor.name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
          Text(tutor.email, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
          if (tutor.phone != null && tutor.phone!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(tutor.phone!, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
          ],
          const SizedBox(height: 24),
          // Stats
          Text('LAST 7 DAYS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.8)),
          const SizedBox(height: 12),
          attState.when(
            data: (stats) => Row(
              children: [
                _StatPill(label: 'Days Active', value: stats['days_worked'].toString(), color: _kAccent),
                const SizedBox(width: 12),
                _StatPill(label: 'Hours Taught', value: stats['total_hours'].toString() + 'h', color: const Color(0xFF0891B2)),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: color.withOpacity(0.8), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Add Tutor Sheet ─────────────────────────────────────────────────────────
class AddTutorSheet extends ConsumerStatefulWidget {
  const AddTutorSheet({super.key});
  @override
  ConsumerState<AddTutorSheet> createState() => _AddTutorSheetState();
}

class _AddTutorSheetState extends ConsumerState<AddTutorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pwdCtrl   = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose(); _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(tutorManagementProvider.notifier).addTutor(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _pwdCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 20),
              // Header
              Row(children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _kAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.school_rounded, color: _kAccent, size: 20)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Add New Tutor', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                  Text('Fill in details to create an account', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                ]),
              ]),
              const SizedBox(height: 28),
              _Field(ctrl: _nameCtrl, label: 'Full Name', icon: Icons.person_rounded, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _Field(ctrl: _emailCtrl, label: 'Email Address', icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _Field(ctrl: _phoneCtrl, label: 'Phone Number', icon: Icons.phone_rounded, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pwdCtrl,
                obscureText: _obscure,
                style: GoogleFonts.inter(fontSize: 14),
                validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded), onPressed: () => setState(() => _obscure = !_obscure)),
                  filled: true, fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _kAccent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Create Tutor Account', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({required this.ctrl, required this.label, required this.icon, this.keyboardType, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true, fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      ),
    );
  }
}
