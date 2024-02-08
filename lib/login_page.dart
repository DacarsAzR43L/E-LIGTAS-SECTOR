import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sizer/sizer.dart';
import 'package:e_ligtas_sector/CustomDialog/LoginSuccessDialog.dart';
import 'Home.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passController = TextEditingController();

  bool passToggle = true;

  Future<void> loginUser() async {

    showDialog(
      context: context,
      builder: (context) {
        return AbsorbPointer( absorbing: true, child: Center(child: CircularProgressIndicator(),));
      },
    );
    final String url = "https://eligtas.site/public/storage/sector-login.php"; // Replace with your PHP script URL

    // Check if 'email' and 'password' are set
    if (emailController.text.isNotEmpty && passController.text.isNotEmpty) {
      final response = await http.post(Uri.parse(url), body: {
        'email': emailController.text,
        'password': passController.text,
      });

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        // Check if 'status' is set in the response
        if (result.containsKey('status')) {
          // Handle different conditions based on specific statuses
          switch (result['status']) {


            case 'Login successful':
              Navigator.of(context).pop();

              final prefs = await SharedPreferences.getInstance();
              prefs.setBool('isLoggedIn', true);
              prefs.setString('userEmail', emailController.text);

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
              showDialog(
                context: context,
                builder: (context) {
                  return LoginSuccessDialog();
                },
              );
              print(result['status']);
              break;


            case 'User account is not active':
              Navigator.of(context).pop();
              AwesomeDialog(
                context: context,
                dialogType: DialogType.warning,
                animType: AnimType.rightSlide,
                title: 'Error!',
                btnOkColor: Color.fromRGBO(51, 71, 246, 1),
                desc: 'User Account is not Active, Please try contacting the Admin for assistance',
                dismissOnTouchOutside: false,
                btnOkOnPress: () {},
              )..show();
              print(result['status']);
              break;


            case 'Password do not match':
              Navigator.of(context).pop();
              AwesomeDialog(
                context: context,
                dialogType: DialogType.warning,
                animType: AnimType.rightSlide,
                title: 'Error!',
                btnOkColor: Color.fromRGBO(51, 71, 246, 1),
                desc: 'Incorrect password, please try again',
                dismissOnTouchOutside: false,
                btnOkOnPress: () {},
              )..show();
              print(result['status']);
              break;


            case 'Database schema issue':
              Navigator.of(context).pop();
              AwesomeDialog(
                context: context,
                dialogType: DialogType.warning,
                animType: AnimType.rightSlide,
                title: 'Error!',
                btnOkColor: Color.fromRGBO(51, 71, 246, 1),
                desc: 'An error Occured, Please Try Again',
                dismissOnTouchOutside: false,
                btnOkOnPress: () {},
              )..show();
              print(result['status']);
              break;

            case 'User does not Exist':
              Navigator.of(context).pop();
              AwesomeDialog(
                context: context,
                dialogType: DialogType.warning,
                animType: AnimType.rightSlide,
                title: 'Error!',
                btnOkColor: Color.fromRGBO(51, 71, 246, 1),
                desc: 'User does not exist, Please try again',
                dismissOnTouchOutside: false,
                btnOkOnPress: () {},
              )..show();
              print(result['status']);
              break;

            default:
            // Handle unexpected status
              Navigator.of(context).pop();
              AwesomeDialog(
                context: context,
                dialogType: DialogType.warning,
                animType: AnimType.rightSlide,
                title: 'Error!',
                btnOkColor: Color.fromRGBO(51, 71, 246, 1),
                desc: 'An error has occured, Please try again',
                dismissOnTouchOutside: false,
                btnOkOnPress: () {},
              )..show();
              print("Unexpected status: ${result['status']}");
              break;
          }
        } else {
          Navigator.of(context).pop();
          AwesomeDialog(
            context: context,
            dialogType: DialogType.warning,
            animType: AnimType.rightSlide,
            title: 'Error!',
            btnOkColor: Color.fromRGBO(51, 71, 246, 1),
            desc: 'An error has occured, Please try again',
            dismissOnTouchOutside: false,
            btnOkOnPress: () {},
          )..show();
          print("Status not provided in the response");
        }
      } else {
        Navigator.of(context).pop();
        AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          animType: AnimType.rightSlide,
          title: 'Error!',
          btnOkColor: Color.fromRGBO(51, 71, 246, 1),
          desc: 'An error has occured, Please try again',
          dismissOnTouchOutside: false,
          btnOkOnPress: () {},
        )..show();
        print("HTTP Error: ${response.statusCode}");
      }
    }
  }

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
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Container(
            width: 100.w,    //It will take a 20% of screen width
            height:90.h,  //It will take a 30% of screen height
            margin: EdgeInsets.fromLTRB(20.0, 30.0, 20.0, 0),
            //decoration: BoxDecoration(
            // color: Colors.white,
            // border: Border.all(
            //color: Colors.red,
            // width: 5,
            // )),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: CircleAvatar(
                    backgroundImage: AssetImage('Assets/appIcon.png'),
                    radius: 15.w,
                  ),
                ),

                SizedBox(height: 10.0,),

                Container(
                  width: 255.0,
                  height: 40.0,
                  alignment: Alignment.center,
                  //decoration: BoxDecoration(
                  // color: Colors.white,
                  //border: Border.all(
                  // color: Colors.red,
                  //  width: 5,
                  // )),
                  child: Text('Log in to your account',
                    style: TextStyle(
                      fontFamily: 'Montserrat-Regular',
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),),
                ),

                SizedBox(height: 25.0,),

                Container(
                  width: 100.w,
                  height: 37.0.h,
                  alignment: Alignment.center,
                  //decoration: BoxDecoration(
                  //color: Colors.white,
                  //  border: Border.all(
                  // color: Colors.red,
                  //width: 5,
                  // )),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text('Email:',
                          style: TextStyle(
                            fontFamily: 'Montserrat-Regular',
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),),

                        SizedBox(height: 9.0,),

                        TextFormField(
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.emailAddress,
                          controller: emailController,
                          decoration: InputDecoration(
                            prefixIcon: new Icon(Icons.email,color: Colors.black,),
                            hintText: 'Email',
                            border: OutlineInputBorder(borderRadius:BorderRadius.circular(10.0),
                                borderSide: BorderSide(color: Color.fromRGBO(122, 122, 122, 1), width: 1.0)),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color.fromRGBO(51, 71, 246, 1),
                                )
                            ),
                          ),
                        ),

                        SizedBox(height: 9.0,),

                        Text('Password:',
                          style: TextStyle(
                            fontFamily: 'Montserrat-Regular',
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),),

                        SizedBox(height: 9.0,),

                        TextFormField(
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.emailAddress,
                          controller: passController,
                          obscureText: passToggle,
                          decoration: InputDecoration(
                            prefixIcon: new Icon(Icons.lock,color: Colors.black,),
                            hintText: 'Password',
                            border: OutlineInputBorder(borderRadius:BorderRadius.circular(10.0),
                                borderSide: BorderSide(color: Color.fromRGBO(122, 122, 122, 1), width: 1.0)),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color.fromRGBO(51, 71, 246, 1),
                                )
                            ),

                            suffixIcon: InkWell(
                              onTap: (){
                                setState(() {
                                  passToggle = !passToggle;
                                });

                              },
                              child: Icon(passToggle ? Icons.visibility_off : Icons.visibility),
                            ),
                          ),
                          validator: (value) {
                            if(value!.isEmpty) {
                              return "Enter Password";

                            }
                            return null;

                          },
                        ),
                      ],
                    ),
                  ),
                ),



                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 400.0,
                      height: 57.0 ,
                      child: TextButton(onPressed: (){

                        if(_formKey.currentState!.validate()){

                          checkInternetConnection();

                        }
                      },
                          child: Text('Log in',
                            style: TextStyle(
                              fontFamily: 'Montserrat-Regular',
                              fontSize:24.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),),
                          style: ButtonStyle(
                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                side: BorderSide(color: Color.fromRGBO(51, 71, 246, 1)),
                              ),),
                            backgroundColor: MaterialStatePropertyAll<Color>(Color.fromRGBO(51, 71, 246, 1)),
                          )),
                    ),



                  ],
                ),


              ],
            ),
          ),
        ),
      ),


    );
  }


  Future<void> checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // No internet connection
      showNoInternetDialog();
    } else {
      // Internet connection is available, proceed with login
      loginUser();
    }
  }

  Future<void> showNoInternetDialog() async {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.rightSlide,
      title: 'Error!',
      btnOkColor: Color.fromRGBO(51, 71, 246, 1),
      desc: 'No Internet Connection, Please try again',
      dismissOnTouchOutside: false,
      btnOkOnPress: () {},
    )..show();
  }


}

