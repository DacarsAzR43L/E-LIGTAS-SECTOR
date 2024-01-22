import 'dart:async';

import 'package:e_ligtas_sector/local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_ligtas_sector/Home.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalNotifications.init();
  //await initializeService();

  runApp(MyApp());
}

/*Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
      iosConfiguration: IosConfiguration(),
      androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          isForegroundMode: true
      )
  );
await service.startService();
}*/

//@pragma('vm:entry-point')

/*void onStart(ServiceInstance service) async{

  if(service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });


    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

  }


  /*Timer.periodic(Duration(seconds: 2), (timer) async {
    if(service is AndroidServiceInstance) {
      if( await service.isForegroundService()) {
        service.setForegroundNotificationInfo(title: "My App Service", content: "Updated at ${DateTime.now()}");
    }
    }


  });*/



    }*/




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
            if (snapshot.hasError) {
              return Container();
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
