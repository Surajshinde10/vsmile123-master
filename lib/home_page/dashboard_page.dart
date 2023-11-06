import 'dart:io';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as FBS;

import 'package:http/http.dart' as http;
import 'package:progress_dialog_fork/progress_dialog_fork.dart';
import 'package:vsmile/allWidgets/searchScreen.dart';
import 'package:vsmile/constant/const.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

import 'dart:math' show cos, sqrt, asin;

import '../bluetooth/bluetooth_main_page.dart';

class MapView extends StatefulWidget {
  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late ProgressDialog pd;
  FBS.BluetoothState _bluetoothState = FBS.BluetoothState.UNKNOWN;
  FBS.FlutterBluetoothSerial _bluetooth = FBS.FlutterBluetoothSerial.instance;
  List<BluetoothDevice> _devicesList = [];
  FBS.BluetoothConnection? _connection;
  bool isconnected = false;

  CameraPosition _initialLocation = CameraPosition(target: LatLng(0.0, 0.0));
  late GoogleMapController mapController;
  PolylineId _polylineId = PolylineId('poly');

  late Position _currentPosition;
  String _currentAddress = '';

  final startAddressController = TextEditingController();
  final destinationAddressController = TextEditingController();

  final startAddressFocusNode = FocusNode();
  final desrinationAddressFocusNode = FocusNode();

  String _startAddress = '';
  String _destinationAddress = '';
  String? _placeDistance;

  Set<Marker> markers = {};

  late PolylinePoints polylinePoints;
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late List<Marker> selectedPetrolPumpMarker;

  Widget _textField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required double width,
    required Icon prefixIcon,
    Widget? suffixIcon,
    required Function(String) locationCallback,
  }) {
    return InkWell(
      onTap: () async {
        var res = await Navigator.push(
            context, MaterialPageRoute(builder: (context) => SearchScreen()));

        if (res == "obtainDirection") {
          // await  getPlaceDirection();
        }
      },
      child: Container(
        width: width * 0.9,
        child: TextField(
          onChanged: (value) {
            locationCallback(value);
          },
          controller: controller,
          focusNode: focusNode,
          decoration: new InputDecoration(
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(0),
              ),
              borderSide: BorderSide(
                color: Colors.grey.shade400,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(0),
              ),
              borderSide: BorderSide(
                color: Colors.blue.shade300,
                width: 0,
              ),
            ),
            contentPadding: EdgeInsets.all(15),
            hintText: hint,
          ),
        ),
      ),
    );
  }

  void _clearRoute() {
    setState(() {
      // _placeDistance = null; // Clear distance
      polylineCoordinates.clear();
      polylines.clear(); // Clear existing polylines
      // startAddressController.text = ''; // Clear start address text field
      // destinationAddressController.text = ''; // Clear destination address text field
      // _startAddress = ''; // Clear start address variable
      _destinationAddress = ''; // Clear destination address variable
    });
  }

  // Method for retrieving the current location
  _getCurrentLocation() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      setState(() {
        _currentPosition = position;
        print('CURRENT POS: $_currentPosition');
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 18.0,
            ),
          ),
        );
      });
      await _getAddress();
    }).catchError((e) {
      print(e);
    });
  }

  // Method for retrieving the address
  _getAddress() async {
    try {
      List<Placemark> p = await placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];

      setState(() {
        _currentAddress =
            "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
        startAddressController.text = _currentAddress;
        _startAddress = _currentAddress;
      });
    } catch (e) {
      print(e);
    }
  }

  // Call this method with your current location's coordinates (LatLng)
  Future<List<Marker>> _fetchPetrolPumpsAndGasStations(
      LatLng currentLocation) async {
    final apiKey =
        "AIzaSyB33yWL3b5E00suRjPn5nMuPr3bZ_iHnqE"; // Replace with your Google Maps API Key
    final radius = 10000; // 10 kilometers in meters

    final location = "${currentLocation.latitude},${currentLocation.longitude}";
    final types =
        "gas_station|petrol_station"; // Include both gas_station and petrol_station

    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
      "?location=$location"
      "&radius=$radius"
      "&types=$types"
      "&key=$apiKey",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final results = data['results'];
        List<Marker> markers = [];

        for (var result in results) {
          String name = result['name'];
          double latitude = result['geometry']['location']['lat'];
          double longitude = result['geometry']['location']['lng'];

          // Create a Marker for the petrol pump or gas station
          Marker marker = Marker(
            markerId: MarkerId(name),
            position: LatLng(latitude, longitude),
            infoWindow: InfoWindow(
              title: name,
            ),
            onTap: () {
              // Calculate distance and create polyline when marker is tapped
              _calculateDistanceAndShowPolyline(LatLng(latitude, longitude));
              setState(() {
                polylineCoordinates.clear();
                _createPolylines(
                    _startAddress as double,
                    _destinationAddress as double,
                    currentLocation as double,
                    currentLocation as double);
                selectedPetrolPumpMarker = markers;
              });
            },
          );

          markers.add(marker);
        }

        return markers;
      } else {
        // Handle API error here.
        print("API Error: ${data['status']}");
        throw Exception("API Error: ${data['status']}");
      }
    } else {
      // Handle HTTP error here.
      print("HTTP Error: ${response.statusCode}");
      throw Exception("HTTP Error: ${response.statusCode}");
    }
  }

  Future<LatLng?> _getLatLngFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final LatLng latLng =
            LatLng(locations.first.latitude, locations.first.longitude);
        return latLng;
      }
    } catch (e) {
      print("Error converting address to LatLng: $e");
    }
    return null;
  }

  void _calculateDistanceAndShowSnackBar(
    double destinationLatitude,
    double destinationLongitude,
  ) async {
    double distance = await _calculateDistanceFromCurrentLocation(
      destinationLatitude,
      destinationLongitude,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Distance from current location: ${distance.toStringAsFixed(2)} km',
        ),
      ),
    );
  }

  void _calculateDistanceAndShowPolyline(LatLng destinationLocation) async {
    // Clear existing polylines
    polylines.clear();

    double distance = await _calculateDistanceFromCurrentLocation(
      destinationLocation.latitude,
      destinationLocation.longitude,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Distance from current location: ${distance.toStringAsFixed(2)} km',
        ),
      ),
    );

    // Create a new polyline to the destination
    await _createPolylines(
      _currentPosition.latitude,
      _currentPosition.longitude,
      destinationLocation.latitude,
      destinationLocation.longitude,
    );

    // Update the UI to show the new polyline
    setState(() {
      _placeDistance = distance.toStringAsFixed(2);
    });
  }

  // Method for calculating the distance between two places
  Future<bool> _calculateDistance() async {
    try {
      polylineCoordinates = []; // Initialize the list

      // Retrieving placemarks from addresses
      List<Location> startPlacemark = await locationFromAddress(_startAddress);
      List<Location> destinationPlacemark =
          await locationFromAddress(_destinationAddress);

      // Use the retrieved coordinates of the current position,
      // instead of the address if the start position is user's
      // current position, as it results in better accuracy.
      double startLatitude = _startAddress == _currentAddress
          ? _currentPosition.latitude
          : startPlacemark[0].latitude;

      double startLongitude = _startAddress == _currentAddress
          ? _currentPosition.longitude
          : startPlacemark[0].longitude;

      double destinationLatitude = destinationPlacemark[0].latitude;
      double destinationLongitude = destinationPlacemark[0].longitude;

      String startCoordinatesString = '($startLatitude, $startLongitude)';
      String destinationCoordinatesString =
          '($destinationLatitude, $destinationLongitude)';

      // Start Location Marker
      Marker startMarker = Marker(
        markerId: MarkerId(startCoordinatesString),
        position: LatLng(startLatitude, startLongitude),
        infoWindow: InfoWindow(
          title: 'Start $startCoordinatesString',
          snippet: _startAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );

      Marker destinationMarker = Marker(
        markerId: MarkerId(destinationCoordinatesString),
        position: LatLng(destinationLatitude, destinationLongitude),
        infoWindow: InfoWindow(
          title: 'Destination $destinationCoordinatesString',
          snippet: _destinationAddress,
        ),
        icon: BitmapDescriptor.defaultMarker,
        onTap: () async {
          _clearRoute();
          double distance = await _calculateDistanceFromCurrentLocation(
            destinationLatitude,
            destinationLongitude,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Distance from current location: ${distance.toStringAsFixed(2)} km'),
            ),
          );
        },
      );

      markers.add(startMarker);
      markers.add(destinationMarker);

      print(
        'START COORDINATES: ($startLatitude, $startLongitude)',
      );
      print(
        'DESTINATION COORDINATES: ($destinationLatitude, $destinationLongitude)',
      );

      // Calculating to check that the position relative
      // to the frame, and pan & zoom the camera accordingly.
      double miny = (startLatitude <= destinationLatitude)
          ? startLatitude
          : destinationLatitude;
      double minx = (startLongitude <= destinationLongitude)
          ? startLongitude
          : destinationLongitude;
      double maxy = (startLatitude <= destinationLatitude)
          ? destinationLatitude
          : startLatitude;
      double maxx = (startLongitude <= destinationLongitude)
          ? destinationLongitude
          : startLongitude;

      double southWestLatitude = miny;
      double southWestLongitude = minx;

      double northEastLatitude = maxy;
      double northEastLongitude = maxx;

      // Accommodate the two locations within the
      // camera view of the map
      mapController.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            northeast: LatLng(northEastLatitude, northEastLongitude),
            southwest: LatLng(southWestLatitude, southWestLongitude),
          ),
          100.0,
        ),
      );

      await _createPolylines(startLatitude, startLongitude, destinationLatitude,
          destinationLongitude);

      double totalDistance = 0.0;

      // Calculating the total distance by adding the distance
      // between small segments
      for (int i = 0; i < polylineCoordinates.length - 1; i++) {
        totalDistance += _coordinateDistance(
          polylineCoordinates[i].latitude,
          polylineCoordinates[i].longitude,
          polylineCoordinates[i + 1].latitude,
          polylineCoordinates[i + 1].longitude,
        );
      }

      setState(() {
        _placeDistance = totalDistance.toStringAsFixed(2);
        print('DISTANCE: $_placeDistance km');
      });

      return true;
    } catch (e) {
      print(e);
    }
    return false;
  }

  Future<double> _calculateDistanceFromCurrentLocation(
      double destinationLatitude, double destinationLongitude) async {
    double startLatitude = _currentPosition.latitude;
    double startLongitude = _currentPosition.longitude;

    double distance = _coordinateDistance(
      startLatitude,
      startLongitude,
      destinationLatitude,
      destinationLongitude,
    );

    return distance;
  }

  // Formula for calculating distance between two coordinates
  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  // Create the polylines for showing the route between two places
  _createPolylines(
    double startLatitude,
    double startLongitude,
    double destinationLatitude,
    double destinationLongitude,
  ) async {
    polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      "AIzaSyB33yWL3b5E00suRjPn5nMuPr3bZ_iHnqE", // Google Maps API Key
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
      travelMode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    PolylineId id = _polylineId;
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
    );
    polylines[id] = polyline;
  }

  Future<void> _tryBluetoothConnectionAgain() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Failed!!!'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Connection with Device Failed try again!!!'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Try Again'),
              onPressed: () {
                _requestBluetoothPermissions();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showBluetoothDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alert!!!'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Please provide bluetooth permission to access the app.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Allow'),
              onPressed: () {
                _requestBluetoothPermissions();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _turnOnBluetooth() {
    _bluetooth.isEnabled.then((state) async {
      if (!state!) {
        await _bluetooth.requestEnable().then((value) => {
              if (!value!)
                {_turnOnBluetooth()}
              else
                {
                  _startDiscovery(),
                  // _getCurrentLocation()
                }
            });
      } else {
        _startDiscovery();
        // _getCurrentLocation();
      }
    });

    // ...
  }

  Future<void> _requestBluetoothPermissions() async {
    print('request permission for bluetooth');
    Map<Permission, PermissionStatus> status = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();
    print('bluetooth permission granted or not |' +
        (status[Permission.bluetooth] == PermissionStatus.granted).toString());
    if (status[Permission.bluetooth] == PermissionStatus.granted) {
      // Bluetooth permission granted, you can now initialize Bluetooth
      _turnOnBluetooth();
    } else {
      _showBluetoothDialog();
      // Handle denied or restricted permissions here
      // You can show a message to the user or take appropriate action
      print('Bluetooth permission denied.');
    }
  }

  @override
  void initState() {
    super.initState();
    // _showBluetoothDialog();
    _requestBluetoothPermissions();
    // _checkBleState(context);

    // _bluetooth.state.then((state) {
    //   setState(() {
    //     _bluetoothState = state;
    //   });
    // });

    // Listen for Bluetooth state changes
    _bluetooth.onStateChanged().listen((FBS.BluetoothState state) {
      setState(() {
        _bluetoothState = state;
      });
    });
  }

  void _clearPolyline() {
    setState(() {
      polylines.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    pd = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false, showLogs: false);

    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: kScaffoldBackground,
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: KCard1,
        leading: Padding(
            padding: const EdgeInsets.only(
              left: 12,
            ),
            child: ClipRect(
              child: Container(
                color: KCard1, // Set your desired background color here
                child: CircleAvatar(
                  radius: 13,
                  backgroundImage: AssetImage('assets/vsmile_logo.png'),
                ),
              ),
            )),
        title: Center(
            child: Text(
          "vSmile",
          style: TextStyle(fontWeight: FontWeight.w600),
        )),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: InkWell(
                onTap: () {},
                child: Icon(
                  Icons.notification_add_outlined,
                  color: Colors.black,
                  size: 25,
                )),
          ), // You can customize the icon as needed
        ],
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            markers: Set<Marker>.from(markers),
            initialCameraPosition: _initialLocation,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: false,
            polylines: Set<Polyline>.of(polylines.values),
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
          ),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                SizedBox(
                  height: 20,
                ),
                _textField(
                    label: 'Start',
                    hint: 'Choose starting point',
                    prefixIcon: Icon(Icons.looks_one),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.my_location),
                      onPressed: () {
                        _getCurrentLocation();
                        // startAddressController.text = _currentAddress;
                        // _startAddress = _currentAddress;
                      },
                    ),
                    controller: startAddressController,
                    focusNode: startAddressFocusNode,
                    width: width,
                    locationCallback: (String value) {
                      setState(() {
                        _startAddress = value;
                      });
                    }),
                _textField(
                  label: 'Destination',
                  hint: 'Choose destination',
                  prefixIcon: Icon(Icons.looks_two),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.arrow_forward),
                    onPressed: (_startAddress.isNotEmpty &&
                            _destinationAddress.isNotEmpty)
                        ? () async {
                            startAddressFocusNode.unfocus();
                            desrinationAddressFocusNode.unfocus();
                            setState(() {
                              if (markers.isNotEmpty) markers.clear();
                              if (polylines.isNotEmpty) polylines.clear();
                              if (polylineCoordinates.isNotEmpty)
                                polylineCoordinates.clear();
                              _placeDistance = null;
                            });

                            if (await _calculateDistance()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Distance Calculated Successfully'),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error Calculating Distance'),
                                ),
                              );
                            }
                          }
                        : () {
                            // Destination field is empty, show a message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Destination field is empty!'),
                              ),
                            );
                          },
                  ),
                  controller: destinationAddressController,
                  focusNode: desrinationAddressFocusNode,
                  width: width,
                  locationCallback: (String value) {
                    setState(() {
                      _destinationAddress = value;
                    });

                    // Check if the value is not empty and fetch petrol pumps and gas stations.
                    if (value.isNotEmpty) {
                      final destination = // Convert value to LatLng (use geocoding or other method);
                          _fetchPetrolPumpsAndGasStations;
                    }
                  },
                ),
                // SizedBox(height: 10),
                // Visibility(
                //   visible: _destinationAddress.isNotEmpty &&
                //       _placeDistance != null,
                //   child: Text(
                //     'DISTANCE: $_placeDistance km',
                //     style: TextStyle(
                //       fontSize: 16,
                //       fontWeight: FontWeight.bold,
                //     ),
                //   ),
                // ),
                // SizedBox(height: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    if (_connection != null) {
      _connection!.output.add(Uint8List.fromList(utf8.encode(text)));
      _connection!.output.allSent.then((_) {
        print('Sent: $text');
      });
    }
  }

  void _startDiscovery() {
    pd.update(
      message: "Searching for Rodie Device...",
    );
    pd.show();
    Future.delayed(Duration(seconds: 25), () async {
      // After 3 seconds, navigate to the main screen
      if (await (_bluetooth != null?.isDiscovering)) {
        _bluetooth.cancelDiscovery();
        if (bluetoothConnection != null
            ? bluetoothConnection!.isConnected
            : false) {
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text("Device Not found, Try again!!!"),
          ));
          _tryBluetoothConnectionAgain();
        }

        pd.hide();
      }
    });
    _bluetooth.startDiscovery().listen((deviceResult) {
      // Extract the BluetoothDevice from the BluetoothDiscoveryResult
      deviceResult.device;
      if (deviceResult.device.name == "Rodie") {
        pd.update(message: "Device Found!!!, Connecting...");
        _connectToDevice(deviceResult.device);
        _bluetooth.cancelDiscovery();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Device Connected!!!"),
        ));
        pd.hide();
        _getCurrentLocation();
        return;
      }

      // setState(() {
      //   _devicesList.add(device);
      // });
    });
  }

  FBS.BluetoothConnection? bluetoothConnection = null;
  void _connectToDevice(FBS.BluetoothDevice device) async {
    try {
      // Close the previous connection if it exists
      if (_connection != null) {
        _connection!.dispose();
        _connection = null;
      }

      // Pair the device
      if (!device.isBonded) {
        final bool? isPaired = await FBS.FlutterBluetoothSerial.instance
            .bondDeviceAtAddress(device.address);
        if (!isPaired!) {
          print('Failed to pair with the device.');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text(
                "Connection with Device Failed!!!, Please contact the support!!!"),
          ));
          pd.hide();
          _tryBluetoothConnectionAgain();
          return;
        }
      }

      // Establish a Bluetooth connection
      bluetoothConnection =
          await FBS.BluetoothConnection.toAddress(device.address);

      bluetoothConnection?.input?.listen((Uint8List data) {
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

  void _checkBleState(BuildContext context) {
    // if (FlutterBluePlus.adapterState == BluetoothAdapterState.off)
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(builder: (context) => BluetoothApp ()),
    //   );
  }
}
