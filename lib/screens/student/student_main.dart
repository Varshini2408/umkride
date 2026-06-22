import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'student_dashboard.dart';
import 'student_profile.dart';
import '../select_location_screen.dart';
import '../../history/history_screen.dart';
import '../messages_page.dart';
import '../notifications_page.dart';

class StudentMain extends StatefulWidget {
  const StudentMain({super.key});
  @override
  State<StudentMain> createState() => _StudentMainState();
}

class _StudentMainState extends State<StudentMain> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const StudentDashboard(),
      const SelectLocationScreen(),
      const HistoryScreen(),
      const MessagesPage(isDriver: false),
      const NotificationsPage(isDriver: false),
      const StudentProfile(),
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
            fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_outlined),
              activeIcon: Icon(Icons.directions_car),
              label: 'Book'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Alerts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}
