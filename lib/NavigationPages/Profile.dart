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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 15.0.w,
                backgroundImage: AssetImage('Assets/appIcon.png'),
                // You can replace the AssetImage with your actual image path
              ),
              SizedBox(height: 2.0.h),
              FutureBuilder<String>(
                future: getUserEmail(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(); // Show a loader while waiting for the data
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    String userName = snapshot.data ?? 'Your Name';
                    return Text(
                      userName,
                      style: TextStyle(fontSize: 20.0.sp),
                    );
                  }
                },
              ),
              Spacer(),
              Container(
                width: 90.w, // Adjust the width as needed
                margin: EdgeInsets.fromLTRB(10, 8, 10, 16), // Adjust margin as needed
                child:TextButton(
                  onPressed: () {

                    AwesomeDialog(
                      context: context,
                      dialogType: DialogType.warning,
                      animType: AnimType.rightSlide,
                      btnOkColor: Color.fromRGBO(51, 71, 246, 1),
                      title: "Confirm Sign Out",
                      desc: 'Are you sure you want to sign out?',
                      btnCancelOnPress: () {},
                      btnOkOnPress: () {
                        signOutUser();

                      },
                      dismissOnTouchOutside: false,
                    )..show();
                  },
                  child: Text('Sign Out',
                    style: TextStyle(
                      fontFamily: 'Montserrat-Regular',
                      fontSize:20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),),
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: BorderSide(color: Color.fromRGBO(51, 71, 246, 1)),
                      ),
                    ),
                    backgroundColor: MaterialStatePropertyAll<Color>(Color.fromRGBO(51, 71, 246, 1)),
                  ),
                ),
              ),
              SizedBox(height: 2.0.h),
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

