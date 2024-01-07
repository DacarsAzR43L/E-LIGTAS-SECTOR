import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_ligtas_sector/Home.dart';
void main() {
  runApp(MyApp());
}

// Function to check the user's logged-in status
Future<bool> checkLoggedInStatus() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn') ?? false;
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder:  (context, orientation, deviceType) {
     return MaterialApp(
       debugShowCheckedModeBanner: false,
        home: FutureBuilder<bool>(
          future: checkLoggedInStatus(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Loading state
              return CircularProgressIndicator();
            } else {
              // Check if the user is logged in or not
              bool isLoggedIn = snapshot.data ?? false;
              return isLoggedIn ? HomeScreen() : LoginPage();
            }
          },
        ),
      );
    }
    );
  }
}
