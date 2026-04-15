import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../../../models/user_model.dart';
import '../../../models/message_model.dart';
import '../providers/chat_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/utils/file_utils.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final UserModel otherUser;
  const ChatScreen({super.key, required this.otherUser});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _editingMessageId;
  PlatformFile? _queuedFile;

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _queuedFile = result.files.first);
    }
  }

  void _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (_queuedFile != null) {
      final file = _queuedFile!;
      setState(() => _queuedFile = null);
      await ref.read(chatNotifierProvider.notifier).uploadAndSendFile(
        widget.otherUser.id, 
        file, 
        text.isNotEmpty ? text : 'Attachment: ${file.name}'
      );
      _messageCtrl.clear();
      _scrollToBottom();
      return;
    }
    if (text.isEmpty) return;
    if (_editingMessageId != null) {
      ref.read(chatNotifierProvider.notifier).editMessage(_editingMessageId!, text);
      setState(() => _editingMessageId = null);
    } else {
      ref.read(chatNotifierProvider.notifier).sendMessage(widget.otherUser.id, text);
    }
    _messageCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _onMessageAction(MessageModel message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.senderId == ref.read(currentUserProvider)?.id) ...[
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Colors.blue),
                title: const Text('Edit Message'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() { _editingMessageId = message.id; _messageCtrl.text = message.content; });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Delete Message'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(chatNotifierProvider.notifier).deleteMessage(message.id);
                },
              ),
            ],
            if (message.fileUrl != null)
              ListTile(
                leading: const Icon(Icons.download_rounded, color: Colors.green),
                title: const Text('Download / Share File'),
                onTap: () {
                  Navigator.pop(context);
                  FileUtils.downloadAndShare(message.fileUrl!, 'Chat_File');
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesStream = ref.watch(chatMessagesProvider(widget.otherUser.id));
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: widget.otherUser.avatarUrl != null && widget.otherUser.avatarUrl!.isNotEmpty ? CachedNetworkImageProvider(widget.otherUser.avatarUrl!) : null,
              child: widget.otherUser.avatarUrl == null || widget.otherUser.avatarUrl!.isEmpty ? Text(widget.otherUser.name[0].toUpperCase() ?? 'U', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherUser.name ?? 'Chat', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(widget.otherUser.role.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesStream.when(
              data: (messages) {
                if (messages.isEmpty) return _buildEmptyState();
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser?.id;
                    return GestureDetector(
                      onLongPress: () => _onMessageAction(message),
                      child: _MessageBubble(message: message, isMe: isMe),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildErrorState(ref),
            ),
          ),
          
          _buildActiveModeOverlay(),

          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4))]),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(icon: const Icon(Icons.add_rounded, color: Color(0xFF0284C7), size: 28), onPressed: _pickFile),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0))),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _messageCtrl,
                      maxLines: 4, minLines: 1,
                      decoration: const InputDecoration(hintText: 'Type a message...', border: InputBorder.none),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: CircleAvatar(radius: 22, backgroundColor: const Color(0xFF0284C7), child: IconButton(icon: Icon(_editingMessageId != null ? Icons.check : Icons.send_rounded, color: Colors.white, size: 20), onPressed: _sendMessage)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveModeOverlay() {
    if (_queuedFile != null) {
      final isImage = ['jpg','jpeg','png'].contains(_queuedFile!.extension?.toLowerCase());
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12)], border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.2))),
        child: Row(
          children: [
            if (isImage && _queuedFile!.path != null) ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_queuedFile!.path!), width: 40, height: 40, fit: BoxFit.cover))
            else const Icon(Icons.description_rounded, color: Color(0xFF0284C7), size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('Ready to send:', style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                   Text(_queuedFile!.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.cancel_rounded, color: Colors.grey), onPressed: () => setState(() => _queuedFile = null)),
          ],
        ),
      );
    }
    if (_editingMessageId != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        color: Colors.blue.withOpacity(0.05),
        child: Row(
          children: [
            const Icon(Icons.edit_rounded, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            const Expanded(child: Text('Editing message...', style: TextStyle(fontSize: 12, color: Colors.blue, fontStyle: FontStyle.italic))),
            IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() { _editingMessageId = null; _messageCtrl.clear(); })),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState() { return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.withOpacity(0.3)), const SizedBox(height: 16), Text('No messages yet', style: GoogleFonts.inter(color: Colors.grey)), Text('Start conversation with ${widget.otherUser.name}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey))])); }
  Widget _buildErrorState(WidgetRef ref) { return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.orange), const SizedBox(height: 16), Text('Sync issue detected', style: GoogleFonts.inter(fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('Connection timed out. Retrying sync...', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 20), ElevatedButton(onPressed: () => ref.refresh(chatMessagesProvider(widget.otherUser.id)), child: const Text('Retry'))]))); }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF0284C7) : Colors.white,
                borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (message.fileUrl != null) ...[
                    _buildAttachment(context),
                  ],
                  if (message.content.isNotEmpty && !message.content.startsWith('Attachment:'))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                      child: Text(message.content, style: GoogleFonts.inter(color: isMe ? Colors.white : const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(DateFormat('h:mm a').format(message.createdAt), style: TextStyle(color: isMe ? Colors.white.withOpacity(0.7) : const Color(0xFF94A3B8), fontSize: 9)),
                        if (isMe) ...[const SizedBox(width: 4), Icon(Icons.done_all_rounded, size: 12, color: Colors.white.withOpacity(0.7))],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachment(BuildContext context) {
    if (message.fileType == 'image') {
      return GestureDetector(
        onTap: () => _showFullScreenImage(context, message.fileUrl!),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Hero(tag: message.fileUrl!, child: CachedNetworkImage(imageUrl: message.fileUrl!, placeholder: (context, url) => Container(height: 180, width: double.infinity, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())), errorWidget: (context, url, error) => const Icon(Icons.error), fit: BoxFit.cover)),
        ),
      );
    }
    return GestureDetector(
      onTap: () async {
        final url = Uri.parse(message.fileUrl!);
        final launched = await launchUrl(url, mode: LaunchMode.externalNonBrowserApplication);
        if (!launched) await launchUrl(url, mode: LaunchMode.externalApplication);
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: isMe ? Colors.white.withOpacity(0.1) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: isMe ? Colors.white.withOpacity(0.2) : const Color(0xFFE2E8F0))),
        child: Row(
          children: [
            Icon(Icons.insert_drive_file_rounded, color: isMe ? Colors.white : const Color(0xFF0284C7), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Document', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: isMe ? Colors.white : const Color(0xFF0F172A))),
                Text('Tap to Open', style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey)),
              ]),
            ),
            IconButton(icon: const Icon(Icons.download_rounded, size: 20, color: Colors.grey), onPressed: () => FileUtils.downloadAndShare(message.fileUrl!, 'Chat_File')),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String url) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(icon: const Icon(Icons.share_rounded, semanticLabel: 'Share & Download'), onPressed: () => FileUtils.downloadAndShare(url, 'Chat_Photo')),
          ],
        ),
        body: Center(child: Hero(tag: url, child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain, placeholder: (context, url) => const CircularProgressIndicator()))),
      ),
    ));
  }
}
