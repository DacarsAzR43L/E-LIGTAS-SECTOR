import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui';

class AcceptedReportsCard {
  final int id;
  final String name;
  final String emergencyType;
  final String date;
  final locationLink;
  final phoneNumber;
  final message;
  final String residentProfile;
  final String image;
  final locationName;
  final reportId;

  AcceptedReportsCard({
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

class AcceptedReportsScreen extends StatefulWidget {
  @override
  _AcceptedReportsScreenState createState() => _AcceptedReportsScreenState();
}

class _AcceptedReportsScreenState extends State<AcceptedReportsScreen> {
  int? expandedCardIndex;
  List<AcceptedReportsCard> acceptedReportslist = [];
  int newItemsCount = 0;
  String status = "1";
  late Database _database;
  bool isConnectedToInternet = false;
  int previousListLength =0;
  AcceptedReportsCard? acceptedReportsCard;

  // Responder Info
  String responderName = '';
  String userFrom = '';

  bool isLoading = true;
  bool hasData = true;


  @override
  void initState() {
    super.initState();

    // Initialize the database and check for internet connection
    initDatabase().then((_) {
      checkInternetConnection().then((isConnected) {
        // Fetch data only if there is an internet connection
        if (isConnectedToInternet) {
          fetchData();
        } else {
          initDatabase();
          loadFromLocalDatabase();
        }
      });
    });
  }


  Future<void> initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = '${documentsDirectory.path}/accepted_reports2.db';

    _database = await openDatabase(
      path,
      onCreate: (db, version) {
        return db.execute(
          '''
        CREATE TABLE accepted_reports2 (
          id INTEGER PRIMARY KEY,
          reportId TEXT,
          name TEXT,
          emergencyType TEXT,
          date TEXT,
          locationName TEXT,
          locationLink TEXT,
          phoneNumber TEXT,
          message TEXT,
          residentProfile TEXT,
          image TEXT
        )
        ''',
        );
      },
      version: 1,
    );
  }

  Future<void> checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    setState(() {
      isConnectedToInternet = (connectivityResult != ConnectivityResult.none);
    });
  }



  Future<void> fetchDataFromPHP(String email) async {
    final String apiUrl =
        'http://192.168.100.7/e-ligtas-sector/get_responder_info.php';

    try {
      // Send a POST request to the PHP script with the email parameter
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'email': email},
      );

      if (response.statusCode == 200) {
        // Decode the response JSON
        Map<String, dynamic> responseData = json.decode(response.body);

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



  Future<void> fetchData() async {
    // Set loading to true when fetching data starts
    setState(() {
      isLoading = true;
      hasData = true;
    });

    final String apiUrl =
        'http://192.168.100.7/e-ligtas-sector/get_accepted_reports.php';

    // Get the user email
    String userEmail = await getUserEmail();

    // Call fetchDataFromPHP with the user email
    await fetchDataFromPHP(userEmail);

    print(userEmail);
    print(responderName);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'responder_name': responderName},
      );

      if (response.statusCode == 200 && mounted) {
        final List<dynamic> responseData = json.decode(response.body);

        setState(() {
          List<AcceptedReportsCard> currentFetch = responseData
              .asMap()
              .map((index, data) => MapEntry(
            index,
            AcceptedReportsCard(
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
              image: data['imageEvidence'],
            ),
          ))
              .values
              .toList();

          // Reverse the order of the list
          currentFetch = currentFetch.reversed.toList();

          // Print a message before deleting the previous data
          print('Deleting previous data in the local database...');

          // Start a database transaction to delete previous data
          _database.transaction((txn) async {
            // Delete all previous data from the local database
             txn.delete('accepted_reports2');
            print('Previous data deleted successfully');
          });

          // Check if there are new items
          if (currentFetch.isNotEmpty) {
            // Calculate new items count
            int newItemsCountInCurrentFetch = currentFetch.length;

            // New items are added
            isLoading = false;
            print('New items added!');
            print('New items count in current fetch: $newItemsCountInCurrentFetch');

            // Update the total new items count
            newItemsCount += newItemsCountInCurrentFetch;
            print(newItemsCount);

            // Print a message before inserting new data
            print('Inserting new data into the local database...');

            acceptedReportslist = currentFetch;

            // Insert new data into the local database
            updateLocalDatabase(currentFetch);

            print('Data insertion completed');
          } else {
            // No new items
            isLoading = false;
            hasData = false;
          }
        });
      } else {
        print('Error: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }






  Future<void> updateLocalDatabase(List<AcceptedReportsCard> currentFetch) async {
    try {
      // Start a database transaction
      await _database.transaction((txn) async {
        // Insert new data into the local database
        for (var newItem in currentFetch) {
          // Add additional checks and logging
          print('Inserting new data for reportId: ${newItem.reportId}');

          if (newItem.residentProfile is String && newItem.image is String) {
            // Convert image data to bytes
            List<int> residentProfileBytes = base64Decode(newItem.residentProfile);
            List<int> imageBytes = base64Decode(newItem.image);

            // Ensure that the decoding was successful
            if (residentProfileBytes.isNotEmpty && imageBytes.isNotEmpty) {
              // Insert the new data into the local database
              await txn.insert(
                'accepted_reports2',
                {
                  'reportId': newItem.reportId,
                  'name': newItem.name,
                  'emergencyType': newItem.emergencyType,
                  'date': newItem.date,
                  'locationName': newItem.locationName,
                  'locationLink': newItem.locationLink,
                  'phoneNumber': newItem.phoneNumber,
                  'message': newItem.message,
                  'residentProfile': newItem.residentProfile,
                  'image': newItem.image,
                },
              );
            } else {
              print('Skipping insertion for reportId ${newItem.reportId}: Failed to decode base64 data');
            }
          } else {
            print('Skipping insertion for reportId ${newItem.reportId}: residentProfile and/or image is not a String');
          }
        }
      });

      print('Local database updated successfully');
    } catch (e) {
      print('Error updating local database: $e');
    }
  }





  Future<void> loadFromLocalDatabase() async {
    // Load data from the local database, ordered by date in descending order
    List<Map<String, dynamic>> result = await _database.query(
      'accepted_reports2',
      orderBy: 'date DESC', // Order by date in descending order
    );

    setState(() {
      List<AcceptedReportsCard> currentFetch = result
          .map((data) => AcceptedReportsCard(
        id: data['id'],
        reportId: data['reportId'],
        name: data['name'],
        emergencyType: data['emergencyType'],
        date: data['date'],
        locationName: data['locationName'],
        locationLink: data['locationLink'],
        phoneNumber: data['phoneNumber'],
        message: data['message'],
        residentProfile: data['residentProfile'],
        image: data['image'],
      ))
          .toList();

      // Update the acceptedReportslist with the reversed list
      acceptedReportslist = currentFetch;

      // Save the new length
      savePreviousListLength(acceptedReportslist.length);

      // No loading, as it's local data
      isLoading = false;
    });
  }


  Future<void> loadPreviousListLength() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int savedPreviousListLength = prefs.getInt('previousListLength') ?? 0;
    print('Loaded Previous List Length: $savedPreviousListLength');
    setState(() {
      previousListLength = savedPreviousListLength;
    });
  }

  Future<void> savePreviousListLength(int length) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('previousListLength', length);
  }




  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accepted Reports'),
      ),
      body:  isLoading
          ? Center(
        child: CircularProgressIndicator(), // Show loading indicator
      )
          : hasData
          ? ListView.builder(
        itemCount: acceptedReportslist.length,
        itemBuilder: (context, index) {
          return _buildActiveRequestCard(index);
        },
      )
          : Center(
        child: Text('No data available'), // Show no data text
      ),
    );
  }

  String getTrimmedDate(String fullDate) {
    // Assuming fullDate has the format 'yyyy-MM-dd HH:mm:ss.SSSSSS'
    return fullDate.split(' ')[0];
  }

  Widget _buildActiveRequestCard(int index) {
    acceptedReportsCard = acceptedReportslist[index];

    if (index >= previousListLength) {
      newItemsCount++;
    }

    Key cardKey = Key('acceptedReportsCard_$index');

    // Check if the current report's date is different from the previous one
    bool showDivider = true; // Show divider by default
    if (index > 0) {
      showDivider = getTrimmedDate(acceptedReportslist[index - 1].date) !=
          getTrimmedDate(acceptedReportsCard!.date);
    }

    // Check if the current report's date is the same as the next one
    bool sameDateAsNext = false;
    if (index < acceptedReportslist.length - 1) {
      sameDateAsNext = getTrimmedDate(acceptedReportsCard!.date) ==
          getTrimmedDate(acceptedReportslist[index + 1].date);
    }

    return Column(
      children: [
        if (showDivider) _buildDivider(getTrimmedDate(acceptedReportsCard!.date)),
        KeyedSubtree(
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
                children: [
                  ListTile(
                    leading: ClipOval(
                      child: CachedMemoryImage(
                        uniqueKey: 'app://imageProfile/${acceptedReportsCard?.reportId}',
                        base64: acceptedReportsCard?.residentProfile,
                      ),
                    ),
                    title: Text(acceptedReportsCard!.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Emergency Type: ${acceptedReportsCard?.emergencyType}'),
                        Text('Date: ${acceptedReportsCard?.date}'),
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
                            Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 5.0),
                            SizedBox(height: 5.0),
                            Row(
                              children: [
                                Text('Location Name: '),
                                SizedBox(width: 5.0),
                                Flexible(child: Text(acceptedReportsCard?.locationName, softWrap: true)),
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
                                      launch(acceptedReportsCard?.locationLink);
                                    },
                                    child: Text(
                                      '${acceptedReportsCard?.locationLink}',
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
                                launch('tel:+${acceptedReportsCard?.phoneNumber}');
                              },
                              child: Row(
                                children: [
                                  Text('Phone Number: '),
                                  SizedBox(width: 5.0),
                                  Text(
                                    '+${acceptedReportsCard?.phoneNumber}',
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
                                Flexible(child: Text(acceptedReportsCard?.message, softWrap: true)),
                              ],
                            ),
                            SizedBox(height: 10.0),
                            Container(
                              alignment: Alignment.center,
                              child: acceptedReportsCard?.image != null
                                  ? CachedMemoryImage(
                                uniqueKey: 'app://image/${acceptedReportsCard?.reportId}',
                                base64: acceptedReportsCard?.image,
                              )
                                  : Placeholder(),
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
    );
  }

  Widget _buildDivider(String date) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Colors.grey[300],
      child: Text(
        date,
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


}

Future<String> getUserEmail() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userEmail') ?? '';
}

