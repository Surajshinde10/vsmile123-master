
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vsmile/constant/const.dart';

import '../home_page/dashboard_page.dart';




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
        // Location permission granted, display the splash screen for 3 seconds
        Future.delayed(Duration(seconds: 3), () {
          // After 3 seconds, navigate to the main screen
          _navigateToMainScreen();
        });
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
      backgroundColor:Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Container(
              height: MediaQuery.of(context).size.height / 1.5,
              width: MediaQuery.of(context).size.width / 1.5,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/vsmile_splash.png"),
                ),
              ),
            ),
          ),

        ],
      )
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
