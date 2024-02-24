
import 'package:flutter/material.dart';

class ReportDetailsPage extends StatefulWidget {
  final int reportId;
  final String status;

  ReportDetailsPage({required this.reportId,required this.status});

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Full Report Details'),
      ),
      body: Center(
        child: Text('Report ID: ${widget.reportId}, status: ${widget.status}'),
      ),
    );
  }
}
