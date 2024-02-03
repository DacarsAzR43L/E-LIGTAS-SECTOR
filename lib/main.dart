import 'dart:async';
import 'package:e_ligtas_sector/local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_ligtas_sector/Home.dart';
import 'package:e_ligtas_sector/NavigationPages/Active_Requests.dart';


void main()  {
  WidgetsFlutterBinding.ensureInitialized();

   LocalNotifications.init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: FutureBuilder<bool?>(
            future: checkLoggedInStatus(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Container();
              } else {
                bool isLoggedIn = snapshot.data ?? false;
                return isLoggedIn ? HomeScreen() : LoginPage();
              }
            },
          ),
        );
      },
    );
  }
}

Future<bool?> checkLoggedInStatus() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn');
}



