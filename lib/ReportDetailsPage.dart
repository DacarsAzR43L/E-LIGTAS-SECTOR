import 'dart:convert';

import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    fetchInitialReportData();
    fetchSpotReportData();
  }

  Future<void> fetchInitialReportData() async {
    try {
      String apiUrl = 'https://eligtas.site/public/storage/get_initial_report.php?report_id=${widget
          .reportId}';

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        setState(() {
          reportData = json.decode(response.body);
        });
      } else {
        print('Failed to load report');
      }
    } catch (e) {
      print('Error fetching report: $e');
    }
  }

  Future<void> fetchSpotReportData() async {
    final String apiUrl = 'https://eligtas.site/public/storage/get_spot_report.php?report_id=${widget
        .reportId}';

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
        child: reportData != null
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
                    child: Image.memory(
                      base64.decode(reportData![0]['residentProfile']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                SizedBox(height: 20.0),
                Text('Report ID: ${widget.reportId}'),
                SizedBox(height: 5.0),
                Text('Resident Name: ${reportData![0]['resident_name']}'),
                SizedBox(height: 5.0),
                Row(
                  children: [
                    Text(
                      'Phone Number: ',
                    ),
                    SizedBox(width: 5.0),
                    GestureDetector(
                      onTap: () {
                        launch('tel:+${reportData![0]['phoneNumber']}');
                      },
                      child: Text(
                        '+${reportData![0]['phoneNumber']}',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5.0),
                Text('Emergency Type: ${reportData![0]['emergency_type']}'),
                SizedBox(height: 5.0),
                Text('Date and Time: ${reportData![0]['dateandTime']}'),
                SizedBox(height: 5.0),
                Text(
                  'Rescued By (Brgy/Sector): ${reportData![0]['SectorName']}',
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
                          launch('${reportData![0]['locationLink']}');
                        },
                        child: Text(
                          '${reportData![0]['locationLink']}',
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
                Text('Location Name: ${reportData![0]['locationName']}'),

                SizedBox(height: 5.0),

                Row(
                  children: [
                    Text('Message: '),
                    SizedBox(width: 5.0),
                    Flexible(child: Text(
                        reportData![0]['message'],
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
                  height: 400.0,
                  child: Swiper(
                    loop: false,
                    itemBuilder:
                        (BuildContext context, int index) {
                      return Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: MemoryImage(
                              base64.decode(
                                  reportData![0]['imageEvidence'][index]),
                            ),
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                    itemCount:
                    reportData![0]['imageEvidence'].length,
                    pagination: SwiperPagination(),
                    control: SwiperControl(),
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
                  spotReportData![0]['description'],
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

                // Display images in base64
                // Display images in base64
                Container(
                  height: 400.0,
                  child: Swiper(
                    loop: false,
                    itemBuilder:
                        (BuildContext context, int index) {
                      return Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: MemoryImage(
                              base64.decode(
                                  spotReportData![0]['imageEvidence'][index]),
                            ),
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                    itemCount:
                    spotReportData![0]['imageEvidence'].length,
                    pagination: SwiperPagination(),
                    control: SwiperControl(),
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