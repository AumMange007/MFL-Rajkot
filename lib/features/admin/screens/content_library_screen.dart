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
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_stats_provider.dart';
import '../providers/batch_management_provider.dart';
import '../../../core/utils/file_utils.dart';

class ContentLibraryScreen extends ConsumerStatefulWidget {
  const ContentLibraryScreen({super.key});
  @override
  ConsumerState<ContentLibraryScreen> createState() => _ContentLibraryScreenState();
}

class _ContentLibraryScreenState extends ConsumerState<ContentLibraryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final canUpload = user?.role == 'admin' || user?.role == 'tutor';
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      floatingActionButton: canUpload
          ? FloatingActionButton.extended(
              onPressed: () => _showAddContentSheet(context, ref),
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_a_photo_rounded),
              label: Text('Add Content', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: const Color(0xFF0284C7),
            actions: [
              IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: () => setState(() {})),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0369A1), Color(0xFF0891B2)])),
                padding: const EdgeInsets.fromLTRB(24, 90, 24, 20),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.video_library_rounded, color: Colors.white, size: 22)),
                    const SizedBox(width: 14),
                    Text('Content Library', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search files…',
                    hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8)), onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); })
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true, fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),
          // Content List
          SliverToBoxAdapter(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: Supabase.instance.client.from('content_library').select().eq('institute_id', user?.instituteId ?? '').order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.only(top: 60), child: Center(child: CircularProgressIndicator(color: Color(0xFF0284C7))));
                if (snapshot.hasError) return ErrorState(message: snapshot.error.toString());
                var items = snapshot.data ?? [];
                if (_searchQuery.isNotEmpty) items = items.where((item) => (item['title'] ?? '').toString().toLowerCase().contains(_searchQuery)).toList();
                if (items.isEmpty) return EmptyState(icon: _searchQuery.isEmpty ? Icons.video_library_rounded : Icons.search_off_rounded, title: _searchQuery.isEmpty ? 'Library is empty' : 'No matches found', subtitle: _searchQuery.isEmpty ? 'Upload PDFs, notes or images for your students.' : 'Try a different search term.');
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  child: Column(
                    children: items.map((item) => _LibraryItemTile(item: item, onDeleted: () => setState(() {}))).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddContentSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(context: context, isScrollControlled: true, useRootNavigator: true, backgroundColor: Colors.transparent, builder: (_) => const _AddContentSheet()).then((_) => setState(() {}));
  }
}

class _LibraryItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDeleted;
  const _LibraryItemTile({required this.item, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final String type  = item['type'] ?? 'pdf';
    final IconData icon = _getIcon(type);
    final Color color  = _getColor(type);
    final String title  = item['title'] ?? 'Untitled';
    final String dateStr = _formatDate(item['created_at'] ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openContent(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Type icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Row(children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(type.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: color))),
                        const SizedBox(width: 6),
                        Text('Added $dateStr', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                      ]),
                    ],
                  ),
                ),
                // Action buttons
                Row(children: [
                  _IconAction(icon: Icons.share_rounded, color: const Color(0xFF0891B2), onTap: () => FileUtils.downloadAndShare(item['file_url']!, item['title'] ?? 'Download')),
                  const SizedBox(width: 6),
                  _IconAction(icon: Icons.delete_outline_rounded, color: const Color(0xFFEF4444), onTap: () => _deleteContent(context)),
                  const SizedBox(width: 6),
                  _IconAction(icon: Icons.open_in_new_rounded, color: const Color(0xFF64748B), onTap: () => _openContent(context)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openContent(BuildContext context) async {
    final String? fileUrl = item['file_url'];
    if (fileUrl == null || fileUrl.isEmpty) return;
    if (item['type'] == 'image') { _showFullScreenImage(context, fileUrl); return; }
    final url = Uri.parse(fileUrl);
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalNonBrowserApplication);
      if (!launched) await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showFullScreenImage(BuildContext context, String url) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white), actions: [
      IconButton(icon: const Icon(Icons.share_rounded), onPressed: () => FileUtils.downloadAndShare(url, 'Admin_Photo'))
    ]), body: Center(child: Hero(tag: url, child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain, placeholder: (context, url) => const CircularProgressIndicator()))))));
  }

  IconData _getIcon(String type) => switch (type) { 'pdf' => Icons.picture_as_pdf_rounded, 'video' => Icons.play_circle_filled_rounded, 'image' => Icons.image_rounded, _ => Icons.insert_drive_file_rounded };
  Color _getColor(String type) => switch (type) { 'pdf' => const Color(0xFFEF4444), 'video' => const Color(0xFF0EA5E9), 'image' => const Color(0xFFF59E0B), _ => const Color(0xFF6366F1) };
  String _formatDate(String iso) { final dt = DateTime.parse(iso); return '${dt.day}/${dt.month}/${dt.year}'; }
  Future<void> _deleteContent(BuildContext context) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: Text('Delete Resource?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)), content: const Text('This will remove the content for all students.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete'))]));
    if (confirmed == true) { try { await Supabase.instance.client.from('content_library').delete().eq('id', item['id']); onDeleted(); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating)); } }
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconAction({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, color: color, size: 16),
    ),
  );
}


// ... (_AddContentSheet and _PickButton remain same)
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
  String _mode = 'image';
  bool _isLoading = false;
  final List<String> _selectedBatchIds = [];
  @override
  void dispose() { _titleCtrl.dispose(); super.dispose(); }
  Future<void> _pickImage() async { final picker = ImagePicker(); final image = await picker.pickImage(source: ImageSource.gallery); if (image != null) setState(() { _pickedImage = image; _pickedFile = null; _mode = 'image'; if (_titleCtrl.text.isEmpty) _titleCtrl.text = image.name; }); }
  Future<void> _pickFile() async { final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx', 'ppt']); if (result != null) setState(() { _pickedFile = result.files.first; _pickedImage = null; _mode = 'file'; if (_titleCtrl.text.isEmpty) _titleCtrl.text = _pickedFile!.name; }); }
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFile == null && _pickedImage == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file'))); return; }
    if (_selectedBatchIds.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a batch'))); return; }
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final fileName = const Uuid().v4();
      String publicUrl = '';
      String type = 'pdf';
      if (_mode == 'image' && _pickedImage != null) {
         type = 'image'; final bytes = await _pickedImage!.readAsBytes(); final ext = _pickedImage!.path.split('.').last; final path = '${user.instituteId}/$fileName.$ext'; await supabase.storage.from('content').uploadBinary(path, bytes); publicUrl = supabase.storage.from('content').getPublicUrl(path);
      } else if (_mode == 'file' && _pickedFile != null) {
         type = _pickedFile!.extension?.toLowerCase() == 'pdf' ? 'pdf' : 'other'; final path = '${user.instituteId}/$fileName.${_pickedFile!.extension}'; if (kIsWeb) {
           await supabase.storage.from('content').uploadBinary(path, _pickedFile!.bytes!);
         } else {
           await supabase.storage.from('content').upload(path, File(_pickedFile!.path!));
         } publicUrl = supabase.storage.from('content').getPublicUrl(path);
      }
      final contentRes = await supabase.from('content_library').insert({'title': _titleCtrl.text.trim(), 'file_url': publicUrl, 'type': type, 'uploaded_by': user.id, 'institute_id': user.instituteId}).select().single();
      final String contentId = contentRes['id'];
      final assignments = _selectedBatchIds.map((bid) => {'content_id': contentId, 'batch_id': bid, 'institute_id': user.instituteId, 'assigned_by': user.id}).toList();
      await supabase.from('batch_content').insert(assignments);
      ref.invalidate(adminStatsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'))); } finally { if (mounted) setState(() => _isLoading = false); }
  }
  @override
  Widget build(BuildContext context) {
    final batchesState = ref.watch(batchManagementProvider);
    return Container( decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))), padding: EdgeInsets.fromLTRB(28, 20, 28, MediaQuery.of(context).viewInsets.bottom + 28), child: Form(key: _formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [ Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 24), Text('Upload & Assign', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))), const SizedBox(height: 4), Text('Pick a file and select which batches can see it.', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))), const SizedBox(height: 24), Row(children: [Expanded(child: _PickButton(label: 'PICK IMAGE', icon: Icons.image_rounded, isActive: _mode == 'image', onTap: _pickImage, selectedName: _pickedImage?.name)), const SizedBox(width: 12), Expanded(child: _PickButton(label: 'PICK PDF/DOC', icon: Icons.picture_as_pdf_rounded, isActive: _mode == 'file', onTap: _pickFile, selectedName: _pickedFile?.name))]), const SizedBox(height: 24), TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Display Title', prefixIcon: Icon(Icons.title_rounded)), validator: (v) => v == null || v.isEmpty ? 'Please give it a title' : null), const SizedBox(height: 24), Text('Select Batches', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))), const SizedBox(height: 12), batchesState.when(data: (list) { if (list.isEmpty) return const Text('No batches created yet.'); return Container(height: 120, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)), child: ListView.builder(padding: const EdgeInsets.symmetric(vertical: 8), itemCount: list.length, itemBuilder: (context, index) { final b = list[index]; final isSelected = _selectedBatchIds.contains(b.id); return CheckboxListTile(title: Text(b.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)), value: isSelected, onChanged: (val) { setState(() { if (val == true) {
      _selectedBatchIds.add(b.id);
    } else {
      _selectedBatchIds.remove(b.id);
    } }); }, controlAffinity: ListTileControlAffinity.leading); })); }, loading: () => const LinearProgressIndicator(), error: (e, _) => Text('Error: $e')), const SizedBox(height: 32), FilledButton(onPressed: _isLoading ? null : _submit, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('UPLOAD AND ASSIGN')) ]))));
  }
}
class _PickButton extends StatelessWidget { final String label; final IconData icon; final bool isActive; final VoidCallback onTap; final String? selectedName; const _PickButton({required this.label, required this.icon, required this.isActive, required this.onTap, this.selectedName}); @override Widget build(BuildContext context) { return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isActive ? const Color(0xFF0284C7).withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isActive ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0), width: 1.5)), child: Column(children: [Icon(icon, color: isActive ? const Color(0xFF0284C7) : const Color(0xFF94A3B8), size: 28), const SizedBox(height: 8), Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: isActive ? const Color(0xFF0284C7) : const Color(0xFF94A3B8))), if (isActive && selectedName != null) ...[const SizedBox(height: 4), Text(selectedName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF0284C7).withOpacity(0.6)))]]))); } }
