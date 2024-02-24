import 'package:e_ligtas_sector/NavigationPages/Accepted_Reports.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'NavigationPages/Active_Requests.dart';
import 'NavigationPages/Profile.dart';
import 'login_page.dart';
import 'package:badges/badges.dart'as badges;
import 'package:e_ligtas_sector/NavigationPages/FullReport.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;
  int activeReportsBadgeCount = 0;

  @override
  void initState() {
    super.initState();
    initialization();
  }

  void initialization() async {
    // This is where you can initialize the resources needed by your app while
    // the splash screen is displayed.  Remove the following example because
    // delaying the user experience is a bad design practice!
    // ignore_for_file: avoid_print
    print('ready in 3...');
    await Future.delayed(const Duration(seconds: 1));
    print('ready in 2...');
    await Future.delayed(const Duration(seconds: 1));
    print('ready in 1...');
    await Future.delayed(const Duration(seconds: 1));
    print('go!');
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        toolbarHeight: 60.0,
        shadowColor: Colors.black,
        title: Text(
          'E-LIGTAS',
          style: TextStyle(
            fontFamily: "Montserrat-Bold",
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()));
            },
          ),
        ],
      ),
      body: _getBody(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Accepted Reports',
          ),
          BottomNavigationBarItem(
            icon: badges.Badge(
              badgeContent: Text('$activeReportsBadgeCount', style: TextStyle(color: Colors.white)),
              badgeStyle: badges.BadgeStyle(),
              child: Icon(Icons.report_outlined),
            ),
            label: 'Pending Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions_outlined),
            label: 'Full Report',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _getBody(int index) {
    switch (index) {
      case 0:
        return AcceptedReportsScreen();
      case 1:
        return ActiveRequestScreen(
          updatePreviousListLength: (length) {
            // Update the badge count when the length changes
            setState(() {
              activeReportsBadgeCount = length;
            });
            print('Previous List Length Updated: $length');
          },
        );
      case 2:
        return FullReport();
      default:
        return Container();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

  Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail') ?? '';
  }
