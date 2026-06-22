import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'COMPLETED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      case 'PENDING':   return Colors.orange;
      case 'ACCEPTED':  return Colors.blue;
      default:          return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Booking History',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .where('studentUid', isEqualTo: uid)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)));
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('No booking history yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Your completed rides will appear here',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ));
          }
          final rides = snap.data!.docs.toList()
              ..sort((a, b) {
                final at = (a.data() as Map)['createdAt'];
                final bt = (b.data() as Map)['createdAt'];
                if (at == null || bt == null) return 0;
                return bt.toDate().compareTo(at.toDate());
              });
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final d = rides[index].data() as Map<String, dynamic>;
              final status = d['status'] ?? 'UNKNOWN';
              final ts = d['createdAt'];
              String date = '';
              if (ts != null) {
                try {
                  final dt = (ts as dynamic).toDate();
                  date = DateFormat('dd MMM yyyy, HH:mm', 'en').format(dt);
                } catch (_) {}
              }
              final fare = (d['fareEstimate'] ?? 0.0).toDouble();
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: _statusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(status, style: TextStyle(
                            color: _statusColor(status),
                            fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                      Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    const Icon(Icons.circle, size: 10, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(child: Text(d['pickupAddress'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        overflow: TextOverflow.ellipsis)),
                  ]),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, top: 3, bottom: 3),
                    child: Icon(Icons.more_vert, size: 12, color: Colors.grey),
                  ),
                  Row(children: [
                    const Icon(Icons.location_on, size: 12, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(child: Text(d['dropoffAddress'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        overflow: TextOverflow.ellipsis)),
                  ]),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.payment, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(d['paymentMethod'] ?? '',
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ]),
                      Text('RM ' + fare.toStringAsFixed(2),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16, color: Colors.black)),
                    ],
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
