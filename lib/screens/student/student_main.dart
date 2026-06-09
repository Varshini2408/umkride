import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'student_dashboard.dart';
import 'student_profile.dart';

class StudentMain extends StatefulWidget {
  const StudentMain({super.key});
  @override
  State<StudentMain> createState() => _StudentMainState();
}

class _StudentMainState extends State<StudentMain> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    StudentDashboard(),
    _ComingSoon(label: 'Book a Ride'),
    _ComingSoon(label: 'Ride History'),
    StudentProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.navy,
        unselectedItemColor: AppColors.muted,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car_outlined),
              activeIcon: Icon(Icons.directions_car), label: 'Book'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person), label: 'Profile'),
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
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.construction, size: 64, color: AppColors.muted),
      const SizedBox(height: 16),
      Text(label, style: const TextStyle(fontSize: 20,
          fontWeight: FontWeight.bold, color: AppColors.navy)),
      const SizedBox(height: 8),
      const Text('Coming Soon!', style: TextStyle(color: AppColors.muted)),
    ]));
  }
}
