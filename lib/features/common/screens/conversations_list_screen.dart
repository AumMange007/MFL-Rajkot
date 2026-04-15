import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';

class ConversationsListScreen extends ConsumerStatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  ConsumerState<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends ConsumerState<ConversationsListScreen> {
  final _searchCtrl = TextEditingController();
  final _newChatCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _newChatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isStaff = currentUser?.role != 'student';

    if (!isStaff) return _buildStudentView();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F6FF),
        appBar: AppBar(
          title: const Text('Institute Messenger'),
          bottom: TabBar(
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.normal, fontSize: 13),
            tabs: const [
              Tab(text: 'MY CHATS', icon: Icon(Icons.chat_bubble_rounded, size: 18)),
              Tab(text: 'FULL DIRECTORY', icon: Icon(Icons.import_contacts_rounded, size: 18)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ChatsListTab(searchQuery: _searchQuery, searchCtrl: _searchCtrl),
            const _InstituteDirectoryTab(),
          ],
        ),
      ),
    );
  }

  // Fallback for students who don't need the directory tab
  Widget _buildStudentView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        title: const Text('My Messages'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _buildSearchBar(),
          ),
        ),
      ),
      body: _ChatsListTab(searchQuery: _searchQuery, searchCtrl: null),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
      decoration: InputDecoration(
        hintText: 'Search chats...',
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

class _ChatsListTab extends ConsumerWidget {
  final String searchQuery;
  final TextEditingController? searchCtrl;
  const _ChatsListTab({required this.searchQuery, this.searchCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsState = ref.watch(chatListProvider);
    
    return Column(
      children: [
        if (searchCtrl != null)
           Padding(
             padding: const EdgeInsets.all(16),
             child: TextField(
               controller: searchCtrl,
               onChanged: (v) => (context.findAncestorStateOfType<_ConversationsListScreenState>() as _ConversationsListScreenState).setState(() {}),
               decoration: InputDecoration(
                 hintText: 'Search your conversations...',
                 prefixIcon: const Icon(Icons.search),
                 filled: true, fillColor: Colors.white,
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
               ),
             ),
           ),
        Expanded(
          child: conversationsState.when(
            data: (users) {
              final filtered = users.where((u) => (u.name ?? '').toLowerCase().contains(searchQuery.toLowerCase())).toList();
              if (users.isEmpty) return _buildEmptyState();
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) => _ConversationTile(user: filtered[index]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No active chats yet.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _InstituteDirectoryTab extends ConsumerStatefulWidget {
  const _InstituteDirectoryTab();
  @override
  ConsumerState<_InstituteDirectoryTab> createState() => _InstituteDirectoryTabState();
}

class _InstituteDirectoryTabState extends ConsumerState<_InstituteDirectoryTab> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final directoryState = ref.watch(instituteDirectoryProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search people...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: directoryState.when(
            data: (users) {
              final filtered = users.where((u) => (u.name ?? '').toLowerCase().contains(_query)).toList();
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                   final u = filtered[index];
                   return _ConversationTile(user: u);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final UserModel user;
  const _ConversationTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final roleColor = switch (user.role) {
      'admin' => Colors.redAccent,
      'tutor' => Colors.blueAccent,
      'staff' => Colors.orangeAccent,
      _       => Colors.greenAccent,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFF1F5F9),
              backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null ? Text(user.name[0].toUpperCase() ?? '') : null,
            ),
            Positioned(
              right: 0, bottom: 0,
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: roleColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(user.name ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(user.roleLabel.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: roleColor, letterSpacing: 0.5)),
        trailing: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF0284C7)),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherUser: user)));
        },
      ),
    );
  }
}
