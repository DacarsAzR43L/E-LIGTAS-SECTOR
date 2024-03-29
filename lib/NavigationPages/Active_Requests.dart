import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sizer/sizer.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_ligtas_sector/CustomDialog/AcceptReportDialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:ui';
import 'dart:typed_data';
import '../CustomDialog/ArchiveReportDialog.dart';
import '../local_notifications.dart';


class ActiveRequestCard {
  final int id;
  final String name;
  final String emergencyType;
  final String date;
  final locationLink;
  final phoneNumber;
  final message;
  final residentProfile;
  final List<String> image;
  final locationName;
  final reportId;

  ActiveRequestCard({
    required this.id,
    required this.reportId,
    required this.name,
    required this.emergencyType,
    required this.date,
    required this.locationLink,
    required this.phoneNumber,
    required this.message,
    required this.residentProfile,
    required this.image,
    required this.locationName,
  });
}


class ActiveRequestScreen extends StatefulWidget {
  final Function(int) updatePreviousListLength;

  ActiveRequestScreen({required this.updatePreviousListLength});

  @override
  _ActiveRequestScreenState createState() => _ActiveRequestScreenState(
    previousListLength: 0, // or any default value you want to set initially
    updatePreviousListLength: updatePreviousListLength,
  );

}



class _ActiveRequestScreenState extends State<ActiveRequestScreen> {

  int? expandedCardIndex;
  List<ActiveRequestCard> activeRequestList = [];
  late Timer _timer;
  late Database _database;
  int newItemsCount = 0;
  String status = "1";
  String statusArchive ="2";
  int previousListLength;
  final Function(int) updatePreviousListLength;
  ActiveRequestCard? activeRequestCard;
  final String _tableName = 'active_requests13';
  bool hasInternetConnection = false;


  //Responder Info
  String responderName = '';
  String userFrom = '';


  _ActiveRequestScreenState({
    required this.previousListLength,
    required this.updatePreviousListLength,
  });


  @override
  void initState() {
    super.initState();

    checkInternetConnectionAndInit();
  }

  Future<void> callFetchData() async {
    await fetchData();
  }

  Future<void> checkInternetConnectionAndInit() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // No internet connection, load from local database
      await initDatabase();
      await loadFromLocalDatabase();
    } else {
      // Internet connection is available, initialize the database and start the timer
      await initDatabase();
      print("Intialize DATABASE");
      setState(() {
        hasInternetConnection = true;
      });
      fetchData();
      startTimer();
    }
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 15), (timer) {
      fetchData();
    });
  }

  Future<bool> hasInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = '${documentsDirectory.path}/active_requests13.db';

    _database = await openDatabase(
      path,
      onCreate: (db, version) {
        return db.execute(
          '''
        CREATE TABLE $_tableName (
          id INTEGER PRIMARY KEY,
          reportId INTEGER,
          name TEXT,
          emergencyType TEXT,
          date TEXT,
          locationName TEXT,
          locationLink TEXT,
          phoneNumber TEXT,
          message TEXT,
          residentProfile BLOB,
          image BLOB
        )
        ''',
        );
      },
      version: 1,
    );
  }


  Future<void> fetchDataFromPHP(String email) async {
    final String apiUrl = 'https://eligtas.site/public/storage/get_responder_info.php';

    try {
      // Send a POST request to the PHP script with the email parameter
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'email': email},
      );

      if (response.statusCode == 200) {
        // Decode the response JSON
        Map <String, dynamic> responseData = json.decode(response.body);

        // Extract the values and set them in a string
        responderName = responseData['responder_name'];
        userFrom = responseData['userfrom'];
      } else {
        print('Error: ${response.body}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<void> insertData(int reportId) async {
    final String apiUrl = 'https://eligtas.site/public/storage/accept_responder_report.php';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'status': status,
          'responder_name': responderName,
          'userfrom': userFrom,
          'reportId': reportId.toString(),
          // Keep it as an integer
        },
      );

      if (response.statusCode == 200) {
        final responseData = await json.decode(response.body) as Map<
            String,
            dynamic>;

        if (responseData['success'] == true) {
          print('Data inserted successfully');

          showDialog(
            context: context,
            builder: (context) {
              return AcceptReportDialog();
            },
          );
        } else {
          print('Error: ${responseData['message']}');
          print('Status: $status');
          print('Report ID: ${activeRequestCard?.reportId}');
          print('User From: $userFrom');
          print('Responder Name: $responderName');
        }
      } else {
        print('Failed to connect to the server. Status code: ${response
            .statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<void> insertArchiveData(int reportId) async {
    final String apiUrl = 'https://eligtas.site/public/storage/accept_responder_report.php';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'status': statusArchive,
          'responder_name': responderName,
          'userfrom': userFrom,
          'reportId': reportId.toString(),

        },
      );

      if (response.statusCode == 200) {
        final responseData = await json.decode(response.body) as Map<
            String,
            dynamic>;

        if (responseData['success'] == true) {
          print('Data inserted successfully');

          showDialog(
            context: context,
            builder: (context) {
              return ArchiveReportDialog();
            },
          );
        } else {
          print('Error: ${responseData['message']}');
          print('Status: $status');
          print('Report ID: ${activeRequestCard?.reportId}');
          print('User From: $userFrom');
          print('Responder Name: $responderName');
        }
      } else {
        print('Failed to connect to the server. Status code: ${response
            .statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }


  Future<void> fetchData() async {
    try {
      // Get the user email
      String userEmail = await getUserEmail();

      // Call fetchDataFromPHP with the user email
      await fetchDataFromPHP(userEmail);

      print(userEmail);

      // Your API endpoint with the userFrom parameter
      final String apiUrl = 'https://eligtas.site/public/storage/get_active_reports.php?userfrom=$userFrom';

      // Perform the HTTP GET request
      final response = await http.get(Uri.parse(apiUrl));

      // Check if the response is successful and the widget is still mounted
      if (response.statusCode == 200 && mounted) {
        // Decode the response body
        final List<dynamic> responseData = json.decode(response.body);

        List<ActiveRequestCard> currentFetch = responseData
            .asMap()
            .map((index, data) => MapEntry(
          index,
          ActiveRequestCard(
            id: index,
            reportId: data['report_id'],
            name: data['resident_name'],
            emergencyType: data['emergency_type'],
            date: data['dateandTime'],
            locationName: data['locationName'],
            locationLink: data['locationLink'],
            phoneNumber: data['phoneNumber'],
            message: data['message'],
            residentProfile: data['residentProfile'],
            image: (data['imageEvidence'] as List<dynamic>).cast<String>(), // Assuming 'imageEvidence' is a list of file paths
          ),
        ))
            .values
            .toList();

        // Check if the lists are different
        if (!listEquals(activeRequestList, currentFetch)) {
          // Compare and update the local database
          compareAndUpdateDatabase(currentFetch);
        }
      } else {
        // Handle error if the HTTP request is not successful
        await loadFromLocalDatabase();
      }
    } catch (error) {
      // Handle other errors
      await loadFromLocalDatabase();
    }
  }



  // Compare the new data with the local database and update if necessary
  Future<void> compareAndUpdateDatabase(List<ActiveRequestCard> currentFetch) async {
    // Retrieve data from the local database
    List<Map<String, dynamic>> localData = await _database.query(_tableName);

    // Perform the comparison and update the database
    // For simplicity, assuming 'reportId' is a unique identifier
    for (var newItem in currentFetch) {
      if (!localData.any((element) => element['reportId'] == newItem.reportId)) {
        // New item found, perform necessary actions
        // For example, show a notification
        LocalNotifications.showSimpleNotification(
          title: "NEW EMERGENCY REPORT",
          body: "A new report has been received!",
          payload: "New item data: ${newItem.reportId}",
        );

        // Convert each image data to bytes
        List<Uint8List?> compressedImages = [];
        for (String imagePath in newItem.image) {
          List<int>? imageBytes = await getImageBytesFromPath(imagePath);
          if (imageBytes != null) {
            List<int>? compressedImage = await compressImage(imageBytes);
            compressedImages.add(compressedImage != null ? Uint8List.fromList(compressedImage) : null);
          }
        }

        // Check if the compression was successful for all images
        if (compressedImages.every((image) => image != null)) {
          // Update the local database with compressed data
          await _database.insert(
            _tableName,
            {
              'reportId': newItem.reportId,
              'name': newItem.name,
              'emergencyType': newItem.emergencyType,
              'date': newItem.date,
              'locationName': newItem.locationName,
              'locationLink': newItem.locationLink,
              'phoneNumber': newItem.phoneNumber,
              'message': newItem.message,
              'residentProfile': await compressImage(base64Decode(newItem.residentProfile)),
              'image': compressedImages,
            },
          );
        } else {
          print('Image compression failed for reportId ${newItem.reportId}');
        }
      }
    }

    // Update the activeRequestList
    activeRequestList = currentFetch;

    // Save the new length
    savePreviousListLength(activeRequestList.length);

    // Update the previous list length
    updatePreviousListLength(activeRequestList.length);
  }

// Function to retrieve image bytes from file path
  Future<List<int>?> getImageBytesFromPath(String imagePath) async {
    try {
      // Read image file as bytes
      File imageFile = File(imagePath);
      return await imageFile.readAsBytes();
    } catch (e) {
      print('Error reading image file: $e');
      return null;
    }
  }


// Function to retrieve data from the local database
  Future<List<Map<String, dynamic>>> getLocalData() async {
    return await _database.query(_tableName);
  }

  Future<Uint8List?> compressImage(List<int> imageBytes) async {
    // Convert List<int> to Uint8List
    Uint8List uint8ImageBytes = Uint8List.fromList(imageBytes);

    // Specify the compression quality (0 to 100, where 100 means no compression)
    int quality = 30;

    // Compress the image
    List<int> compressedBytes = await FlutterImageCompress.compressWithList(
      uint8ImageBytes,
      quality: quality,
    );

    // Return the compressed image bytes as Uint8List
    return compressedBytes.isNotEmpty
        ? Uint8List.fromList(compressedBytes)
        : null;
  }


  Future<void> loadFromLocalDatabase() async {
    // Load data from the local database
    List<Map<String, dynamic>> result = await _database.query(_tableName);

    setState(() {
      List<ActiveRequestCard> currentFetch = result
          .map((data) => ActiveRequestCard(
        id: data['id'],
        reportId: data['reportId'],
        name: data['name'],
        emergencyType: data['emergencyType'],
        date: data['date'],
        locationName: data['locationName'],
        locationLink: data['locationLink'],
        phoneNumber: data['phoneNumber'],
        message: data['message'],
        residentProfile: base64Encode(data['residentProfile']),
        image: [base64Encode(data['image'])], // Wrap in a list
      ))
          .toList();

      // Update the activeRequestList
      activeRequestList = currentFetch;

      // Save the new length
      savePreviousListLength(activeRequestList.length);

      // Update the previous list length
      updatePreviousListLength(activeRequestList.length);
    });
  }


  Future<void> removeItem(int index, int reportId) async {
    var connectivityResult = await (Connectivity().checkConnectivity());

    if (connectivityResult != ConnectivityResult.none) {
      // There is an internet connection, perform operations
      setState(() {
        // Remove the item from the list
        activeRequestList.removeAt(index);
        print("Removing item with reportId: $reportId");
        insertData(reportId);
        // Update the previous list length and notify the parent widget
        savePreviousListLength(activeRequestList.length);
        updatePreviousListLength(activeRequestList.length);
      });

      // Delete the corresponding record from the local database
      await _database.delete(
        _tableName,
        where: 'reportId = ?',
        whereArgs: [reportId],
      );
    } else {
      // No internet connection, show a dialog or perform other actions
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('No Internet Connection'),
            content: Text(
                'Please check your internet connection and try again.'),
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

  Future<void> ArchiveItem(int index, int reportId) async {
    var connectivityResult = await (Connectivity().checkConnectivity());

    if (connectivityResult != ConnectivityResult.none) {
      // There is an internet connection, perform operations
      setState(() {
        // Remove the item from the list
        activeRequestList.removeAt(index);
        insertArchiveData(reportId);

        // Update the previous list length and notify the parent widget
        savePreviousListLength(activeRequestList.length);
        updatePreviousListLength(activeRequestList.length);
      });

      // Delete the corresponding record from the local database
      await _database.delete(
        _tableName,
        where: 'reportId = ?',
        whereArgs: [reportId],
      );
    } else {
      // No internet connection, show a dialog or perform other actions
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('No Internet Connection'),
            content: Text(
                'Please check your internet connection and try again.'),
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

  Future<void> loadPreviousListLength() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int savedPreviousListLength = prefs.getInt('previousListLength') ?? 0;
    print('Loaded Previous List Length: $savedPreviousListLength');
    setState(() {
      previousListLength = savedPreviousListLength;
      widget.updatePreviousListLength(
          previousListLength); // Call the callback function
    });
  }

  Future<void> savePreviousListLength(int length) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('previousListLength', length);
  }




  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Reports'),
      ),
      body: activeRequestList.isEmpty
          ? Center(
        child: FutureBuilder(
          future: hasInternet(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.data == true) {
              // Internet connection is available
              return Text('No pending reports available.');
            } else {
              // No internet connection
              return Text('Please check your internet connection.');
            }
          },
        ),
      )
          : ListView.builder(
        itemCount: activeRequestList.length,
        itemBuilder: (context, index) {
          return _buildActiveRequestCard(index);
        },
      ),
    );
  }


  Widget _buildActiveRequestCard(int index) {
    ActiveRequestCard activeRequestCard = activeRequestList[index];

    if (index >= previousListLength) {
      newItemsCount++;
    }

    Key cardKey = Key('activeRequestCard_$index');

    return KeyedSubtree(
      key: cardKey,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (expandedCardIndex == index) {
              expandedCardIndex = null;
            } else {
              expandedCardIndex = index;
            }
          });
        },
        child: Card(
          key: cardKey,
          margin: EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 1.h),
                child: Text(
                  'Report ID: ${activeRequestCard.reportId}',
                  style: TextStyle(
                    fontSize: 12.0, // You can adjust the font size
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 50.0,
                  height: 100.0,
                  child: ClipOval(
                    clipBehavior: Clip.hardEdge,
                    child: CachedMemoryImage(
                      uniqueKey: 'app://imageProfile/${activeRequestCard
                          .reportId}',
                      base64: activeRequestCard.residentProfile,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Text(activeRequestCard.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Emergency Type: ${activeRequestCard.emergencyType}'),
                    Text('Date: ${activeRequestCard.date}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        AwesomeDialog(
                          context: context,
                          dialogType: DialogType.warning,
                          animType: AnimType.rightSlide,
                          btnOkColor: Color.fromRGBO(51, 71, 246, 1),
                          title: 'Confirm Rescue',
                          desc: 'Are you sure you want to accept this report? ',
                          btnCancelOnPress: () {},
                          btnOkOnPress: () {
                            removeItem(index, activeRequestCard.reportId);
                          },
                          dismissOnTouchOutside: false,
                        )
                          ..show();
                      },
                      child: Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 30.0,
                      ),
                    ),
                    SizedBox(width: 10.0), // Add some space between icons
                    GestureDetector(
                      onTap: () {
                        AwesomeDialog(
                          context: context,
                          dialogType: DialogType.warning,
                          animType: AnimType.rightSlide,
                          btnOkColor: Color.fromRGBO(51, 71, 246, 1),
                          title: 'Archive Rescue',
                          desc: 'Are you sure you want to archive this report? ',
                          btnCancelOnPress: () {},
                          btnOkOnPress: () {
                            ArchiveItem(index, activeRequestCard.reportId);
                          },
                          dismissOnTouchOutside: false,
                        )
                          ..show();

                      },
                      child: Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 30.0,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 500,
                child: Visibility(
                  visible: expandedCardIndex == index,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 500,
                          child: Visibility(
                            visible: expandedCardIndex == index,
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  SizedBox(height: 5.0),
                                  SizedBox(height: 5.0),
                                  Row(
                                    children: [
                                      Text('Location Name: '),
                                      SizedBox(width: 5.0),
                                      Flexible(child: Text(activeRequestCard.locationName ?? "", softWrap: true)),
                                    ],
                                  ),
                                  SizedBox(height: 5.0),
                                  Row(
                                    children: [
                                      Text('Location Link: ', style: TextStyle(color: Colors.black)),
                                      SizedBox(width: 5.0),
                                      Flexible(
                                        child: GestureDetector(
                                          onTap: () {
                                            launch(activeRequestCard.locationLink ?? "");
                                          },
                                          child: Text(
                                            '${activeRequestCard.locationLink ?? ""}',
                                            softWrap: true,
                                            style: TextStyle(
                                              color: Colors.blue,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 5.0),
                                  GestureDetector(
                                    onTap: () {
                                      launch('tel:+${activeRequestCard.phoneNumber}');
                                    },
                                    child: Row(
                                      children: [
                                        Text('Phone Number: '),
                                        SizedBox(width: 5.0),
                                        Text(
                                          '+${activeRequestCard.phoneNumber ?? ""}',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 5.0),
                                  Row(
                                    children: [
                                      Text('Message: '),
                                      SizedBox(width: 5.0),
                                      Flexible(child: Text(activeRequestCard.message ?? "", softWrap: true)),
                                    ],
                                  ),
                                  SizedBox(height: 10.0),
                                  Container(
                                    width: double.infinity,
                                    height: 400,
                                    child: Swiper(
                                      loop: false,
                                      itemBuilder: (BuildContext context, int index) {
                                        return Container(
                                          alignment: Alignment.center,
                                          child: Image.memory(
                                            base64Decode(activeRequestCard.image[index]),
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      },
                                      itemCount: activeRequestCard.image.length,
                                      pagination: SwiperPagination(), // Add pagination dots if needed
                                      control: SwiperControl(), // Add control arrows if needed
                                      // Other Swiper configurations
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
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