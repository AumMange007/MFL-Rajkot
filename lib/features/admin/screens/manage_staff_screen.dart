import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/common_widgets.dart';
import '../../../models/user_model.dart';
import '../providers/staff_management_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/screens/chat_screen.dart';
import '../../common/providers/profile_photo_provider.dart';

class ManageStaffScreen extends ConsumerStatefulWidget {
  const ManageStaffScreen({super.key});

  @override
  ConsumerState<ManageStaffScreen> createState() => _ManageStaffScreenState();
}

class _ManageStaffScreenState extends ConsumerState<ManageStaffScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staffState = ref.watch(staffManagementProvider);
    final user = ref.watch(currentUserProvider);
    final isSuperAdmin = user?.isManager ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        title: Text(isSuperAdmin ? 'Manage Staff & Tutors' : 'Tutor Directory'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: isSuperAdmin ? 'Search staff or tutors...' : 'Search tutors by name...',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStaffSheet(context, isSuperAdmin),
        icon: const Icon(Icons.add_moderator_rounded),
        label: Text(isSuperAdmin ? 'Add Staff' : 'Add Tutor'),
      ),
      body: staffState.when(
        data: (staff) {
          final baseList = isSuperAdmin ? staff : staff.where((s) => s.role == 'tutor').toList();
          final filtered = baseList.where((s) {
            final name = (s.name).toLowerCase();
            return name.contains(_searchQuery);
          }).toList();

          if (baseList.isEmpty) {
             return EmptyState(icon: Icons.badge_outlined, title: 'No entries', subtitle: isSuperAdmin ? 'Invite staff members' : 'No tutors found');
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(staffManagementProvider.notifier).fetchStaff(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: filtered.length,
              itemBuilder: (context, index) => _StaffListItem(member: filtered[index], canManage: isSuperAdmin || filtered[index].role == 'tutor'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.read(staffManagementProvider.notifier).fetchStaff()),
      ),
    );
  }

  void _showAddStaffSheet(BuildContext context, bool isSuperAdmin) {
    showModalBottomSheet(context: context, isScrollControlled: true, useRootNavigator: true, builder: (_) => AddStaffSheet(isSuperAdmin: isSuperAdmin));
  }
}

class _StaffListItem extends ConsumerWidget {
  final UserModel member;
  final bool canManage;
  const _StaffListItem({required this.member, required this.canManage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleColor = member.role == 'tutor' ? const Color(0xFF0EA5E9) : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showProfile(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFF1F5F9),
                  backgroundImage: member.avatarUrl != null ? CachedNetworkImageProvider(member.avatarUrl!) : null,
                  child: member.avatarUrl == null ? Text(member.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: roleColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(member.roleLabel.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: roleColor)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(member.username ?? member.email, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF0284C7), size: 18), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(otherUser: member)))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfile(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, useRootNavigator: true, backgroundColor: Colors.transparent, builder: (_) => ManageStaffProfileSheet(staff: member));
  }
}

class ManageStaffProfileSheet extends ConsumerStatefulWidget {
  final UserModel staff;
  const ManageStaffProfileSheet({super.key, required this.staff});

  @override
  ConsumerState<ManageStaffProfileSheet> createState() => _ManageStaffProfileSheetState();
}

class _ManageStaffProfileSheetState extends ConsumerState<ManageStaffProfileSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late String _role;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.staff.name);
    _emailCtrl = TextEditingController(text: widget.staff.email);
    _phoneCtrl = TextEditingController(text: widget.staff.phone);
    _role = widget.staff.role;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      String name = _nameCtrl.text.trim();
      String effectiveRole = _role;

      if (_role == 'manager') {
        effectiveRole = 'staff';
        if (!name.toUpperCase().startsWith('[MANAGER]')) {
          name = '[MANAGER] $name';
        }
      } else {
        // If promoting/demoting AWAY from manager, remove the [MANAGER] tag if present
        name = name.replaceAll(RegExp(r'\[MANAGER\]\s*', caseSensitive: false), '');
      }

      await ref.read(staffManagementProvider.notifier).updateStaffProfile(
        userId: widget.staff.id,
        name: name,
        role: effectiveRole,
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showResetPass() async {
    final passCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Account Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manually set a new password for ${widget.staff.name}.', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => passCtrl.text.length >= 6 ? Navigator.pop(ctx, true) : null, child: const Text('RESET NOW', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(staffManagementProvider.notifier).manualResetPassword(widget.staff.id, passCtrl.text.trim());
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully! 🚀')));
      } catch (e) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _delete() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser?.id == widget.staff.id) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Self-destruction blocked! 🛡️')));
       return;
    }

    final TextEditingController confirmCtrl = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Critical: Delete User?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirm deletion of "${widget.staff.name}". This is permanent.', style: const TextStyle(fontSize: 13, color: Colors.red)),
            const SizedBox(height: 16),
            const Text('Type "DELETE" to confirm:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: confirmCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => confirmCtrl.text.trim().toUpperCase() == 'DELETE' ? Navigator.pop(ctx, true) : null, child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(staffManagementProvider.notifier).deleteStaff(widget.staff);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSuperAdmin = ref.watch(currentUserProvider)?.isManager ?? false;

    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      padding: EdgeInsets.fromLTRB(28, 20, 28, MediaQuery.of(context).viewInsets.bottom + 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFFF1F5F9),
                      backgroundImage: widget.staff.avatarUrl != null ? CachedNetworkImageProvider(widget.staff.avatarUrl!) : null,
                      child: widget.staff.avatarUrl == null ? const Icon(Icons.person, size: 30) : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: () => ref.read(profilePhotoProvider.notifier).uploadForUser(widget.staff.id),
                        child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Color(0xFF0284C7), shape: BoxShape.circle), child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.staff.name, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
                      Text(widget.staff.roleLabel, style: GoogleFonts.inter(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (isSuperAdmin) IconButton.filledTonal(onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded, color: Colors.red), style: IconButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1))),
              ],
            ),
            const SizedBox(height: 32),
            Text('PERSONAL DETAILS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey)),
            const SizedBox(height: 16),
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 16),
            TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 16),
            TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_android_rounded))),
            if (isSuperAdmin) ...[
              const SizedBox(height: 32),
              Text('ACCESS & ROLES', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: widget.staff.isManager ? 'manager' : _role,
                decoration: const InputDecoration(labelText: 'Assigned Role', prefixIcon: Icon(Icons.verified_user_outlined)),
                items: const [
                  DropdownMenuItem(value: 'tutor', child: Text('Teacher / Tutor')),
                  DropdownMenuItem(value: 'staff', child: Text('Operational Staff')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager (Support Lead) 🛡️')),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
            ],
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _showResetPass,
              icon: const Icon(Icons.lock_reset_rounded, color: Colors.red),
              label: const Text('MANUAL PASSWORD OVERRIDE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isLoading ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text(_isLoading ? 'SAVING...' : 'SAVE PROFILE UPDATES'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddStaffSheet extends ConsumerStatefulWidget {
  final bool isSuperAdmin;
  const AddStaffSheet({super.key, required this.isSuperAdmin});
  @override
  ConsumerState<AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends ConsumerState<AddStaffSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _unameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  late String _role;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _role = 'tutor';
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      padding: EdgeInsets.fromLTRB(28, 20, 28, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 24),
              Text(widget.isSuperAdmin ? 'Add Staff or Tutor' : 'Register New Tutor', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 32),
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 16),
              TextFormField(controller: _unameCtrl, decoration: const InputDecoration(labelText: 'Login ID', prefixIcon: Icon(Icons.alternate_email))),
              const SizedBox(height: 16),
              TextFormField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)), obscureText: true),
              const SizedBox(height: 16),
              if (widget.isSuperAdmin) ...[
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'User Role', prefixIcon: Icon(Icons.security)),
                  items: const [
                    DropdownMenuItem(value: 'tutor', child: Text('Teacher / Tutor')),
                    DropdownMenuItem(value: 'staff', child: Text('Operational Staff')),
                    DropdownMenuItem(value: 'manager', child: Text('Manager (Support Lead) 🛡️')),
                  ],
                  onChanged: (v) => setState(() => _role = v!),
                ),
              ],
              const SizedBox(height: 40),
              FilledButton(onPressed: _isLoading ? null : _submit, child: Text(_isLoading ? 'CREATING...' : 'REGISTER ACCOUNT')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      String name = _nameCtrl.text.trim();
      String effectiveRole = _role;
      
      // If Manager is selected, use 'staff' role but tag the name for our Smart Convention
      if (_role == 'manager') {
        effectiveRole = 'staff';
        if (!name.toUpperCase().startsWith('[MANAGER]')) {
          name = '[MANAGER] $name';
        }
      }

      await ref.read(staffManagementProvider.notifier).addStaff(
        name: name,
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        username: _unameCtrl.text.trim(),
        password: _passCtrl.text,
        role: effectiveRole,
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
