import 'package:flutter/material.dart';
import 'package:e_ligtas_sector/local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class ManualReports extends StatefulWidget {
  const ManualReports({super.key});

  @override
  State<ManualReports> createState() => _ManualReportsState();
}

class _ManualReportsState extends State<ManualReports> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Flutter Local Notifications")),
      body: Container(
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.notifications_outlined),
                onPressed: () async {
                  /*LocalNotifications.showSimpleNotification(
                      title: "Simple Notification",
                      body: "This is a simple notification",
                      payload: "This is simple data");*/

                  final service = FlutterBackgroundService();
                  var isRunning = await service.isRunning();

                  if(isRunning) {
                    service.invoke("stopService");
                  }

                },
                label: Text("Simple Notification"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}