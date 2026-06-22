import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsPage extends StatelessWidget {
  final bool isDriver;
  const NotificationsPage({super.key, this.isDriver = false});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final themeColor = isDriver
        ? Colors.orange.shade800 : Colors.blue.shade900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('toUid', isEqualTo: uid)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none,
                    size: 72, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('No notifications yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ));
          }

          // Sort by createdAt in app
          final docs = snap.data!.docs.toList()
            ..sort((a, b) {
              final at = (a.data() as Map)['createdAt'];
              final bt = (b.data() as Map)['createdAt'];
              if (at == null || bt == null) return 0;
              try { return bt.toDate().compareTo(at.toDate()); }
              catch (_) { return 0; }
            });

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final ts = d['createdAt'];
              String time = '';
              if (ts != null) {
                try {
                  final dt = (ts as dynamic).toDate();
                  time = '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2,'0')}';
                } catch (_) {}
              }
              return Dismissible(
                key: Key(docs[i].id),
                background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white)),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => FirebaseFirestore.instance
                    .collection('notifications').doc(docs[i].id).delete(),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: themeColor.withOpacity(0.1),
                    child: Icon(Icons.notifications, color: themeColor),
                  ),
                  title: Text(d['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['message'] ?? ''),
                      const SizedBox(height: 4),
                      Text(time,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
