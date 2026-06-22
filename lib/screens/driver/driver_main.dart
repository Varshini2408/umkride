import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import 'driver_dashboard.dart';
import 'driver_profile.dart';
import 'incoming_ride_screen.dart';
import 'driver_rides_history.dart';
import '../messages_page.dart';
import '../notifications_page.dart';
import '../ratings_page.dart';

class DriverMain extends StatefulWidget {
  const DriverMain({super.key});
  @override
  State<DriverMain> createState() => _DriverMainState();
}

class _DriverMainState extends State<DriverMain> {
  int _currentIndex = 0;
  bool _isOnline = false;
  bool _showingRequest = false;
  Stream<QuerySnapshot>? _rideStream;

  void _setOnline(bool online) {
    setState(() {
      _isOnline = online;
      _rideStream = online
          ? FirebaseFirestore.instance
              .collection('rides')
              .where('status', isEqualTo: 'PENDING')
              .snapshots()
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final screens = [
      DriverDashboard(isOnline: _isOnline, onToggle: _setOnline),
      const DriverRidesHistory(),
      const MessagesPage(isDriver: true),
      const NotificationsPage(isDriver: true),
      RatingsPage(isDriver: true, driverUid: uid),
      const DriverProfile(),
    ];
    return Scaffold(
      body: Stack(children: [
        screens[_currentIndex],
        if (_isOnline && _rideStream != null)
          StreamBuilder<QuerySnapshot>(
            stream: _rideStream,
            builder: (context, snap) {
              if (snap.hasData &&
                  snap.data!.docs.isNotEmpty &&
                  !_showingRequest) {
                final ride = snap.data!.docs.first;
                final data = ride.data() as Map<String, dynamic>;
                if (data['driverUid'] == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (mounted && !_showingRequest) {
                      // Check gender preference
                      final driverDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .get();
                      final driverGender = driverDoc.data()?['gender'] ?? 'MALE';
                      final pref = data['genderPreference'] ?? 'ANY';
                      final allowed = pref == 'ANY' ||
                          (pref == 'FEMALE_ONLY' && driverGender == 'FEMALE');
                      if (!allowed) return;
                      setState(() => _showingRequest = true);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => IncomingRideScreen(
                                  rideId:   ride.id,
                                  rideData: data))).then((_) {
                        if (mounted) setState(() => _showingRequest = false);
                      });
                    }
                  });
                }
              }
              return const SizedBox.shrink();
            },
          ),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.navy,
        unselectedItemColor: AppColors.muted,
        selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Rides'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Alerts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.star_outline),
              activeIcon: Icon(Icons.star),
              label: 'Ratings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}
