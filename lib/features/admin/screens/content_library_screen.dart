import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_stats_provider.dart';

class ContentLibraryScreen extends ConsumerWidget {
  const ContentLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final canUpload = user?.role == 'admin' || user?.role == 'tutor';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text('Content Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => (context as Element).markNeedsBuild(),
          ),
        ],
      ),
      floatingActionButton: canUpload ? FloatingActionButton.extended(
        onPressed: () => _showAddContentSheet(context, ref),
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('Add Content'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ) : null,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: Supabase.instance.client
            .from('content_library')
            .select()
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorState(message: snapshot.error.toString());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.video_library_rounded,
              title: 'Library is empty',
              subtitle: 'Upload PDFs, notes or images for your students.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              (context as Element).markNeedsBuild();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _LibraryItemTile(
                  item: item,
                  onDeleted: () => (context as Element).markNeedsBuild(),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showAddContentSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddContentSheet(),
    );
  }
}

class _LibraryItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDeleted;
  const _LibraryItemTile({required this.item, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final String type = item['type'] ?? 'pdf';
    final IconData icon = _getIcon(type);
    final Color color = _getColor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            item['title'] ?? 'Untitled', 
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF0F172A))
          ),
          subtitle: Text(
            '${type.toUpperCase()} • Added ${_formatDate(item['created_at'])}', 
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                onPressed: () => _deleteContent(context),
              ),
              const Icon(Icons.open_in_new_rounded, color: Color(0xFF94A3B8), size: 20),
            ],
          ),
          onTap: () => _openContent(context),
        ),
      ),
    );
  }

  Future<void> _deleteContent(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource?'),
        content: const Text('This will remove the content for all students.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await Supabase.instance.client.from('content_library').delete().eq('id', item['id']);
        onDeleted();
      } catch (e) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _openContent(BuildContext context) async {
    final String? fileUrl = item['file_url'];
    if (fileUrl == null || fileUrl.isEmpty) return;
    final url = Uri.parse(fileUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open file URL')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'video': return Icons.play_circle_filled_rounded;
      case 'image': return Icons.image_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'pdf': return const Color(0xFFEF4444);
      case 'video': return const Color(0xFF0EA5E9);
      case 'image': return const Color(0xFFF59E0B);
      default: return const Color(0xFF6366F1);
    }
  }

  String _formatDate(String iso) {
    final dt = DateTime.parse(iso);
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _AddContentSheet extends ConsumerStatefulWidget {
  const _AddContentSheet();

  @override
  ConsumerState<_AddContentSheet> createState() => _AddContentSheetState();
}

class _AddContentSheetState extends ConsumerState<_AddContentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  PlatformFile? _pickedFile;
  XFile? _pickedImage;
  String _mode = 'image'; // 'image' or 'file'
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
         _pickedImage = image;
         _pickedFile = null;
         _mode = 'image';
         if (_titleCtrl.text.isEmpty) {
           _titleCtrl.text = image.name;
         }
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt'],
    );
    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
        _pickedImage = null;
        _mode = 'file';
        if (_titleCtrl.text.isEmpty) {
          _titleCtrl.text = _pickedFile!.name;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFile == null && _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file or image')));
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final fileName = const Uuid().v4();
      String publicUrl = '';
      String type = 'pdf';

      if (_mode == 'image' && _pickedImage != null) {
         type = 'image';
         final bytes = await _pickedImage!.readAsBytes();
         final ext = _pickedImage!.path.split('.').last;
         final path = '${user.instituteId}/$fileName.$ext';
         
         await supabase.storage.from('content').uploadBinary(path, bytes);
         publicUrl = supabase.storage.from('content').getPublicUrl(path);
      } else if (_mode == 'file' && _pickedFile != null) {
         type = _pickedFile!.extension?.toLowerCase() == 'pdf' ? 'pdf' : 'other';
         final path = '${user.instituteId}/$fileName.${_pickedFile!.extension}';
         
         if (kIsWeb) {
            await supabase.storage.from('content').uploadBinary(path, _pickedFile!.bytes!);
         } else {
            await supabase.storage.from('content').upload(path, File(_pickedFile!.path!));
         }
         publicUrl = supabase.storage.from('content').getPublicUrl(path);
      }

      await supabase.from('content_library').insert({
        'title': _titleCtrl.text.trim(),
        'file_url': publicUrl,
        'type': type,
        'uploaded_by': user.id,
        'institute_id': user.instituteId,
      });

      ref.invalidate(adminStatsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
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
              Text('Upload Resource', 
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Text('Pick an image or document from your gallery to share.', 
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _PickButton(
                      label: 'PICK IMAGE',
                      icon: Icons.image_rounded,
                      isActive: _mode == 'image',
                      onTap: _pickImage,
                      selectedName: _pickedImage?.name,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickButton(
                      label: 'PICK PDF/DOC',
                      icon: Icons.picture_as_pdf_rounded,
                      isActive: _mode == 'file',
                      onTap: _pickFile,
                      selectedName: _pickedFile?.name,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleCtrl, 
                style: GoogleFonts.inter(fontSize: 14),
                decoration: const InputDecoration(labelText: 'Display Title', prefixIcon: Icon(Icons.title_rounded)),
                validator: (v) => v == null || v.isEmpty ? 'Please give it a title' : null,
              ),

              const SizedBox(height: 40),
              FilledButton(
                onPressed: _isLoading ? null : _submit, 
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Text('UPLOAD AND PUBLISH'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final String? selectedName;

  const _PickButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.selectedName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4F46E5).withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8), size: 28),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8))),
            if (isActive && selectedName != null) ...[
              const SizedBox(height: 4),
              Text(selectedName!, maxLines: 1, overflow: TextOverflow.ellipsis, 
                  style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF4F46E5).withOpacity(0.6))),
            ]
          ],
        ),
      ),
    );
  }
}
