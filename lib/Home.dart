import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'NavigationPages/Active_Request.dart';
import 'login_page.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1; // Set the default tab index to 1 (Business)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        toolbarHeight:60.0,
        shadowColor: Colors.black,
        title: Text('E-LIGTAS',
            style:TextStyle(
                fontFamily: "Montserrat-Bold",
                fontWeight: FontWeight.bold,
                fontSize: 24)
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              // Add logic for handling person icon click
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
            icon: Icon(Icons.report_outlined),
            label: 'Active Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions_outlined),
            label: 'Manual Report',
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
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Welcome to the Home Screen!'),
              SizedBox(height: 16.0),
              FutureBuilder<String>(
                future: getUserEmail(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Loading state
                    return CircularProgressIndicator();
                  } else {
                    // Display the user's email
                    String userEmail = snapshot.data ?? '';
                    return Text('Logged in as: $userEmail');
                  }
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  // Clear user information from SharedPreferences on logout
                  final prefs = await SharedPreferences.getInstance();
                  prefs.clear();

                  // Navigate back to the login screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                child: Text('Logout'),
              ),
            ],
          ),
        );
      case 1:
        return ActiveRequestScreen();
      case 2:
        return Center(
          child: Text('School Tab'),
        );
      default:
        return Container();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail') ?? '';
  }
}
