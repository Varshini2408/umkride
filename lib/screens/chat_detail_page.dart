import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatDetailPage extends StatefulWidget {
  final String rideId;
  final String otherUserName;
  final bool isDriver;
  const ChatDetailPage({
    super.key,
    required this.rideId,
    required this.otherUserName,
    required this.isDriver,
  });
  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _db = FirebaseFirestore.instance;
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    await _db
        .collection('rides')
        .doc(widget.rideId)
        .collection('messages')
        .add({
      'text':      text,
      'senderUid': _uid,
      'isDriver':  widget.isDriver,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isDriver
        ? Colors.orange.shade800 : Colors.blue.shade900;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('rides')
                .doc(widget.rideId)
                .collection('messages')
                .orderBy('createdAt')
                .snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(
                  child: CircularProgressIndicator());
              final msgs = snap.data!.docs;
              if (msgs.isEmpty) return const Center(
                  child: Text('No messages yet. Say hi!',
                      style: TextStyle(color: Colors.grey)));
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: msgs.length,
                itemBuilder: (_, i) {
                  final d = msgs[i].data() as Map<String, dynamic>;
                  final isMe = d['senderUid'] == _uid;
                  final ts = d['createdAt'];
                  String time = '';
                  if (ts != null) {
                    try {
                      final dt = (ts as dynamic).toDate();
                      time = '${dt.hour}:${dt.minute.toString().padLeft(2,'0')}';
                    } catch (_) {}
                  }
                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isMe ? themeColor : Colors.grey.shade200,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: Radius.circular(isMe ? 12 : 0),
                          bottomRight: Radius.circular(isMe ? 0 : 12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(d['text'] ?? '',
                              style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                  fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(time,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isMe
                                      ? Colors.white70 : Colors.black54)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: themeColor,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _send,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
