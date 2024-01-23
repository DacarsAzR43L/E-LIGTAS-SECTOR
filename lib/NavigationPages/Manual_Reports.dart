import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

import '../CustomDialog/GalleryErrorDialog.dart';


class ManualReports extends StatefulWidget {
  @override
  _ManualReportsState createState() => _ManualReportsState();
}

class _ManualReportsState extends State<ManualReports> {

  //FORM VARIABLES
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController messageController = TextEditingController();


  //PERSONAL INFO
  String name = "Not Available";
  String residentProfile = "";
  int phoneNumber = 0;
  String Description = "";

  //PHONE NUMBER
  String finalNumber = "Not Available";
  String countryCode = '63';
  String setcountryCode = '+63';

  //LOCATION
  Position? _currentPosition;
  String _currentAddress = 'Loading...';
  String locationLink ="";
  double latitude = 0;
  double longitude = 0;

  //SELECT TYPE OF REPORT
  bool _loading = false;
  String emergencyType ="";
  int _selectedButton = 4;

  //Camera Permission
  late PermissionStatus status;
  late PermissionStatus statusCamera;

  //PICKED FILE FOR IMAGE EVIDENCE
  late io.File? _imageFile =null;
  late String? _imageName =null;
  late String? _imageData =null;

  //PICKED FILE FOR RESIDENT PROFILE
  late io.File? _imageFile1 =null;
  late String? _imageName1 =null;
  late String? _imageData1 =null;

 // SECTOR FROM INFORMATION
  String responderName = '';
  String userFrom = '';
  String statusReport = "1";



  @override
  void initState() {
    super.initState();
    _loadDefaultImage();
    fetchDataFromPHP();
  }


  // LOCATION METHODS
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


// PICK IMAGE FOR IMAGE EVIDENCE
  Future<void> _showImageSourceDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return io.Platform.isIOS
            ? CupertinoAlertDialog(
          title: Text('Select Image Source'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text('Camera'),
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            CupertinoDialogAction(
              child: Text('Gallery'),
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        )
            : AlertDialog(
          title: Text('Select Image Source'),
          actions: <Widget>[
            TextButton(
              child: Text('Camera'),
              onPressed: ()  {

                //statCamera ==true ||
                if( statusCamera.isGranted) {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                }
                else  {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) {
                      return GalleryErrorDialog();
                    },
                  );
                }
              },
            ),
            TextButton(
              child: Text('Gallery'),
              onPressed: () {

                // statGallery == true ||
                if( status.isGranted ) {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                }
                else {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) {
                      return GalleryErrorDialog();
                    },
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource gallery) async {
    final XFile? image = await ImagePicker().pickImage(source: gallery);

    if (image != null) {
      List<int> imageBytes = await io.File(image.path).readAsBytes();

      // Convert bytes to Uint8List
      Uint8List uint8List = Uint8List.fromList(imageBytes);

      // Encode Uint8List to base64
      String base64Image = 'data:image/${image.path.split('.').last};base64,' + base64Encode(imageBytes);

      setState(() {
        _imageFile = io.File(image.path);
        _imageName = image.path.split('/').last;
        _imageData = base64Image;

        print("Base64 Image Data: $_imageData");
        print("Image Name: $_imageName");
        print("Image File: $_imageFile");
      });
    }
  }


  // PICK IMAGE FOR RESIDENT PROFILE
  Future<void> _showImageSourceDialog1(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return io.Platform.isIOS
            ? CupertinoAlertDialog(
          title: Text('Select Image Source'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text('Camera'),
              onPressed: () {
                Navigator.pop(context);
                _pickImage1(ImageSource.camera);
              },
            ),
            CupertinoDialogAction(
              child: Text('Gallery'),
              onPressed: () {
                Navigator.pop(context);
                _pickImage1(ImageSource.gallery);
              },
            ),
          ],
        )
            : AlertDialog(
          title: Text('Select Image Source'),
          actions: <Widget>[
            TextButton(
              child: Text('Camera'),
              onPressed: ()  {

                //statCamera ==true ||
                if( statusCamera.isGranted) {
                  Navigator.pop(context);
                  _pickImage1(ImageSource.camera);
                }
                else  {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) {
                      return GalleryErrorDialog();
                    },
                  );
                }
              },
            ),
            TextButton(
              child: Text('Gallery'),
              onPressed: () {

                // statGallery == true ||
                if( status.isGranted ) {
                  Navigator.pop(context);
                  _pickImage1(ImageSource.gallery);
                }
                else {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) {
                      return GalleryErrorDialog();
                    },
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage1(ImageSource gallery) async {
    final XFile? image = await ImagePicker().pickImage(source: gallery);

    if (image != null) {
      List<int> imageBytes = await io.File(image.path).readAsBytes();

      // Convert bytes to Uint8List
      Uint8List uint8List = Uint8List.fromList(imageBytes);

      // Encode Uint8List to base64
      String base64Image = 'data:image/${image.path.split('.').last};base64,' + base64Encode(imageBytes);

      setState(() {
        _imageFile1 = io.File(image.path);
        _imageName1 = image.path.split('/').last;
        _imageData1 = base64Image;

        print("Base64 Image Data: $_imageData1");
        print("Image Name: $_imageName1");
        print("Image File: $_imageFile1");
      });
    }
  }


  // LOAD DEFAULT IMAGE
  Future<void> _loadDefaultImage() async {
    ByteData data = await rootBundle.load('Assets/appIcon.png');
    List<int> bytes = data.buffer.asUint8List();
    XFile defaultImage = await _saveToTemporaryFile(bytes);

    setState(() {
      _imageFile1 = io.File(defaultImage.path);
      _imageName1 = defaultImage.path.split('/').last;
      _imageData1 = 'data:image/${defaultImage.path.split('.').last};base64,' + base64Encode(bytes);

      print("Base64 Image Data: $_imageData1");
      print("Image Name: $_imageName1");
      print("Image File: $_imageFile1");

    });
  }

  Future<XFile> _saveToTemporaryFile(List<int> bytes) async {
    try {
      // Get the app's temporary directory
      Directory tempDir = await getTemporaryDirectory();

      // Create a file with a unique name
      String filePath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png';
      io.File file = io.File(filePath);

      // Write the bytes to the file
      await file.writeAsBytes(bytes);

      return XFile(filePath);
    } catch (e) {
      print("Error saving to temporary file: $e");
      throw e; // Rethrow the exception to handle it outside of this function
    }
  }


//SELECT TYPE OF EMERGENCY
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

  //FETCH SECTOR INFO
  Future<void> fetchDataFromPHP() async {
    // Get the user email
    String userEmail = await getUserEmail();

    print(userEmail);

    final String apiUrl =
        'http://192.168.100.7/e-ligtas-sector/get_responder_info.php';

    try {
      // Send a POST request to the PHP script with the email parameter
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'email': userEmail},
      );

      if (response.statusCode == 200) {
        // Decode the response JSON
        Map<String, dynamic> responseData = json.decode(response.body);

        // Extract the values and set them in a string
        responderName = responseData['responder_name'];
        userFrom = responseData['userfrom'];

        print(responderName);
        print(userFrom);

      } else {
        print('Error: ${response.body}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }


  //UPLOAD THE REPORTS
  void uploadData() async {

    // Check for internet connectivity
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // No internet connection
      // Handle the absence of internet connectivity as needed
      print('No internet connection');
      // You may show an error dialog or perform other actions here
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AbsorbPointer(
          absorbing: true,
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );

    try {
      // Your API endpoint
      String apiUrl = "http://192.168.100.7/e-ligtas-sector/send_manual_reports.php";

      // Sample form data
      FormData formData = FormData.fromMap({
        'emergency_type': emergencyType,
        'dateTime': DateTime.now().toLocal().toString(),
        'resident_name': name,
        'locationName': _currentAddress,
        'locationLink': locationLink,
        'phoneNumber': finalNumber,
        'message': Description,
        'responder_name': responderName,
        'userform': userFrom,
        'imageEvidence': await MultipartFile.fromFile(_imageFile!.path, filename: 'image.jpg'),
        'residentProfile': await MultipartFile.fromFile(_imageFile1!.path, filename: 'image.jpg'),
        //'status': statusReport,

      });

      Dio dio = Dio();
      // Send the form data with files using Dio
      Response response = await dio.post(apiUrl, data: formData);

      if (response.statusCode == 200) {
        var responseBody = jsonEncode(response.data);
        var res = jsonDecode(responseBody);

        print('Response from server: $res');

        if (res['success'] == true) {
          Navigator.of(context).pop();

          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            animType: AnimType.rightSlide,
            btnOkColor: Color.fromRGBO(51, 71, 246, 1),
            title: 'Success',
            desc: 'Report Sent Successfully! ',
            btnOkOnPress: () {},
            dismissOnTouchOutside: false,
          )..show();
          print('Image uploaded successfully!');

          setState(() {
            messageController.clear();
            nameController.clear();
            phoneNumberController.clear();
            _selectedButton = 4;
            _imageFile = null;
            _loadDefaultImage();
          });
        }
      }
    } catch (error) {

      Navigator.of(context).pop();
      print('Error: $error');
      // Handle the error as needed
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred. Please try again later.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
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

                Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                          radius: 15.0.w, // Adjusted radius using sizer
                          backgroundColor: Colors.grey,
                          child: _imageFile1 == null
                              ? Icon(Icons.person, size: 15.0.w, color: Colors.white)
                              : ClipOval(
                            child: Image.file(
                              _imageFile1!,
                              width: 40.0.w, // Adjusted width using sizer
                              height: 40.0.w, // Adjusted height using sizer
                              fit: BoxFit.cover,
                            ),
                          ),
                      ),
                      SizedBox(height: 1.0.h), // Adjusted height using sizer

                      ElevatedButton(
                        onPressed: () async {
                          status = await Permission.photos.request();
                          statusCamera = await Permission.camera.request();

                          if (status.isGranted || statusCamera.isGranted) {
                            await _showImageSourceDialog1(context);
                          } else {
                            AwesomeDialog(
                              context: context,
                              dialogType: DialogType.warning,
                              animType: AnimType.rightSlide,
                              btnOkColor: Color.fromRGBO(51, 71, 246, 1),
                              title: 'Error',
                              desc: 'Please Allow Access to the Media or Camera ',
                              btnOkOnPress: () {},
                              dismissOnTouchOutside: false,
                            )..show();
                          }
                        },
                        child: Text(
                          "Upload Image",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: "Montserrat-Regular",
                            fontSize: 12.0.sp, // Adjusted font size using sizer
                          ),
                        ),
                        style: ButtonStyle(
                          backgroundColor:
                          MaterialStatePropertyAll<Color>(Color.fromRGBO(51, 71, 246, 1)),
                        ),
                      ),
                    ] ),
                SizedBox(height: 2.0.h),



                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      Text('Full Name',
                        style: TextStyle(
                          fontSize: 15.0,
                          color: Colors.grey,
                          fontFamily: "Montserrat-Regular",
                        ),
                      ),
                      SizedBox(height: 2.h,),
                      TextFormField(
                        autovalidateMode:
                        AutovalidateMode.onUserInteraction,
                        keyboardType: TextInputType.name,
                        controller: nameController,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(1.0.h), // Adjusted padding using sizer
                          prefixIcon: new Icon(
                            Icons.account_circle_outlined,
                            color: Colors.black,
                          ),
                          hintText: 'Full Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(1.0.h), // Adjusted radius using sizer
                            borderSide: BorderSide(
                              color: Color.fromRGBO(122, 122, 122, 1),
                              width: 1.0.w, // Adjusted width using sizer
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromRGBO(51, 71, 246, 1),
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Enter Name";
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 1.0.h),

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
                           width: 40.w,
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

                      Text('Select the type of report',
                        style: TextStyle(
                          fontSize: 15.0,
                          color: Colors.grey,
                          fontFamily: "Montserrat-Regular",
                        ),
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

                    SizedBox(height: 2.h,),

                      Text('Phone Number',
                        style: TextStyle(
                          fontSize: 15.0,
                          color: Colors.grey,
                          fontFamily: "Montserrat-Regular",
                        ),
                      ),
                      SizedBox(height: 1.0.h), // Adjusted height using sizer

                      TextFormField(
                        autovalidateMode:
                        AutovalidateMode.onUserInteraction,
                        keyboardType: TextInputType.number,
                        controller: phoneNumberController,
                        maxLength: 10,
                        maxLengthEnforcement: null,
                        decoration: InputDecoration(
                          prefixIcon: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 1.3.h, vertical: 1.8.h), // Adjusted padding using sizer
                            child: Text(
                              setcountryCode,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp, // Adjusted font size using sizer
                              ),
                            ),
                          ),
                          hintText: 'e.g +639993161582',
                          contentPadding: EdgeInsets.all(1.0.h), // Adjusted padding using sizer
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(1.0.h), // Adjusted radius using sizer
                            borderSide: BorderSide(
                              color: Color.fromRGBO(122, 122, 122, 1),
                              width: 1.0.w, // Adjusted width using sizer
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromRGBO(51, 71, 246, 1),
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Enter Phone Number";
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

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Upload an Photo Evidence',
                            style: TextStyle(

                              fontSize: 15.0,
                              color: Colors.grey,
                              fontFamily: "Montserrat-Regular",
                            ),
                          ),

                          SizedBox(height: 10.0),

                          GestureDetector(
                            onTap: () async{
                              // Handle the click here
                              status =  await Permission.photos.request();
                              statusCamera =  await Permission.camera.request();

                              if (status.isGranted || statusCamera.isGranted) {
                                await _showImageSourceDialog(context);
                              } else {
                                AwesomeDialog(
                                  context: context,
                                  dialogType: DialogType.warning,
                                  animType: AnimType.rightSlide,
                                  btnOkColor: Color.fromRGBO(51, 71, 246, 1),
                                  title: 'Error',
                                  desc: 'Please Allow Access to the Media or Camera ',
                                  btnOkOnPress: () {},
                                  dismissOnTouchOutside: false,
                                )..show();
                              }
                            },
                            child: DottedBorder(
                              color: Colors.grey,
                              strokeWidth: 2,
                              dashPattern: [10,5],
                              child: Container(
                                color: Colors.grey[200],
                                width: double.infinity,
                                height: 190,
                                child:_imageFile == null ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: AssetImage('Assets/appIcon.png'),
                                        radius: 50.0,
                                      ),
                                      Text(
                                        'Upload an Image',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text('Max of 1 image only',
                                        style: TextStyle(
                                          fontSize: 10.0,
                                          color: Colors.grey,
                                          fontFamily: "Montserrat-Regular",
                                        ),
                                      ),
                                    ],
                                  ),
                                ) : Image.file(
                                  _imageFile!,
                                  width: 170,
                                  height: 170,
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),





                      SizedBox(height: 2.0.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 290.0,
                            height: 50.0 ,
                            child: TextButton(onPressed: (){
                              String _userInput = phoneNumberController.text;

                              if (_formKey.currentState!.validate() && _selectedButton <4&& _imageFile1 !=null && _imageFile !=null &&  _currentPosition != null &&
                              phoneNumberController.text.length ==10
                              ) {


                               Description = messageController.text;

                               name = nameController.text;

                               String mergePhoneNumber = '$countryCode$_userInput';

                               finalNumber = mergePhoneNumber;

                               print('Merged Phone Number: $mergePhoneNumber');

                                Uri myLink = Uri.parse("https://www.google.com/maps/search/?api=1&query=$latitude,$longitude");
                                locationLink = myLink.toString();

                                AwesomeDialog(
                                  context: context,
                                  dialogType: DialogType.warning,
                                  animType: AnimType.rightSlide,
                                  btnOkColor: Color.fromRGBO(51, 71, 246, 1),
                                  title: "Confirm Information",
                                  desc: 'Are you sure that the information is accurate?',
                                  btnCancelOnPress: () {},
                                  btnOkOnPress: () {
                                    uploadData();
                                  },
                                  dismissOnTouchOutside: false,
                                )..show();

                              }

                              else{
                                AwesomeDialog(
                                  context: context,
                                  dialogType: DialogType.warning,
                                  animType: AnimType.rightSlide,
                                  title: 'Warning!',
                                  btnOkColor: Color.fromRGBO(51, 71, 246, 1),
                                  desc: 'All Fields are Required',
                                  btnOkOnPress: () {},
                                )..show();
                              }
                            },
                                child: Text('Submit Report',
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
              ],
            ),
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
