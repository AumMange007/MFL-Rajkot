import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../../widgets/common_widgets.dart';
import '../../../core/utils/file_utils.dart';

// ── Models ─────────────────────────────────────────────────────────────
class LibraryItem {
  final String id;
  final String title;
  final String type;
  final String fileUrl;
  final DateTime createdAt;
  LibraryItem({required this.id, required this.title, required this.type, required this.fileUrl, required this.createdAt});
  factory LibraryItem.fromJson(Map<String, dynamic> json) => LibraryItem(id: json['id'], title: json['title'] ?? 'Untitled', type: json['type'] ?? 'other', fileUrl: json['file_url'] ?? '', createdAt: DateTime.parse(json['created_at']));
}

// ── Providers ──────────────────────────────────────────────────────────
final libraryProvider = FutureProvider<List<LibraryItem>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  if (user.role == 'student') {
    final studentData = await supabase.from(AppConstants.studentsTable).select('batch_id').eq('user_id', user.id).maybeSingle();
    final String? batchId = studentData?['batch_id'];
    if (batchId == null) return [];
    final data = await supabase.from('batch_content').select('content_library(*)').eq('batch_id', batchId).order('assigned_at', ascending: false);
    return (data as List).where((e) => e['content_library'] != null).map((e) => LibraryItem.fromJson(e['content_library'])).toList();
  }
  final data = await supabase.from('content_library').select().eq('institute_id', user.instituteId).order('created_at', ascending: false);
  return (data as List).map((e) => LibraryItem.fromJson(e)).toList();
});

// ── UI Screen ──────────────────────────────────────────────────────────
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
    final libraryState = ref.watch(libraryProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(title: const Text('E-Content Library'), actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.invalidate(libraryProvider))]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(hintText: 'Search materials...', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); }) : null, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)))),
            ),
          ),
          Expanded(
            child: libraryState.when(
              data: (items) {
                final filteredItems = items.where((i) => i.title.toLowerCase().contains(_searchQuery)).toList();
                if (items.isEmpty) return const EmptyState(icon: Icons.auto_stories_rounded, title: 'Library is empty', subtitle: 'Study materials will appear here.');
                if (filteredItems.isEmpty) return const EmptyState(icon: Icons.search_off_rounded, title: 'No matches', subtitle: 'Try another search term.');
                return RefreshIndicator(onRefresh: () async => ref.invalidate(libraryProvider), child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), itemCount: filteredItems.length, itemBuilder: (context, index) => _LibraryItemTile(item: filteredItems[index])));
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(libraryProvider)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryItemTile extends StatelessWidget {
  final LibraryItem item;
  const _LibraryItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final String type = item.type;
    final IconData icon = _getIcon(type);
    final Color color = _getColor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _openContent(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text('${type.toUpperCase()} • Added ${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  ]),
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.teal, size: 24),
                  onPressed: () => FileUtils.downloadAndShare(item.fileUrl, item.title),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openContent(BuildContext context) async {
    if (item.type == 'image') { _showFullScreenImage(context, item.fileUrl); return; }
    final url = Uri.parse(item.fileUrl);
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalNonBrowserApplication);
      if (!launched) await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showFullScreenImage(BuildContext context, String url) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white), actions: [
      IconButton(icon: const Icon(Icons.share_rounded), onPressed: () => FileUtils.downloadAndShare(url, 'Library_Photo'))
    ]), body: Center(child: Hero(tag: url, child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain, placeholder: (context, url) => const CircularProgressIndicator()))))));
  }

  IconData _getIcon(String type) => switch (type) { 'pdf' => Icons.picture_as_pdf_rounded, 'video' => Icons.play_circle_filled_rounded, 'image' => Icons.image_rounded, _ => Icons.insert_drive_file_rounded };
  Color _getColor(String type) => switch (type) { 'pdf' => const Color(0xFFEF4444), 'video' => const Color(0xFF0EA5E9), 'image' => const Color(0xFFF59E0B), _ => const Color(0xFF6366F1) };
}
