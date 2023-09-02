import 'package:flutter/material.dart';

import 'mainScreen.dart';



class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Simulate a delay for demonstration purposes (e.g., loading data)
    Future.delayed(Duration(seconds: 3), () {
      // After the delay, navigate to the main screen or any other screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainScreen()), // Replace with your desired screen
      );
    });
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
