import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';

class DriverRidesHistory extends StatelessWidget {
  const DriverRidesHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Container(
          height: 140,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D1F35), Color(0xFF1A3C5E)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: const SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Icon(Icons.history, color: AppColors.gold, size: 28),
                SizedBox(width: 14),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Rides', style: TextStyle(fontSize: 20,
                        fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Completed rides history',
                        style: TextStyle(color: AppColors.gold, fontSize: 12)),
                  ],
                ),
              ]),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rides')
                .where('driverUid', isEqualTo: uid)
                .where('status', isEqualTo: 'COMPLETED')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(
                    color: AppColors.navy));
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_car_outlined, size: 72,
                        color: AppColors.muted.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    const Text('No completed rides yet',
                        style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.bold, color: AppColors.navy)),
                    const SizedBox(height: 8),
                    const Text('Go online to start receiving rides!',
                        style: TextStyle(color: AppColors.muted)),
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
              double totalEarnings = 0;
              for (final r in rides) {
                final d = r.data() as Map<String, dynamic>;
                totalEarnings += (d['fareEstimate'] ?? 0.0).toDouble();
              }
              return Column(children: [
                // Summary
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Expanded(child: Column(children: [
                      Text('${rides.length}', style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold,
                          color: Colors.white)),
                      const Text('Total Rides', style: TextStyle(
                          color: AppColors.muted, fontSize: 12)),
                    ])),
                    Container(width: 1, height: 40, color: Colors.white24),
                    Expanded(child: Column(children: [
                      Text('RM ${totalEarnings.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 22,
                              fontWeight: FontWeight.bold, color: AppColors.gold)),
                      const Text('Total Earnings', style: TextStyle(
                          color: AppColors.muted, fontSize: 12)),
                    ])),
                  ]),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: rides.length,
                    itemBuilder: (_, i) {
                      final d = rides[i].data() as Map<String, dynamic>;
                      final ts = d['createdAt'];
                      String date = '';
                      if (ts != null) {
                        final dt = (ts as dynamic).toDate();
                        date = '${dt.day}/${dt.month}/${dt.year}';
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                                blurRadius: 5, offset: const Offset(0, 1))]),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.check_circle,
                                color: AppColors.success, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(d['pickupAddress'] ?? '',
                                style: const TextStyle(fontSize: 12,
                                    color: AppColors.darkText),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            const Icon(Icons.arrow_downward,
                                size: 12, color: AppColors.muted),
                            Text(d['dropoffAddress'] ?? '',
                                style: const TextStyle(fontSize: 12,
                                    color: AppColors.darkText),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                            Text('RM ${(d['fareEstimate'] ?? 0.0).toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold,
                                    color: AppColors.success, fontSize: 15)),
                            Text(date, style: const TextStyle(
                                fontSize: 10, color: AppColors.muted)),
                          ]),
                        ]),
                      );
                    },
                  ),
                ),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}
