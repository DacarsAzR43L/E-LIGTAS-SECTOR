import 'dart:convert';

import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

class InitialReportsCard {
  final int id;
  final String name;
  final String emergencyType;
  final String date;
  final locationLink;
  final phoneNumber;
  final message;
  final String residentProfile;
  final List<String> image;
  final locationName;
  final reportId;
  final sectorName;

  InitialReportsCard({
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
    required this.sectorName,
  });
}

class ReportDetailsPage extends StatefulWidget {
  final int reportId;
  final String status;

  ReportDetailsPage({required this.reportId, required this.status});

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  List<dynamic>? reportData;
  List<dynamic>? spotReportData;
  List<InitialReportsCard> initialReportslist = [];
  InitialReportsCard? initialReportsCard;

  @override
  void initState() {
    super.initState();
    fetchInitialReportData();
    fetchSpotReportData();
  }

  Future<void> fetchInitialReportData() async {
    try {
      String apiUrl = 'https://eligtas.site/public/storage/get_initial_report.php?report_id=${widget.reportId}';

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        setState(() {
          initialReportslist = responseData
              .asMap()
              .map((index, data) =>
              MapEntry(
                index,
                InitialReportsCard(
                  id: index,
                  reportId: data['report_id'],
                  sectorName: data['SectorName'],
                  name: data['resident_name'],
                  emergencyType: data['emergency_type'],
                  date: data['dateandTime'],
                  locationName: data['locationName'],
                  locationLink: data['locationLink'],
                  phoneNumber: data['phoneNumber'],
                  message: data['message'],
                  residentProfile: data['residentProfile'],
                  image: (data['imageEvidence'] as List<dynamic>).cast<String>(),
                ),
              ))
              .values
              .toList();

          // Set initialReportsCard to the first item in the list
          initialReportsCard = initialReportslist[0];
        });
      } else {
        print('Failed to load report');
      }
    } catch (e) {
      print('Error fetching report: $e');
    }
  }

  Future<void> fetchSpotReportData() async {
    final String apiUrl = 'https://eligtas.site/public/storage/get_spot_report.php?report_id=${widget.reportId}';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200 && mounted) {
        final List<dynamic> responseData = json.decode(response.body);

        setState(() {
          spotReportData = responseData;
        });
      }
    } catch (e) {
      print('Error fetching spot report data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Full Report Details'),
      ),
      body: Padding(
        padding: EdgeInsets.all(5.w),
        child: initialReportslist != null
            ? ListView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Initial Report Details',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 10.0),

                Container(
                  width: 100.0,
                  height: 100.0,
                  child: ClipOval(
                    clipBehavior: Clip.hardEdge,
                    child: initialReportsCard?.residentProfile.isNotEmpty ?? false
                        ? CachedMemoryImage(
                      uniqueKey: 'app://imageProfile/${initialReportsCard!.reportId}',
                      base64: initialReportsCard!.residentProfile,
                      fit: BoxFit.cover,
                    )
                        : Image.asset(
                      'Assets/appIcon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                SizedBox(height: 20.0),
                Text('Report ID: ${widget.reportId}'),
                SizedBox(height: 5.0),
                Text('Resident Name:${initialReportsCard?.name ?? 'N/A'}'),
                SizedBox(height: 5.0),
                Row(
                  children: [
                    Text(
                      'Phone Number: ',
                    ),
                    SizedBox(width: 5.0),
                    GestureDetector(
                      onTap: () {
                        launch('tel:+${initialReportsCard?.phoneNumber}');
                      },
                      child: Text(
                        '+${initialReportsCard?.phoneNumber ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5.0),
                Text('Emergency Type: ${initialReportsCard?.emergencyType ?? 'N/A'}'),
                SizedBox(height: 5.0),
                Text('Date and Time: ${initialReportsCard?.date ?? 'N/A'}'),
                SizedBox(height: 5.0),
                Text(
                  'Rescued By (Brgy/Sector): ${initialReportsCard?.sectorName ?? 'N/A'}',
                ),
                SizedBox(height: 5.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location Link: ',
                    ),
                    SizedBox(width: 5.0),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          launch('${initialReportsCard?.locationLink}');
                        },
                        child: Text(
                          '${initialReportsCard?.locationLink ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5.0),
                Text('Location Name:${initialReportsCard?.locationName ?? 'N/A'}'),

                SizedBox(height: 5.0),

                Row(
                  children: [
                    Text('Message: '),
                    SizedBox(width: 5.0),
                    Flexible(child: Text(
                        initialReportsCard?.message ?? 'N/A',
                        softWrap: true)),
                  ],
                ),

                SizedBox(height: 20.0),
                Text(
                  'Image Evidence:',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 400,
                  child: initialReportsCard?.image == null || initialReportsCard!.image.isEmpty
                      ? Container(
                    alignment: Alignment.center,
                    child: Text(
                      "No image evidence available",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                      : Swiper(
                    loop: false,
                    itemBuilder: (BuildContext context, int swiperIndex) {
                      return Container(
                        alignment: Alignment.center,
                        child: Image.memory(
                          base64Decode(initialReportsCard!.image[swiperIndex]),
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                    itemCount: initialReportsCard!.image.length,
                    pagination: SwiperPagination(), // Add pagination dots if needed
                    control: SwiperControl(), // Add control arrows if needed
                    // Other Swiper configurations
                  ),
                ),


                SizedBox(height: 23.0),

                Divider(),
                SizedBox(height: 10.0),

                Text(
                  'Spot Report Details',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20.0),

                Text(
                  'Correction Message:',
                  style: TextStyle(
                    fontSize: 15.sp,
                  ),
                ),

                SizedBox(height: 5.0),
                Text(
                  spotReportData?[0]['description'] ?? 'N/A',
                  textAlign: TextAlign.justify,
                ),

                SizedBox(height: 10.0),

                Text(
                  'Image Evidence:',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10.0),

                // Display images in base64 for spot report
                Container(
                  height: 400.0,
                  child: spotReportData != null && spotReportData![0]['imageEvidence'] != null
                      ? Swiper(
                    loop: false,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: MemoryImage(
                              base64.decode(spotReportData![0]['imageEvidence'][index]),
                            ),
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                    itemCount: spotReportData![0]['imageEvidence'].length,
                    pagination: SwiperPagination(),
                    control: SwiperControl(),
                  )
                      : Center(
                    child: Text('No image evidence for spot report'),
                  ),
                ),
              ],
            ),
          ],
        )
            : Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
