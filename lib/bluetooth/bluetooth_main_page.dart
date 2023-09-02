import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BluetoothApp(),
    );
  }
}

class BluetoothApp extends StatefulWidget {
  @override
  _BluetoothAppState createState() => _BluetoothAppState();
}

class _BluetoothAppState extends State<BluetoothApp> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  List<BluetoothDevice> _devicesList = [];
  BluetoothConnection? _connection;
  bool isconnected = false;

  @override
  void initState() {
    super.initState();
    _requestBluetoothPermissions();

    // Get current Bluetooth state
    _bluetooth.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    // Listen for Bluetooth state changes
    _bluetooth.onStateChanged().listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
      });
    });
  }

  void _startDiscovery() {
    _bluetooth.startDiscovery().listen((deviceResult) {
      // Extract the BluetoothDevice from the BluetoothDiscoveryResult
      BluetoothDevice device = deviceResult.device;

      setState(() {
        _devicesList.add(device);
      });
    });
  }

  Future<void> _requestBluetoothPermissions() async {
    Map<Permission, PermissionStatus> status = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();

    if (status[Permission.bluetooth] == PermissionStatus.granted) {
      // Bluetooth permission granted, you can now initialize Bluetooth
      _initBluetooth();
    } else {
      // Handle denied or restricted permissions here
      // You can show a message to the user or take appropriate action
      print('Bluetooth permission denied.');
    }
  }

  void _initBluetooth() {
    // Check Bluetooth state and initialize as before
    _bluetooth.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });

      // ...
    });

    // ...
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      // Close the previous connection if it exists
      if (_connection != null) {
        _connection!.dispose();
        _connection = null;
      }

      // Pair the device
      if (!device.isBonded) {
        final bool? isPaired = await FlutterBluetoothSerial.instance
            .bondDeviceAtAddress(device.address);
        if (!isPaired!) {
          print('Failed to pair with the device.');
          return;
        }
      }

      // Establish a Bluetooth connection
      BluetoothConnection bluetoothConnection =
      await BluetoothConnection.toAddress(device.address);

      bluetoothConnection.input?.listen((Uint8List data) {
        // Handle received data
        String message = utf8.decode(data);
        print('Received: $message');
      });

      setState(() {
        debugPrint('Connecting successful');
        _connection = bluetoothConnection;
      });
    } catch (error) {
      print('Error connecting to device: $error');
      // Handle the error and possibly notify the user
    }
  }


  void _sendMessage(String text) {
    if (_connection != null) {
      _connection!.output.add(Uint8List.fromList(utf8.encode(text)));
      _connection!.output.allSent.then((_) {
        print('Sent: $text');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Example'),
      ),
      body: Column(
        children: <Widget>[
          Text('Bluetooth State: $_bluetoothState'),
          ElevatedButton(
            onPressed: () {
              if (_bluetoothState == BluetoothState.STATE_ON) {
                _startDiscovery();
              } else {
                print('Turn on your Bluetooth device');
              }
            },
            child: Text('Discover Devices'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devicesList.length,
              itemBuilder: (context, index) {
                BluetoothDevice device = _devicesList[index];
                return ListTile(
                  title: Text(device.name ?? 'Unknown Device'),
                  subtitle: Text(device.address),
                  onTap: () {
                    print('Tapped on device: ${device.name}');
                    if (_connection != null) {
                      _connection!.dispose();
                      _connection = null;
                    }
                    _connectToDevice(device);
                    print(_connection);
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _connection != null
                ? () => _sendMessage("Hello, Bluetooth!")
                : null,
            child: Text('Send Message'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_connection != null) {
      _connection!.dispose();
      _connection = null;
    }
    super.dispose();
  }
}
