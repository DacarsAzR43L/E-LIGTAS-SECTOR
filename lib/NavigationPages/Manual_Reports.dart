import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io'as io;
import 'dart:typed_data';
import 'package:http/http.dart' as http;


class ManualReports extends StatefulWidget {
  @override
  _ManualReportsState createState() => _ManualReportsState();
}

class _ManualReportsState extends State<ManualReports> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  //Location
  Position? _currentPosition;
  String _currentAddress = 'Loading...';
  String locationLink ="";
  double latitude = 0;
  double longitude = 0;


  bool _loading = false;
  String emergencyType ="";
  int _selectedButton = 4;


  Future<void> _checkLocationServiceAndGetCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      print('Location services are disabled');

      showAlertDialog('Warning!', 'Please turn on your location service');

      setState(() {
        _loading = false;
      });
      return;
    }

    if (io.Platform.isAndroid) {
      await _requestLocationPermissionAndroid();
    } else if (io.Platform.isIOS) {
      await _requestLocationPermissionIOS();
    }

    // Continue to get the current location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    setState(() {
      _currentPosition = position;
      longitude =position.longitude;
      latitude = position.latitude;
    });

    // Call convertCoordinatesToAddress with the obtained latitude and longitude
    await convertCoordinatesToAddress(position.latitude, position.longitude);

    setState(() {
      _loading = false;
    });

  }

  Future<void> _requestLocationPermissionAndroid() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print('Location permission denied');

      showAlertDialog('Warning!', 'Please grant permission to access your current location!');
    }
  }

  Future<void> convertCoordinatesToAddress(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks != null && placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress = "${place.street}, ${place.subLocality}, ${place.locality}";
        });
      } else {
        setState(() {
          _currentAddress = 'No address found';
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _currentAddress = 'Error occurred during geocoding';
      });
    }
  }

  void showAlertDialog(String title, String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.rightSlide,
      btnOkColor: Color.fromRGBO(51, 71, 246, 1),
      title: title,
      desc: message,
      btnOkOnPress: () {},
      dismissOnTouchOutside: false,
    )..show();
  }

  Future<void> _requestLocationPermissionIOS() async {
    // On iOS, location permission is usually requested when you attempt to use location services.
  }


  Widget _buildButton(int buttonIndex, String label, IconData icon, Color color)
  {
    return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedButton = buttonIndex;

              switch (_selectedButton) {
                case 0:
                  print('Fire');
                  setState(() {
                    emergencyType ='Fire';
                  });
                  break;
                case 1:
                  print('Crime');
                  setState(() {
                    emergencyType ='Crime';
                  });
                  break;
                case 2:
                  print('Accident');
                  setState(() {
                    emergencyType ='Accident';
                  });
                  break;
                case 3:
                  print('Medical');
                  setState(() {
                    emergencyType ='Fire';
                  });
                  break;
                default:
                  print('Null Emergency');
              }

            });
            print(_selectedButton);
          },
          child: Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedButton == buttonIndex ? Colors.blueAccent : Colors.black,
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedButton = buttonIndex;
                  switch (_selectedButton) {
                    case 0:
                      print('Fire');
                      setState(() {
                        emergencyType ='Fire';
                      });
                      break;
                    case 1:
                      print('Crime');
                      setState(() {
                        emergencyType ='Crime';
                      });
                      break;
                    case 2:
                      print('Accident');
                      setState(() {
                        emergencyType ='Accident';
                      });
                      break;
                    case 3:
                      print('Medical');
                      setState(() {
                        emergencyType ='Medical';
                      });
                      break;
                    default:
                      print('Default Emergency');
                  }
                });
                print(_selectedButton);
              },
              icon: Icon(
                icon,
                size: 24,
              ),
              label: Text(
                label,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22.0,
                ),
              ),
            ),
          ),

        ));
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(2.0.h), // Use sizer for padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Manual Reports',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.0.h),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(labelText: 'Name'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 2.0.h),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,

                        children: [
                          Text('Location: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.sp,
                              color: Colors.black,
                              fontFamily: "Montserrat-Regular",
                            ),
                          ),

                          Container(
                           width: 38.w,
                            // decoration: BoxDecoration(
                            // color: Colors.white,
                            //border: Border.all(
                            //color: Colors.red,
                            //  width: 5,
                            // )),
                            child:   _currentPosition != null
                                ?  Text(_currentAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.black,
                                fontFamily: "Montserrat-Regular",
                              ),
                            )
                                : Text('Location has not fetched yet', maxLines: 1,
                              overflow: TextOverflow.ellipsis,),
                          ),


                          SizedBox(width:1.0),

                          TextButton.icon(
                            onPressed: () {
                              _loading ? null : _checkLocationServiceAndGetCurrentLocation();
                            },
                            icon: Icon(Icons.location_on,size: 15.0,),
                            label:_loading
                                ? CircularProgressIndicator()
                                : Text('Get Location'),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(Colors.white),
                              foregroundColor: MaterialStateProperty.all(Colors.black),
                              padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                                EdgeInsets.symmetric(vertical: 0, horizontal:5),
                              ),
                            ),
                          ),


                        ],
                      ),
                      SizedBox(height: 2.0.h),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildButton(0, 'Fire',Icons.local_fire_department_outlined, Colors.blue),
                              _buildButton(1, 'Crime', Icons.local_police_outlined,Colors.blue),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildButton(2, 'Accident', Icons.car_crash,Colors.blue),
                              _buildButton(3, 'Medical', Icons.medical_information_outlined, Colors.blue),
                            ],
                          ),
                        ],
                      ),



                      TextFormField(
                        controller: phoneNumberController,
                        decoration: InputDecoration(labelText: 'Phone Number'),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 2.0.h),


                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Describe your Situation',
                            style: TextStyle(

                              fontSize: 15.0,
                              color: Colors.grey,
                              fontFamily: "Montserrat-Regular",
                            ),
                          ),

                          SizedBox(height: 10.0),

                          SizedBox(
                            width: double.infinity, // <-- TextField width
                            height: 150, // <-- TextField height
                            child: TextFormField(
                              controller: messageController,
                              expands: true,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              decoration: InputDecoration(
                                isCollapsed: true,
                                // isDense: true,
                                hintText: 'Enter your Message',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.only(top:15.0,bottom: 20.0, left:10.0, right: 10.0),
                              ),
                              validator: (value) {

                                if (value == null || value.isEmpty ) {
                                  return "Please Input Description";
                                }
                                return null;

                              },

                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.0.h),
                      Container(
                        color: Colors.grey.shade200,
                        padding: EdgeInsets.all(2.0.h),
                        child: Text(
                          'Additional Container Below Form',
                          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 2.0.h),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // Perform form submission logic
                            // For example, you can save the form data to a database
                            // or navigate to the next screen
                          }
                        },
                        child: Text('Submit'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
