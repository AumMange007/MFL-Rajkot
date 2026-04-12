import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/user_model.dart';
import '../../common/providers/profile_photo_provider.dart';

class ForceProfileFillScreen extends ConsumerStatefulWidget {
  const ForceProfileFillScreen({super.key});

  @override
  ConsumerState<ForceProfileFillScreen> createState() => _ForceProfileFillScreenState();
}

class _ForceProfileFillScreenState extends ConsumerState<ForceProfileFillScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Student fields
  final _levelCtrl = TextEditingController();
  final _langCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _parentMobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  
  // Tutor fields
  final _bioCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();

  bool _isLoading = false;
  late UserModel _user;

  @override
  void initState() {
    super.initState();
    _user = ref.read(currentUserProvider)!;
    if (_user.phone != null) {
      _mobileCtrl.text = _user.phone!;
    }
  }

  @override
  void dispose() {
    _levelCtrl.dispose();
    _langCtrl.dispose();
    _mobileCtrl.dispose();
    _parentMobileCtrl.dispose();
    _addressCtrl.dispose();
    _dobCtrl.dispose();
    _bioCtrl.dispose();
    _experienceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final supabase = ref.read(supabaseProvider);
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) throw 'Not authenticated';

      // 1. Update public.users
      await supabase.from(AppConstants.usersTable).update({
        'is_profile_complete': true,
        'phone': _mobileCtrl.text.trim(),
      }).eq('id', userId);
      
      // 2. Role specific table update
      if (_user.role == 'student') {
        await supabase.from(AppConstants.studentsTable).update({
          'institute_id': _user.instituteId,
          'level': _levelCtrl.text.isEmpty ? 'A1' : _levelCtrl.text,
          'language': _langCtrl.text.isEmpty ? 'German' : _langCtrl.text,
          'mobile': _mobileCtrl.text.trim(),
          'parent_mobile': _parentMobileCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
          'dob': _dobCtrl.text.trim(),
        }).eq('user_id', userId);
      } else if (_user.role == 'tutor') {
        await supabase.from('tutors').update({
          'institute_id': _user.instituteId,
          'mobile': _mobileCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
          'dob': _dobCtrl.text.trim(),
          'bio': _bioCtrl.text.trim(),
          'experience': _experienceCtrl.text.trim(),
        }).eq('user_id', userId);
      }
      
      // Refresh Auth User state
      await ref.read(authNotifierProvider.notifier).refreshUser();
      
    } catch (e) {
      print('DEBUG: Profile completion failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Complete Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Profile Photo Section
                  Center(
                    child: Stack(
                      children: [
                        Consumer(builder: (ctx, ref, _) {
                          final state = ref.watch(profilePhotoProvider);
                          return CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.indigo.withOpacity(0.1),
                            backgroundImage: _user.avatarUrl != null ? NetworkImage(_user.avatarUrl!) : null,
                            child: _user.avatarUrl == null ? const Icon(Icons.person, size: 45, color: Colors.indigo) : null,
                          );
                        }),
                        Positioned(
                          bottom: 0, right: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.indigo,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                              onPressed: () => ref.read(profilePhotoProvider.notifier).uploadForUser(_user.id),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Profile Details Required', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Tell us more about yourself to get started.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 32),
                  
                  _buildField(_mobileCtrl, 'Mobile Number', Icons.phone, TextInputType.phone),
                  _buildField(_addressCtrl, 'Address', Icons.location_on),
                  _buildField(_dobCtrl, 'Date of Birth (DD-MM-YYYY)', Icons.calendar_today),
                  
                  if (_user.role == 'student') ...[
                    _buildField(_parentMobileCtrl, 'Parent Mobile', Icons.people, TextInputType.phone),
                  ],
                  if (_user.role == 'tutor') ...[
                    _buildField(_bioCtrl, 'Short Bio', Icons.info, TextInputType.multiline, 3),
                    _buildField(_experienceCtrl, 'Experience (Years)', Icons.history, TextInputType.number),
                  ],

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Profile & Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, [TextInputType? type, int maxLines = 1]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
      ),
    );
  }
}
