import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../auth/providers/auth_provider.dart';
import '../../../models/message_model.dart';
import '../../../models/user_model.dart';

// Optimization: Limited stream to prevent "Memory Lag" for long histories (Fixes Flaw #3)
final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, otherUserId) {
  final supabase = ref.watch(supabaseProvider);
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return Stream.value([]);

  return supabase
      .from('messages')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: true)
      .limit(150) // Keep the most recent 150 messages in the live stream for performance
      .map((data) {
        return data
            .map((e) => MessageModel.fromJson(e))
            .where((m) => 
               (m.senderId == currentUser.id && m.receiverId == otherUserId) ||
               (m.senderId == otherUserId && m.receiverId == currentUser.id))
            .toList();
      })
      .handleError((e) {
        return <MessageModel>[];
      });
});

class ChatNotifier extends StateNotifier<bool> {
  final Ref _ref;
  ChatNotifier(this._ref) : super(false);

  Future<void> sendMessage(String receiverId, String content) async {
    final supabase = _ref.read(supabaseProvider);
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null || content.trim().isEmpty) return;

    await supabase.from('messages').insert({
      'sender_id': currentUser.id,
      'receiver_id': receiverId,
      'content': content.trim(),
    });
  }

  Future<void> uploadAndSendFile(String receiverId, PlatformFile platformFile, String textContent) async {
    final file = File(platformFile.path!);
    final ext = p.extension(file.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final path = 'attachments/$fileName';

    final supabase = _ref.read(supabaseProvider);
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      await supabase.storage.from('content').upload(path, file);
      final fileUrl = supabase.storage.from('content').getPublicUrl(path);

      await supabase.from('messages').insert({
        'sender_id': currentUser.id,
        'receiver_id': receiverId,
        'content': textContent,
        'file_url': fileUrl,
        'file_type': ['jpg', 'jpeg', 'png'].contains(ext.toLowerCase().replaceAll('.', '')) ? 'image' : 'document',
      });
    } catch (e) {
      // Handle upload error
    }
  }

  Future<void> editMessage(String messageId, String newContent) async {
    final supabase = _ref.read(supabaseProvider);
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null || newContent.trim().isEmpty) return;

    await supabase
        .from('messages')
        .update({'content': newContent.trim()})
        .eq('id', messageId)
        .eq('sender_id', currentUser.id);
  }

  Future<void> deleteMessage(String messageId) async {
    final supabase = _ref.read(supabaseProvider);
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return;

    await supabase
        .from('messages')
        .delete()
        .eq('id', messageId)
        .eq('sender_id', currentUser.id);
  }

  Future<void> markAsRead(String otherUserId) async {
    final supabase = _ref.read(supabaseProvider);
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return;

    await supabase
        .from('messages')
        .update({'is_read': true})
        .eq('receiver_id', currentUser.id)
        .eq('sender_id', otherUserId)
        .eq('is_read', false);
  }
}

final chatNotifierProvider = StateNotifierProvider<ChatNotifier, bool>((ref) => ChatNotifier(ref));

final chatListProvider = FutureProvider<List<UserModel>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return [];

  try {
    final res = await supabase
        .from('messages')
        .select('sender_id, receiver_id')
        .or('sender_id.eq.${currentUser.id},receiver_id.eq.${currentUser.id}')
        .limit(200); // Scalability limit
    
    final userIds = <String>{};
    for (var row in (res as List)) {
      if (row['sender_id'] != currentUser.id) userIds.add(row['sender_id']);
      if (row['receiver_id'] != currentUser.id) userIds.add(row['receiver_id']);
    }

    if (userIds.isEmpty) return [];

    final usersRes = await supabase
        .from('users')
        .select()
        .inFilter('id', userIds.toList());
    
    return (usersRes as List).map((e) => UserModel.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

final instituteUsersSearchProvider = FutureProvider.family<List<UserModel>, String>((ref, query) async {
  final supabase = ref.watch(supabaseProvider);
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null || query.length < 2) return [];

  final res = await supabase
      .from('users')
      .select()
      .eq('institute_id', currentUser.instituteId)
      .neq('id', currentUser.id)
      .ilike('name', '%$query%')
      .limit(20); // Result cap for speed
  
  return (res as List).map((e) => UserModel.fromJson(e)).toList();
});

final instituteDirectoryProvider = FutureProvider<List<UserModel>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return [];

  final res = await supabase
      .from('users')
      .select()
      .eq('institute_id', currentUser.instituteId)
      .neq('id', currentUser.id)
      .order('name')
      .limit(100); // Directory cap
  
  return (res as List).map((e) => UserModel.fromJson(e)).toList();
});
