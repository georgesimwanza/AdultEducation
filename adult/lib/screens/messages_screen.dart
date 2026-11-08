import 'dart:async';

import 'package:flutter/material.dart';

import 'package:adult/Model/lms_models.dart';
import 'package:adult/screens/color.dart';
import 'package:adult/screens/lms_widgets.dart';
import 'package:adult/service/lms_api.dart';
import 'package:adult/service/offline_cache.dart';

/// Conversations with instructors (for learners) or with anyone in the
/// institution (for staff).
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _list = GlobalKey<AsyncViewState<List<Conversation>>>();

  Future<void> _open(int userId, String name) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(userId: userId, name: name)));
    _list.currentState?.reload();
  }

  Future<void> _newMessage() async {
    final contact = await Navigator.push<Contact>(
      context,
      MaterialPageRoute(builder: (_) => const _ContactPicker()),
    );
    if (contact != null) await _open(contact.id, contact.name);
  }

  @override
  Widget build(BuildContext context) {
    return LmsPage(
      title: 'Messages',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newMessage,
        backgroundColor: EduColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('New message'),
      ),
      body: AsyncView<List<Conversation>>(
        key: _list,
        load: () async =>
            ((await LmsApi.get('/messages/conversations')) as List).map((e) => Conversation.fromJson(e)).toList(),
        builder: (context, list, reload) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.forum_rounded,
              title: 'No messages yet',
              message: 'Tap "New message" to ask your instructor a question.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              for (final c in list)
                LmsCard(
                  onTap: () => _open(c.userId, c.name),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: EduColors.primarySoft,
                      child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: EduColors.primary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(
                            child: Text(c.name,
                                style: TextStyle(
                                    fontSize: 16, fontWeight: c.unread > 0 ? FontWeight.w900 : FontWeight.w700)),
                          ),
                          if (c.lastAt != null)
                            Text(relativeTime(c.lastAt!),
                                style: TextStyle(fontSize: 12, color: EduColors.textSecondary)),
                        ]),
                        Text(roleLabel(c.role), style: TextStyle(fontSize: 12.5, color: EduColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(c.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                    if (c.unread > 0) ...[
                      const SizedBox(width: 8),
                      Badge(label: Text('${c.unread}')),
                    ],
                  ]),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ContactPicker extends StatelessWidget {
  const _ContactPicker();

  @override
  Widget build(BuildContext context) {
    return LmsPage(
      title: 'Choose who to message',
      body: AsyncView<List<Contact>>(
        load: () async => ((await LmsApi.get('/messages/contacts')) as List).map((e) => Contact.fromJson(e)).toList(),
        builder: (context, list, reload) {
          if (list.isEmpty) {
            return const EmptyState(icon: Icons.person_search_rounded, title: 'No one to message yet');
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final c in list)
                LmsCard(
                  onTap: () => Navigator.pop(context, c),
                  child: Row(children: [
                    const Icon(Icons.person_rounded, color: EduColors.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(c.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                    StatusChip(roleLabel(c.role), color: EduColors.primary),
                  ]),
                ),
            ],
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final int userId;
  final String name;
  const ChatScreen({super.key, required this.userId, required this.name});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    // Light polling while the chat is open; stops when it closes
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _load(quiet: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    try {
      final list = ((await LmsApi.get('/messages/with/${widget.userId}')) as List)
          .map((e) => ChatMessage.fromJson(e))
          .toList();
      if (!mounted) return;
      final grew = list.length != _messages.length;
      setState(() {
        _messages = list;
        _loading = false;
        _error = null;
      });
      if (grew) _scrollToEnd();
    } catch (e) {
      if (!mounted || quiet) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    try {
      final m = ChatMessage.fromJson(await LmsApi.post('/messages', {'recipientId': widget.userId, 'body': body}));
      _text.clear();
      setState(() => _messages = [..._messages, m]);
      _scrollToEnd();
    } on QueuedOffline catch (e) {
      // Show it in the chat now; the saved copy keeps it there until the
      // server sends the real one back after reconnecting.
      final pending = {'id': -DateTime.now().millisecondsSinceEpoch, 'body': body, 'mine': true,
          'sentAt': DateTime.now().toIso8601String()};
      await OfflineCache.appendToList(LmsApi.url('/messages/with/${widget.userId}'), pending);
      _text.clear();
      setState(() => _messages = [..._messages, ChatMessage.fromJson(pending)]);
      _scrollToEnd();
      if (mounted) showError(context, e);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LmsPage(
      title: widget.name,
      body: Column(children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? EmptyState(
                      icon: Icons.wifi_off_rounded,
                      title: 'Could not load',
                      message: _error,
                      actionLabel: 'Try again',
                      onAction: _load,
                    )
                  : _messages.isEmpty
                      ? const EmptyState(icon: Icons.waving_hand_rounded, title: 'Say hello!')
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) => _Bubble(m: _messages[i]),
                        ),
        ),
        Container(
          color: EduColors.surface,
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _text,
                minLines: 1,
                maxLines: 4,
                maxLength: 4000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message',
                  counterText: '',
                  filled: true,
                  fillColor: EduColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Send',
              iconSize: 26,
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage m;
  const _Bubble({required this.m});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: m.mine ? EduColors.primary : EduColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: m.mine ? null : Border.all(color: EduColors.border),
          ),
          child: Column(
            crossAxisAlignment: m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(m.body, style: TextStyle(fontSize: 15.5, color: m.mine ? Colors.white : EduColors.textPrimary)),
              const SizedBox(height: 4),
              Text(
                '${formatDateTime(m.sentAt)}${m.mine && m.readAt != null ? ' · Seen' : ''}',
                style: TextStyle(fontSize: 11, color: m.mine ? EduColors.onPrimaryMuted : EduColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
