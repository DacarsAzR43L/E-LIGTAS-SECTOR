import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CenteredButtonWidget extends StatelessWidget {

  String status ="1";
  String responderName = "miandimatulac23@gmail.com";
  String userFrom = "MDRRMO";
  String reportId = "100";




  Future<void> insertData() async {
    final String apiUrl = 'http://192.168.100.7/e-ligtas-sector/accept_responder_report.php';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'status': status,
          'responder_name': responderName,
          'userfrom': userFrom,
          'reportId': reportId, // Keep it as an integer
        },
      );

      if (response.statusCode == 200) {
        final responseData = await json.decode(response.body) as Map<String, dynamic>;

        if (responseData['success'] == true) {
          print('Data inserted successfully');
        } else {
          print('Error: ${responseData['message']}');
          print('Status: $status');
          print('Report ID: $reportId');
          print('User From: $userFrom');
          print('Responder Name: $responderName');
        }
      } else {
        print('Failed to connect to the server. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Centered Button Example'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            AwesomeDialog(
              context: context,
              dialogType: DialogType.warning,
              animType: AnimType.rightSlide,
              btnOkColor: Color.fromRGBO(51, 71, 246, 1),
              title: 'Confirm Rescue',
              desc: 'Are you sure you want to accept this report? ',
              btnCancelOnPress: () {},
              btnOkOnPress: () {
                insertData();
              },

              dismissOnTouchOutside: false,
            )..show();
          },
          child: Text('Click Me'),
        ),
      ),
    );
  }
}