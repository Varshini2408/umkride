import 'package:flutter/material.dart';

// Tracker for unread counts by role
int unreadMessagesDriver = 0;
int unreadMessagesPassenger = 0;
int unreadNotificationsDriver = 0;
int unreadNotificationsPassenger = 0;

// Messages stored as GLOBAL variables
List<Map<String, dynamic>> sharedMessages = [
  {
    'text': 'GOOD DAY, I WILL TAKE YOU TO YOUR INTENDED DESTINATION.',
    'sender': 'driver',
    'time': 'System'
  },
];

// List of GLOBAL notifications with 'target' field (driver/passenger/all)
List<Map<String, String>> sharedNotifications = [
  {
    'title': 'Booking Successful',
    'message': 'Ali will pick you up at the Residential College at 2.30 PM.',
    'time': '5 minutes ago',
    'target': 'passenger', 
  },
  {
    'title': 'New Task',
    'message': 'You have a new booking from Ahmad.',
    'time': '10 minutes ago',
    'target': 'driver',
  },
];

// List of GLOBAL ratings
List<Map<String, dynamic>> sharedRatings = [
  {
    'passengerName': 'Ahmad',
    'rating': 5,
    'comment': 'The driver is very friendly and the car is clean!',
    'time': 'Yesterday'
  },
];
