import 'dart:async';
import 'package:e_ligtas_sector/local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_ligtas_sector/Home.dart';
import 'package:workmanager/workmanager.dart';
import 'package:e_ligtas_sector/NavigationPages/Active_Requests.dart';


void main()  {
  WidgetsFlutterBinding.ensureInitialized();

   LocalNotifications.init();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  Workmanager().registerPeriodicTask(
    "backgroundTask",
    "backgroundTask",
    frequency: Duration(minutes: 15),
    constraints: Constraints(
        networkType: NetworkType.connected),
  );


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

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('Background task is running...');

      final ActiveRequestScreen activeRequestScreen = ActiveRequestScreen(
      updatePreviousListLength: (length) {
        // Handle length update if needed
      },
    );
    activeRequestScreen.callFetchData();

      return Future.value(true);
    } catch (e) {
      print('Error in background task: $e');
      return Future.value(false);
    }
  });
}


