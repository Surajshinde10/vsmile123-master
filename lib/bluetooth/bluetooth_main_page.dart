// import 'dart:convert';
// import 'dart:typed_data';

// import 'package:flutter/material.dart';

// import '../constant/const.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: BluetoothApp(),
//     );
//   }
// }

// class BluetoothApp extends StatefulWidget {
//   @override
//   _BluetoothAppState createState() => _BluetoothAppState();
// }

// class _BluetoothAppState extends State<BluetoothApp> {


//   @override
//   void initState() {
//     super.initState();

//     // Get current Bluetooth state
    
//   }


//   void _connectToRodie() {}



 
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: kScaffoldBackground,
//       appBar: AppBar(
//         backgroundColor: KCard1,
//         title: Padding(
//           padding: const EdgeInsets.only(right: 40),
//           child: Center(
//               child: Text(
//             'Bluetooth Device Connectivity',
//             style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
//           )),
//         ),
//       ),
//       body: Center(
//         child: Column(
//           children: <Widget>[
//             SizedBox(
//               height: 30,
//             ),
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Text(
//                 'Please Connect with VSmile Rodie by Turning your Bluetooth ON',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//             ),
//             SizedBox(
//               height: 60,
//             ),
//             Container(
//               child: ElevatedButton(
//                 onPressed: () async {
//                   if (_bluetoothState == BluetoothState.STATE_ON) {
//                     _startDiscovery();
//                   } else {
//                     await FBPFlutterBluePlus.turnOn();
//                     _startDiscovery();
//                   }
//                 },
//                 child: Text('Connect to RODIE'),
//               ),
//             ),
//             SizedBox(
//               height: 60,
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   'BT Status :',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(
//                   width: 10,
//                 ),
//                 Text(
//                   '$_bluetoothState',
//                   style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black45),
//                 ),
//               ],
//             ),
//             SizedBox(
//               height: 60,
//             ),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: _devicesList.length,
//                 itemBuilder: (context, index) {
//                   BluetoothDevice device = _devicesList[index];
//                   return ListTile(
//                     title: Text(device.name ?? 'Unknown Device'),
//                     subtitle: Text(device.address),
//                     onTap: () {
//                       print('Tapped on device: ${device.name}');
//                       if (_connection != null) {
//                         _connection!.dispose();
//                         _connection = null;
//                       }
//                       _connectToDevice(device);
//                       print(_connection);
//                     },
//                   );
//                 },
//               ),
//             ),
//             ElevatedButton(
//               onPressed: _connection != null
//                   ? () => _sendMessage("Hello, Bluetooth!")
//                   : null,
//               child: Text('Send Message'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     if (_connection != null) {
//       _connection!.dispose();
//       _connection = null;
//     }
//     super.dispose();
//   }
// }
