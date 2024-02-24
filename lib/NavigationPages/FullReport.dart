import 'dart:convert';
import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sizer/sizer.dart';

import '../ReportDetailsPage.dart';

class VerifiedRecordsCard {
  final int reportId;
  final String emergencyType;
  final String residentProfile;
  final String date;
  final String name;
  final String status;

  VerifiedRecordsCard({
    required this.reportId,
    required this.emergencyType,
    required this.residentProfile,
    required this.date,
    required this.name,
    required this.status,
  });
}

class ErrorneousRecordsCard {
  final int reportId;
  final String emergencyType;
  final String residentProfile;
  final String date;
  final String name;
  final String status;

  ErrorneousRecordsCard({
    required this.reportId,
    required this.emergencyType,
    required this.residentProfile,
    required this.date,
    required this.name,
    required this.status,
  });
}

class FullReport extends StatefulWidget {
  @override
  _FullReportState createState() => _FullReportState();
}

class _FullReportState extends State<FullReport> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<VerifiedRecordsCard> verifiedRecords = [];
  List<ErrorneousRecordsCard> errorneousRecords = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    fetchData();
    fetchErrorneousData();
  }

  Future<void> fetchData() async {
    final String apiUrl = 'https://eligtas.site/public/storage/get_verified_reports.php';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200 && mounted) {
        final List<dynamic> responseData = json.decode(response.body);

        setState(() {
          verifiedRecords = responseData
              .map((data) => VerifiedRecordsCard(
            reportId: data['report_id'],
            emergencyType: data['emergency_type'],
            residentProfile: data['residentProfile'],
            date: data['dateandTime'],
            name: data['resident_name'],
            status: data['status'],
          ))
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<void> fetchErrorneousData() async {
    final String apiUrl = 'https://eligtas.site/public/storage/get_errorneous_reports.php';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200 && mounted) {
        final List<dynamic> responseData = json.decode(response.body);

        print(responseData);
        setState(() {
          errorneousRecords = responseData
              .map((data) => ErrorneousRecordsCard(
            reportId: data['report_id'],
            emergencyType: data['emergency_type'],
            residentProfile: data['residentProfile'],
            date: data['dateandTime'],
            name: data['resident_name'],
            status: data['status'],
          ))
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching errorneous data: $e');
    }
  }



  String getTrimmedDate(String fullDate) {
    return fullDate.split(' ')[0];
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

  Widget _buildErrorneousDivider(String date) {
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

  Widget _buildVerifiedReportsCard(int index) {
    VerifiedRecordsCard record = verifiedRecords[index];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportDetailsPage(reportId: record.reportId, status: record.status),
          ),
        );
      },
      child: Column(
        children: [
          _buildDivider(getTrimmedDate(record.date)),
          Card(
            child: ListTile(
              title: Padding(
                padding: EdgeInsets.only(left: 10.0),
                child: Text(
                  'Report ID: ${record.reportId}',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              leading: Container(
                width: 50.0,
                height: 100.0,
                child: ClipOval(
                  clipBehavior: Clip.hardEdge,
                  child: CachedMemoryImage(
                    uniqueKey: 'app://imageProfile/${record.reportId}',
                    base64: record.residentProfile,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${record.name}'),
                  Text('Emergency Type: ${record.emergencyType}'),
                  Text('Date: ${record.date}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorneousReportsCard(int index) {
    ErrorneousRecordsCard record = errorneousRecords[index];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportDetailsPage(reportId: record.reportId, status: record.status),
          ),
        );
      },
      child: Column(
        children: [
          Card(
            child: ListTile(
              title: Padding(
                padding: EdgeInsets.only(left: 10.0),
                child: Text(
                  'Report ID: ${record.reportId}',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              leading: Container(
                width: 50.0,
                height: 100.0,
                child: ClipOval(
                  clipBehavior: Clip.hardEdge,
                  child: CachedMemoryImage(
                    uniqueKey: 'app://imageProfile/${record.reportId}',
                    base64: record.residentProfile,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${record.name}'),
                  Text('Emergency Type: ${record.emergencyType}'),
                  Text('Date: ${record.date}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 1.0.h),
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Verified'),
                  Tab(text: 'Errorneous'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Content for the 'Verified' tab
                  SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(2.0.h),
                      child: Center(
                        child: Column(
                          children: verifiedRecords.map((record) {
                            return _buildVerifiedReportsCard(verifiedRecords.indexOf(record));
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  // Content for the 'Errorneous' tab
                  SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(2.0.h),
                      child: Center(
                        child: Column(
                          children: errorneousRecords.map((record) {
                            return Column(
                              children: [
                                _buildErrorneousDivider(getTrimmedDate(record.date)),
                                _buildErrorneousReportsCard(
                                    errorneousRecords.indexOf(record)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
