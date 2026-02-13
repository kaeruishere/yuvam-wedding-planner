import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/texts.dart';
import 'dashboard_screen.dart';
import 'wallet_screen.dart';
import 'services_screen.dart';
import 'items_screen.dart';
import 'us_screen.dart';
import 'tasks_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/notification_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 2;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    // 1. Check/Request Permissions
    await NotificationService().checkAndRequestPermissions();

    // 2. Setup Listener for partner notifications
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final coupleId = userDoc.data()?['coupleId'];

    if (coupleId != null) {
      _notificationSubscription = FirebaseFirestore.instance
          .collection('couples')
          .doc(coupleId)
          .collection('notifications')
          .where('createdAt', isGreaterThan: Timestamp.now()) // Only new notifications
          .snapshots()
          .listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data() as Map<String, dynamic>;
            final senderId = data['senderId'];
            
            // Only show if sent by partner
            if (senderId != user.uid) {
              NotificationService().showLocalNotification(
                title: data['title'] ?? 'Yeni Bildirim',
                body: data['body'] ?? '',
              );
            }
          }
        }
      });
    }
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const ServicesScreen();
      case 1:
        return const  ItemsScreen();
      case 2:
        return DashboardScreen(onNavigate: _navigateToTab);
      case 3:
        return const TasksScreen();
      case 4:
        return const UsScreen();
      default:
        return DashboardScreen(onNavigate: _navigateToTab);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _buildCurrentScreen(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.business_outlined),
            activeIcon: const Icon(Icons.business),
            label: AppTexts.navServices,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_bag_outlined),
            activeIcon: const Icon(Icons.shopping_bag),
            label: AppTexts.navShopping,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: AppTexts.navDashboard,
          ),
           BottomNavigationBarItem(
            icon: const Icon(Icons.check_box_outlined),
            activeIcon: const Icon(Icons.check_box),
            label: AppTexts.navTasks,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_outline),
            activeIcon: const Icon(Icons.favorite),
            label: AppTexts.navUs,
          ),
        ],
      ),
    );
  }
}
