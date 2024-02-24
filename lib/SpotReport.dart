import 'dart:convert';
import 'dart:typed_data';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import 'CustomDialog/GalleryErrorDialog.dart';

class SpotReport extends StatefulWidget {
  final String reportId;
  final String cardIndex;

  SpotReport({required this.reportId, required this.cardIndex});

  @override
  State<SpotReport> createState() => _SpotReportState();
}

class _SpotReportState extends State<SpotReport> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController descriptionController = TextEditingController();

  // Status Permission
  late PermissionStatus status;
  late PermissionStatus statusCamera;

  List<io.File> _imageFiles = [];
  List<String> _imageNames = [];
  List<String> _imageDataList = [];
  String Message="";

  Widget _buildImageWithCloseButton(io.File imageFile, String base64Image, int index) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image.file(
            imageFile,
            width: 50.0,
            height: 50.0,
            fit: BoxFit.cover,
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _imageFiles.removeAt(index);
              _imageDataList.removeAt(index);
            });
          },
          child: CircleAvatar(
            radius: 12.0,
            backgroundColor: Colors.red,
            child: Icon(
              Icons.close,
              color: Colors.white,
              size: 16.0,
            ),
          ),
        ),
      ],
    );
  }

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
                _pickImages1(ImageSource.camera);
              },
            ),
            CupertinoDialogAction(
              child: Text('Gallery'),
              onPressed: () {
                Navigator.pop(context);
                _pickImages(ImageSource.gallery);
              },
            ),
          ],
        )
            : AlertDialog(
          title: Text('Select Image Source'),
          actions: <Widget>[
            TextButton(
              child: Text('Camera'),
              onPressed: () {
                // statCamera ==true ||
                if (statusCamera.isGranted) {
                  Navigator.pop(context);
                  _pickImages1(ImageSource.camera);
                } else {
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
                if (status.isGranted) {
                  Navigator.pop(context);
                  _pickImages(ImageSource.gallery);
                } else {
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

  Future<void> _pickImages1(ImageSource gallery) async {
    try {
      final XFile? image = await ImagePicker().pickImage(source: gallery);

      if (image != null) {

        // Show CircularProgressIndicator while picking images
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Loading images..."),
                ],
              ),
            );
          },
          barrierDismissible: false,
        );

        List<int> imageBytes = await io.File(image.path).readAsBytes();

        // Convert List<int> to Uint8List
        Uint8List uint8List = Uint8List.fromList(imageBytes);

        // Print original image size
        print("Original Size: ${uint8List.length} bytes");

        // Compress image using flutter_image_compress
        List<int> compressedBytes = await FlutterImageCompress.compressWithList(
          uint8List,
          minHeight: 720,
          minWidth: 720,
          quality: 50,
          format: CompressFormat.webp,
        );

        // Print compressed image size
        print("Compressed Size: ${compressedBytes.length} bytes");

        // Save compressed bytes to the image file
        await io.File(image.path).writeAsBytes(compressedBytes);

        // Convert compressed bytes to Uint8List
        Uint8List compressedUint8List = Uint8List.fromList(compressedBytes);

        // Encode Uint8List to base64
        String base64Image =
            'data:image/${image.path.split('.').last};base64,' +
                base64Encode(compressedUint8List);

        // Print image file size after compression
        print(
            "Image File Size After Compression: ${io.File(image.path).lengthSync()} bytes");

        setState(() {
          _imageFiles.add(io.File(image.path));
          _imageNames.add(image.path.split('/').last);
          _imageDataList.add(base64Image);

          print("Base64 Image Data List: $_imageDataList");
          print("Image Names List: $_imageNames");
          print("Image Files List: $_imageFiles");
        });
      }
      // Dismiss the CircularProgressIndicator dialog
      Navigator.pop(context);
    } catch (e) {
      print("Error during image picking: $e");
    }
  }


  Future<void> _pickImages(ImageSource gallery) async {
    try {



      final List<XFile>? newImages = await ImagePicker().pickMultiImage(
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 50,
      );

      if (newImages != null && newImages.isNotEmpty) {

        // Show CircularProgressIndicator while picking images
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Loading images..."),
                ],
              ),
            );
          },
          barrierDismissible: false,
        );

        List<String> base64Images = [];

        for (XFile image in newImages) {
          List<int> imageBytes = await io.File(image.path).readAsBytes();

          // Convert List<int> to Uint8List
          Uint8List uint8List = Uint8List.fromList(imageBytes);

          // Print original image size
          print("Original Size: ${uint8List.length} bytes");

          // Compress image using flutter_image_compress
          List<int> compressedBytes = await FlutterImageCompress.compressWithList(
            uint8List,
            minHeight: 720,
            minWidth: 720,
            quality: 50,
            format: CompressFormat.webp,
          );

          // Print compressed image size
          print("Compressed Size: ${compressedBytes.length} bytes");

          // Save compressed bytes to the image file
          await io.File(image.path).writeAsBytes(compressedBytes);

          // Convert compressed bytes to Uint8List
          Uint8List compressedUint8List = Uint8List.fromList(compressedBytes);

          // Encode Uint8List to base64
          String base64Image =
              'data:image/${image.path.split('.').last};base64,' +
                  base64Encode(compressedUint8List);

          // Print image file size after compression
          print("Image File Size After Compression: ${io.File(image.path).lengthSync()} bytes");

          base64Images.add(base64Image);
        }

        setState(() {
          // Add new images to the existing list
          _imageFiles.addAll(newImages.map((XFile file) => io.File(file.path)));
          _imageDataList.addAll(base64Images);

          print("Updated Base64 Image Data List: $_imageDataList");
          print("Updated Image Files List: $_imageFiles");
        });
      }

      // Dismiss the CircularProgressIndicator dialog
      Navigator.pop(context);
    } catch (e) {
      print("Error during image picking: $e");
    }
  }


  Future<void> uploadData(List<io.File> imageFiles, String message) async {
    try {
      // Check for network connectivity
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        // No Internet Connection
        AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          animType: AnimType.rightSlide,
          btnOkColor: Color.fromRGBO(51, 71, 246, 1),
          title: "Error!",
          desc: 'Please check your Internet Connection!',
          btnCancelOnPress: () {},
          btnOkOnPress: () {
            uploadData(_imageFiles, descriptionController.text);
          },
          dismissOnTouchOutside: false,
        )
          ..show();
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        builder: (context) {
          return AbsorbPointer(
            absorbing: true,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );

      Dio dio = Dio();

      FormData formData = FormData();

      formData.fields.add(MapEntry('report_id', widget.reportId));
      formData.fields.add(MapEntry('message', message));

      for (int i = 0; i < imageFiles.length; i++) {
        formData.files.add(MapEntry(
          'images[]',
          await MultipartFile.fromFile(imageFiles[i].path, filename: 'image_$i.webp'),
        ));
      }

      Response response = await dio.post(
        'https://eligtas.site/public/storage/create_spot_report.php',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      Navigator.of(context).pop(); // Hide loading indicator

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _imageFiles = [];
          descriptionController.clear();
        });

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

        print('API Response: ${response.data}');
      } else {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          btnOkColor: Color.fromRGBO(255, 0, 0, 1),
          title: 'Error',
          desc: 'Failed to send report. Please try again.',
          btnOkOnPress: () {},
          dismissOnTouchOutside: false,
        )..show();

        print('API Error: ${response.statusCode}');
        print('Error Message: ${response.data}');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Hide loading indicator

      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        btnOkColor: Color.fromRGBO(255, 0, 0, 1),
        title: 'Error',
        desc: 'An Error Occurred. Please try again.',
        btnOkOnPress: () {},
        dismissOnTouchOutside: false,
      )..show();

      print('Error uploading data: $e');
    }
  }

  Future<void> uploadFlaggedData(List<io.File> imageFiles, String message) async {
    try {
      // Check for network connectivity
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        // No Internet Connection
        AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          animType: AnimType.rightSlide,
          btnOkColor: Color.fromRGBO(51, 71, 246, 1),
          title: "Error!",
          desc: 'Please check your Internet Connection!',
          btnCancelOnPress: () {},
          btnOkOnPress: () {
            uploadData(_imageFiles, descriptionController.text);
          },
          dismissOnTouchOutside: false,
        )
          ..show();
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        builder: (context) {
          return AbsorbPointer(
            absorbing: true,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );

      Dio dio = Dio();

      FormData formData = FormData();

      formData.fields.add(MapEntry('report_id', widget.reportId));
      formData.fields.add(MapEntry('message', message));

      for (int i = 0; i < imageFiles.length; i++) {
        formData.files.add(MapEntry(
          'images[]',
          await MultipartFile.fromFile(imageFiles[i].path, filename: 'image_$i.webp'),
        ));
      }

      Response response = await dio.post(
        'https://eligtas.site/public/storage/create_flagged_report.php',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      Navigator.of(context).pop(); // Hide loading indicator

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _imageFiles = [];
          descriptionController.clear();
        });

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

        print('API Response: ${response.data}');
      } else {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          btnOkColor: Color.fromRGBO(255, 0, 0, 1),
          title: 'Error',
          desc: 'Failed to send report. Please try again.',
          btnOkOnPress: () {},
          dismissOnTouchOutside: false,
        )..show();

        print('API Error: ${response.statusCode}');
        print('Error Message: ${response.data}');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Hide loading indicator

      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        btnOkColor: Color.fromRGBO(255, 0, 0, 1),
        title: 'Error',
        desc: 'An Error Occurred. Please try again.',
        btnOkOnPress: () {},
        dismissOnTouchOutside: false,
      )..show();

      print('Error uploading data: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return  WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, 'Data you want to pass back');
        return false; // Return false to prevent the screen from being popped immediately
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text("Spot Report"),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Report ID: ${widget.reportId}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
                SizedBox(height: 20.0),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Enter Information:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    SizedBox(height: 10.0),
                    SizedBox(
                      width: double.infinity,
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 200,
                              child: TextFormField(
                                controller: descriptionController,
                                expands: true,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                decoration: InputDecoration(
                                  isCollapsed: true,
                                  hintText: 'Enter your Message',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.only(
                                    top: 15.0,
                                    bottom: 20.0,
                                    left: 10.0,
                                    right: 10.0,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Please Input Description";
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(height: 10.0),
                            Text(
                              "Upload Image:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                              ),
                            ),
                            SizedBox(height: 10.0),
                            DottedBorder(
                              color: Colors.grey,
                              strokeWidth: 2,
                              dashPattern: [10, 5],
                              child: Container(
                                color: Colors.grey[200],
                                width: double.infinity,
                                height: 190,
                                child: _imageFiles.isNotEmpty
                                    ? Center(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: Container(
                                      padding: EdgeInsets.all(10.0),
                                      child: Wrap(
                                        spacing: 10.0,
                                        runSpacing: 10.0,
                                        children: List.generate(
                                          _imageFiles.length,
                                              (index) => _buildImageWithCloseButton(
                                            _imageFiles[index],
                                            _imageDataList[index],
                                            index,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                    : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: AssetImage('Assets/appIcon.png'),
                                        radius: 50.0,
                                      ),
                                      Text(
                                        'Upload Evidence Photos',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10.0),
                            Center(
                              child: TextButton(
                                onPressed: () async {
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
                                child: Text(
                                  'Select Image',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat-Regular',
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ButtonStyle(
                                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      side: BorderSide(color: Color.fromRGBO(51, 71, 246, 1)),
                                    ),
                                  ),
                                  backgroundColor: MaterialStateProperty.all<Color>(Color.fromRGBO(51, 71, 246, 1)),
                                ),
                              ),
                            ),
                            SizedBox(height: 20.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () {

                                    if (formKey.currentState!.validate()) {
                                      // Check if _imageFiles is not null and not empty
                                      if (_imageFiles != null && _imageFiles.isNotEmpty) {

                                        AwesomeDialog(
                                          context: context,
                                          dialogType: DialogType.warning,
                                          animType: AnimType.rightSlide,
                                          btnOkColor: Color.fromRGBO(51, 71, 246, 1),
                                          title: "Confirm Information",
                                          desc: 'Are you sure that the information is accurate?',
                                          btnCancelOnPress: () {},
                                          btnOkOnPress: () {
                                            uploadData(_imageFiles, descriptionController.text);
                                          },
                                          dismissOnTouchOutside: false,
                                        )
                                          ..show();

                                      } else {

                                        AwesomeDialog(
                                          context: context,
                                          dialogType: DialogType.warning,
                                          animType: AnimType.rightSlide,
                                          btnOkColor: Color.fromRGBO(51, 71, 246, 1),
                                          title: "Error!",
                                          desc: 'An error occurred, Please try again!',
                                          btnCancelOnPress: () {},
                                          btnOkOnPress: () {
                                            uploadData(_imageFiles, descriptionController.text);
                                          },
                                          dismissOnTouchOutside: false,
                                        )
                                          ..show();
                                      }
                                    }

                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),// Set background color to green
                                  ),
                                  child: Text(
                                    'Mark as Verified ✔',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    if (formKey.currentState!.validate()) {
                                      // Check if _imageFiles is not null and not empty
                                      if (_imageFiles != null && _imageFiles.isNotEmpty) {

                                        AwesomeDialog(
                                          context: context,
                                          dialogType: DialogType.warning,
                                          animType: AnimType.rightSlide,
                                          btnOkColor: Color.fromRGBO(51, 71, 246, 1),
                                          title: "Confirm Information",
                                          desc: 'Are you sure that the information is accurate?',
                                          btnCancelOnPress: () {},
                                          btnOkOnPress: () {
                                            uploadFlaggedData(_imageFiles, descriptionController.text);
                                          },
                                          dismissOnTouchOutside: false,
                                        )
                                          ..show();

                                      } else {

                                        AwesomeDialog(
                                          context: context,
                                          dialogType: DialogType.warning,
                                          animType: AnimType.rightSlide,
                                          btnOkColor: Color.fromRGBO(51, 71, 246, 1),
                                          title: "Error!",
                                          desc: 'An error occurred, Please try again!',
                                          btnCancelOnPress: () {},
                                          btnOkOnPress: () {
                                            uploadData(_imageFiles, descriptionController.text);
                                          },
                                          dismissOnTouchOutside: false,
                                        )
                                          ..show();
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),// Set background color to red
                                  ),
                                  child: Text(
                                    'Mark as Erroneous X',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),

                          ],
                        ),
                      ),
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
}
