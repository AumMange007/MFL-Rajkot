import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../../widgets/common_widgets.dart';

// ── Models ─────────────────────────────────────────────────────────────
class LibraryItem {
  final String id;
  final String title;
  final String type;
  final String fileUrl;
  final DateTime createdAt;

  LibraryItem({required this.id, required this.title, required this.type, required this.fileUrl, required this.createdAt});

  factory LibraryItem.fromJson(Map<String, dynamic> json) => LibraryItem(
    id: json['id'],
    title: json['title'] ?? 'Untitled',
    type: json['type'] ?? 'other',
    fileUrl: json['file_url'] ?? '',
    createdAt: DateTime.parse(json['created_at']),
  );
}

// ── Providers ──────────────────────────────────────────────────────────
final libraryProvider = FutureProvider<List<LibraryItem>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final data = await supabase
      .from('content_library')
      .select()
      .eq('institute_id', user.instituteId)
      .order('created_at', ascending: false);
  
  return (data as List).map((e) => LibraryItem.fromJson(e)).toList();
});

// ── UI Screen ──────────────────────────────────────────────────────────
class ContentLibraryScreen extends ConsumerWidget {
  const ContentLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text('E-Content Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(libraryProvider),
          ),
        ],
      ),
      body: libraryState.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.auto_stories_rounded,
              title: 'Library is empty',
              subtitle: 'Your study materials and resources will appear here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(libraryProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _LibraryItemTile(item: item);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(libraryProvider)),
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
        child: InkWell(
          onTap: () => _openContent(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text('${type.toUpperCase()} • Added ${_formatDate(item.createdAt)}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openContent(BuildContext context) async {
    final url = Uri.parse(item.fileUrl);
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

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
