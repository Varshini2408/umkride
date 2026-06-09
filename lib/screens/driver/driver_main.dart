import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'driver_dashboard.dart';
import 'driver_profile.dart';

class DriverMain extends StatefulWidget {
  const DriverMain({super.key});
  @override
  State<DriverMain> createState() => _DriverMainState();
}

class _DriverMainState extends State<DriverMain> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DriverDashboard(),
      const _ComingSoon(label: 'My Rides'),
      const DriverProfile(),
    ];
    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.navy,
        unselectedItemColor: AppColors.muted,
        selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 11),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_outlined),
              activeIcon: Icon(Icons.directions_car),
              label: 'Rides'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  final String label;
  const _ComingSoon({required this.label});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.construction, size: 64, color: AppColors.muted),
        const SizedBox(height: 16),
        Text(label,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold,
                color: AppColors.navy)),
        const SizedBox(height: 8),
        const Text('Coming Soon!',
            style: TextStyle(color: AppColors.muted)),
      ]),
    );
  }
}
