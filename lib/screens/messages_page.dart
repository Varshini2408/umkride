import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_detail_page.dart';

class MessagesPage extends StatelessWidget {
  final bool isDriver;
  const MessagesPage({super.key, this.isDriver = false});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final themeColor = isDriver
        ? Colors.orange.shade800 : Colors.blue.shade900;
    final field = isDriver ? 'driverUid' : 'studentUid';

    return Scaffold(
      appBar: AppBar(
        title: Text(isDriver ? 'Customer Messages' : 'Driver Messages'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .where(field, isEqualTo: uid)
            .where('status', whereIn: ['ACCEPTED', 'PICKED_UP', 'COMPLETED'])
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 72, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('No active chats',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Chat is available during and after a ride',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ));
          }
          final rides = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: rides.length,
            itemBuilder: (_, i) {
              final d = rides[i].data() as Map<String, dynamic>;
              final rideId = rides[i].id;
              final status = d['status'] ?? '';
              final otherName = isDriver
                  ? 'Student' : (d['driverName'] ?? 'Driver');

              // Check if chat is still allowed (within 2 hours of completion)
              bool chatAllowed = true;
              if (status == 'COMPLETED') {
                final ts = d['completedAt'];
                if (ts != null) {
                  try {
                    final completed = (ts as dynamic).toDate();
                    final diff = DateTime.now().difference(completed);
                    if (diff.inHours >= 2) chatAllowed = false;
                  } catch (_) {}
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6)]),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: themeColor.withOpacity(0.1),
                    child: Text(otherName[0],
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: themeColor)),
                  ),
                  title: Text(otherName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${d['pickupAddress'] ?? ''} → ${d['dropoffAddress'] ?? ''}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: chatAllowed
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          chatAllowed ? status : 'Closed',
                          style: TextStyle(
                              fontSize: 10,
                              color: chatAllowed
                                  ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  onTap: chatAllowed
                      ? () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ChatDetailPage(
                            rideId: rideId,
                            otherUserName: otherName,
                            isDriver: isDriver,
                          )))
                      : () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Chat closed — 2 hours after ride completion'))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
