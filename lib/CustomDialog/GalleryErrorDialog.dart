import 'package:flutter/material.dart';

class GalleryErrorDialog extends StatelessWidget {
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
            Image.asset('Assets/Error.gif', width: 100, height: 100),
            SizedBox(height: 16),
            Text(
              'Error!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 13),
            Text(
              'Please allow the app to access media.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.0,
                fontFamily: "Montserrat-Regular",
              ),
            ),
            SizedBox(height: 13),
            SizedBox(
              width: 200.0,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss the dialog
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