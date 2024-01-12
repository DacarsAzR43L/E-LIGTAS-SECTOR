import 'dart:async';
import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:isolate';
import 'dart:ui';

class AcceptedReportsCard {
  final int id;
  final String name;
  final String emergencyType;
  final String date;
  final locationLink;
  final phoneNumber;
  final message;
  final residentProfile;
  final image;
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
  int previousListLength =0;
  AcceptedReportsCard? acceptedReportsCard;

  // Responder Info
  String responderName = '';
  String userFrom = '';




  @override
  void initState() {
    super.initState();

    fetchData();

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

          // Check if the lists are different
          if (!listEquals(acceptedReportslist, currentFetch)) {
            // Calculate new items count
            int newItemsCountInCurrentFetch =
                currentFetch.length - acceptedReportslist.length;

            if (newItemsCountInCurrentFetch > 0) {
              // New items are added
              print('New items added!');
              print(
                  'New items count in current fetch: $newItemsCountInCurrentFetch');

              // Update the total new items count
              newItemsCount += newItemsCountInCurrentFetch;
              print(newItemsCount);
            } else {
              // No new items, set newItemsCount to 0
              newItemsCount = 0;
            }

            // Update the acceptedReportslist with the reversed list
            acceptedReportslist = currentFetch;

            // Save the new length
            savePreviousListLength(acceptedReportslist.length);
          }
        });
      } else {
        print('Error: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error: $error');
    }
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
      body: ListView.builder(
        itemCount: acceptedReportslist.length,
        itemBuilder: (context, index) {
          return _buildActiveRequestCard(index);
        },
      ),
    );
  }

  Widget _buildActiveRequestCard(int index) {
    acceptedReportsCard = acceptedReportslist[index];

    if (index >= previousListLength) {
      newItemsCount++;
    }

    Key cardKey = Key('acceptedReportsCard_$index');

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
            children: [
              ListTile(
                leading: ClipOval(
                  child: CachedMemoryImage(
                    uniqueKey:
                    'app://imageProfile/${acceptedReportsCard?.reportId}',
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
                        SizedBox(height: 5.0,),
                        SizedBox(height: 5.0,),
                        Row(
                          children: [
                            Text('Location Name: ',),
                            SizedBox(width: 5.0,),
                            Flexible(child: Text(acceptedReportsCard?.locationName, softWrap: true)),
                          ],
                        ),
                        SizedBox(height: 5.0,),
                        Row(
                          children: [
                            Text('Location Link: ', style: TextStyle(color: Colors.black)),
                            SizedBox(width: 5.0,),
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
                        SizedBox(height: 5.0,),
                        GestureDetector(
                          onTap: () {
                            launch('tel:+${acceptedReportsCard?.phoneNumber}');
                          },
                          child: Row(
                            children: [
                              Text('Phone Number: '),
                              SizedBox(width: 5.0,),
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
                        SizedBox(height: 5.0,),
                        Row(
                          children: [
                            Text('Message: ',),
                            SizedBox(width: 5.0,),
                            Flexible(child: Text(acceptedReportsCard?.message, softWrap: true)),
                          ],
                        ),
                        SizedBox(height: 10.0,),
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
    );
  }

}

Future<String> getUserEmail() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userEmail') ?? '';
}
