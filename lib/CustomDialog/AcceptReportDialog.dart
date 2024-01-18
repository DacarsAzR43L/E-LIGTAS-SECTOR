import 'package:flutter/material.dart';

class AcceptReportDialog extends StatelessWidget {



  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 200,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('Assets/verified.gif', width: 100, height: 100),
            SizedBox(height: 16),
            Text(
              'Report Successfully Accepted!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            Text(
              'Go to Accepted Reports to see current Accepted Reports.',
              style: TextStyle(
                fontSize: 13.0,
                fontFamily: "Montserrat-Regular",
              ),
            ),

            SizedBox(
              width: 200.0,
              child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll<Color>(Color.fromRGBO(51, 71, 246, 1)),
                  ),
                  child: Text('OK',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}