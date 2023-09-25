import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vsmile/dataHandler/appData.dart';
import 'package:vsmile/home_page/dashboard_page.dart';
import 'allWidgets/mainScreen.dart';
import 'allWidgets/placesFetch.dart';
import 'allWidgets/splashScreen.dart';
import 'bluetooth/bluetooth_main_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider(
      create: (context) => AppData(),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(

          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: SplashScreen()
          // home: MapView()

        // home: BluetoothApp()

    ),
    );
  }
}



