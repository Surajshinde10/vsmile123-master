
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../test.dart';




class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _checkLocationPermission().then((status) {
      if (status == PermissionStatus.granted) {
        // Location permission granted, navigate to the main screen
        _navigateToMainScreen();
      } else {
        // Location permission not granted, show a message and request permission
        _showPermissionMessage();
      }
    });
  }

  Future<PermissionStatus> _checkLocationPermission() async {
    final status = await Permission.location.status;
    return status;
  }

  Future<PermissionStatus> _requestLocationPermission() async {
    final status = await Permission.location.request();
    return status;
  }

  void _showPermissionMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Location Permission Required'),
          content: Text(
            'To use this app, we need access to your device\'s location. '
                'Please grant location permission in the settings.',
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                _requestLocationPermission().then((status) {
                  if (status == PermissionStatus.granted) {
                    // Location permission granted, navigate to the main screen
                    _navigateToMainScreen();
                  }
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToMainScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MapView()), // Replace with your desired screen
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FlutterLogo(
          size: 200.0, // Adjust the size as needed
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen'),
      ),
      body: Center(
        child: Text('Welcome to the Home Screen!'),
      ),
    );
  }
}
