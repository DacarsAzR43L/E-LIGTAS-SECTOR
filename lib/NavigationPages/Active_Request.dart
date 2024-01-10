import 'dart:async';
import 'dart:convert';
import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActiveRequestCard {
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
  // final report_id;

  ActiveRequestCard({
    required this.id,
    required this.name,
    required this.emergencyType,
    required this.date,
    required this.locationLink,
    required this.phoneNumber,
    required this.message,
    required this.residentProfile,
    required this.image,
    required this.locationName, //required this.report_id,
  });
}

class ActiveRequestScreen extends StatefulWidget {
  @override
  _ActiveRequestScreenState createState() => _ActiveRequestScreenState();
}

class _ActiveRequestScreenState extends State<ActiveRequestScreen> {
  int? expandedCardIndex; // Track the index of the expanded card
  List<ActiveRequestCard> activeRequestList = [];
  late Timer _timer; // Declare a timer variable
  int newItemsCount = 0;
  int previousListLength = 0;


  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchData();


    //setZeroValue('exampleInt', 0);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        // Reached the end of the list, fetch more data if needed
        fetchData();
      }
    });

    // Start the timer in initState
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      // Fetch data every 2 seconds
      fetchData();
      print('Go na' );
    });
  }

  Future<void> fetchData() async {
    final String apiUrl = 'http://192.168.100.7/e-ligtas-sector/get_active_reports.php';
   // int newItemsCountInCurrentFetch = await getZeroValue('exampleInt');
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200 && mounted) {
        final List<dynamic> responseData = json.decode(response.body);

        setState(() {
          int newItemsCountInCurrentFetch = 0;

          List<ActiveRequestCard> currentFetch = responseData
              .asMap()
              .map((index, data) => MapEntry(
            index,
            ActiveRequestCard(
              id: index,
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

          // Count only the new items in the current fetch
          if (currentFetch.length > previousListLength) {
            newItemsCountInCurrentFetch = currentFetch.length - previousListLength;
          }

          // Check if new items are added
          if (newItemsCountInCurrentFetch > 0) {
            // Items are added
            print('New items added!');
            print('New items count in current fetch: $newItemsCountInCurrentFetch');

            // Add items from the previous fetch to the current fetch
            if (newItemsCount > 0) {
              currentFetch.addAll(activeRequestList);
            }

            // Update the total new items count
            newItemsCount += newItemsCountInCurrentFetch;
            // No saving to local storage in this version

            // Update the activeRequestList
            activeRequestList = currentFetch;
          } else {
            // No new items, clear the previous fetch
            activeRequestList = currentFetch;
          }

          // Update the previous list length
          previousListLength = activeRequestList.length;
        });
      } else {
        // Handle server error
        print('Error: ${response.reasonPhrase}');
      }
    } catch (error) {
      // Handle network error
      print('Error: $error');
    }
  }

  /*Future<void> loadNewItemsCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      newItemsCount = prefs.getInt('newItemsCount') ?? 0;
    });
  }*/

  Future<void> setZeroValue(String key, int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(key, value);
  }

  // Function to get an int value from shared preferences
  Future<int> getZeroValue(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? 0;
  }


  @override
  void dispose() {
    // Save the newItemsCount when disposing of the widget

    // Cancel the timer in dispose
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Active Reports'),
      ),
      body: ListView.builder(
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
      // This item is new
      newItemsCount++;
    }

    Key cardKey = Key('activeRequestCard_$index'); // Unique key for each Card

    return KeyedSubtree(
      key: cardKey,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (expandedCardIndex == index) {
              expandedCardIndex =
              null; // Collapse the current card if tapped again
            } else {
              expandedCardIndex = index; // Expand the selected card
            }
          });
        },
        child: Card(
          key: cardKey, // Assign the unique key to the Card widget
          margin: EdgeInsets.all(8.0),
          child: Column(
            children: [
              ListTile(
                leading: ClipOval(
                  child: CachedMemoryImage(
                    uniqueKey: 'app://imageProfile/${activeRequestCard.id}',
                    base64: activeRequestCard.residentProfile,
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
                trailing: Icon(
                  Icons.check,
                  color: Colors.green,
                  size: 30.0,
                ),
              ),
              Container(
                width: 500, // Set a specific width
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
                              Flexible(child: Text(activeRequestCard.locationName, softWrap: true)),
                            ]
                        ),
                        SizedBox(height: 5.0,),
                        Row(
                          children: [
                            Text('Location Link: ', style: TextStyle(color: Colors.black)), // Label
                            SizedBox(width: 5.0,),
                            Flexible(
                              child: GestureDetector(
                                onTap: () {
                                  launch(activeRequestCard.locationLink); // Launch the URL when tapped
                                },
                                child: Text(
                                  '${activeRequestCard.locationLink}',
                                  softWrap: true,
                                  style: TextStyle(
                                    color: Colors.blue, // Customize the link color
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
                            launch('tel:+${activeRequestCard.phoneNumber}');
                          },
                          child: Row(
                            children: [
                              Text('Phone Number: '),
                              SizedBox(width: 5.0,),
                              Text('+${activeRequestCard.phoneNumber}',style: TextStyle(
                                color: Colors.blue, // Customize the link color
                                decoration: TextDecoration.underline,
                              ),),
                            ],
                          ),
                        ),
                        SizedBox(height: 5.0,),
                        Row(
                            children: [
                              Text('Message: ',),
                              SizedBox(width: 5.0,),
                              Flexible(child: Text(activeRequestCard.message, softWrap: true)),
                            ]
                        ),
                        SizedBox(height: 10.0,),
                        Container(
                          alignment: Alignment.center,
                          child: activeRequestCard.image != null
                              ? CachedMemoryImage(
                            uniqueKey: 'app://image/${activeRequestCard.id}',
                            base64: activeRequestCard.image,
                          )
                              : Placeholder(), // Placeholder image
                        ),
                        // Add more details if needed
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
