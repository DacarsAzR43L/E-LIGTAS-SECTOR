import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import '../login_page.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  late Future<String?> userFromFuture;

  @override
  void initState() {
    super.initState();
    userFromFuture = fetchUserFrom();
  }


  Future<void> signOutUser() async {


    // Check for internet connectivity
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print('No internet connection');

      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        animType: AnimType.rightSlide,
        btnOkColor: Color.fromRGBO(51, 71, 246, 1),
        title: "No Internet Connection",
        desc: 'Please Try Again',
        btnCancelOnPress: () {},
        btnOkOnPress: () {},
        dismissOnTouchOutside: false,
      )..show();
      return;
    }

    try {
      await storeSignOutInfo();
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (context) => LoginPage()), (
              route) => false);
    } catch (e) {
      print('Error signing out: $e');
      // Handle sign-out errors, if any.
    }
  }

  storeSignOutInfo() async {
    print("Shared pref called");
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isLoggedIn', false);
    print(prefs.getBool('isLoggedIn'));
  }

  Future<String?> fetchUserFrom() async {
    final String apiUrl = 'https://eligtas.site/public/storage/get_userFrom.php';

    String userEmail = await getUserEmail();

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'email': userEmail},
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        // Check for errors in the response
        if (responseData.containsKey('error')) {
          print('Error: ${responseData['error']}');
          return null;
        }

        // Check if the response contains 'userfrom' key
        if (responseData.containsKey('userfrom')) {
          // Assuming 'userfrom' is a string
          String userfrom = responseData['userfrom'];
          print('Userfrom: $userfrom');
          return userfrom;
        } else {
          print('Error: Userfrom not found in the response.');
          return null;
        }
      } else {
        print('Error: ${response.reasonPhrase}');
        return null;
      }
    } catch (error) {
      print('Error: $error');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: EdgeInsets.all(2.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 15.0.w,
                backgroundImage: AssetImage('Assets/appIcon.png'),
                // You can replace the AssetImage with your actual image path
              ),
              SizedBox(height: 2.0.h),
              FutureBuilder<String?>(
                future: getUserEmail(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(); // Show a loader while waiting for the data
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    String userName = snapshot.data ?? 'Your Name';
                    return Column(
                      children: [
                        Text(
                          userName,
                          style: TextStyle(fontSize: 20.0.sp),
                        ),
                        FutureBuilder<String?>(
                          future: userFromFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator(); // Show a loader while waiting for the data
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else {
                              String userFrom = snapshot.data ?? 'Userfrom';
                              return Text(
                                'User from: $userFrom',
                                style: TextStyle(fontSize: 16.0.sp),
                              );
                            }
                          },
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
Future<String> getUserEmail() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userEmail') ?? '';
}

