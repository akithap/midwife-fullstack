import 'package:flutter/material.dart';

import 'midwife_home_screen.dart';
import 'mother_list_screen.dart';
import 'appointment_screen.dart';
import 'midwife_map_screen.dart';
import '../theme/app_theme.dart';

class MidwifeMainScreen extends StatefulWidget {
  @override
  _MidwifeMainScreenState createState() => _MidwifeMainScreenState();
}

class _MidwifeMainScreenState extends State<MidwifeMainScreen> {
  int _selectedIndex = 0;

  // The pages corresponding to each tab
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      MidwifeHomeScreen(), // 0: Home/Dashboard
      MotherListScreen(), // 1: Mothers
      AppointmentScreen(), // 2: Calendar/Visits
      MidwifeMapScreen(), // 3: Map
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pregnant_woman_outlined),
            activeIcon: Icon(Icons.pregnant_woman),
            label: 'Mothers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }
}
