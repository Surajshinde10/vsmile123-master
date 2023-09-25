import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:http/http.dart' as http;
import 'package:vsmile/constant/const.dart';
import 'dart:convert';

import 'dart:math' show cos, sqrt, asin;

import '../bluetooth/bluetooth_main_page.dart';


class MapView extends StatefulWidget {
  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  CameraPosition _initialLocation = CameraPosition(target: LatLng(0.0, 0.0));
  late GoogleMapController mapController;

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
    return Container(
      width: width * 0.8,
      child: TextField(
        onChanged: (value) {
          locationCallback(value);
        },
        controller: controller,
        focusNode: focusNode,
        decoration: new InputDecoration(
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.grey.shade400,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.blue.shade300,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.all(15),
          hintText: hint,
        ),
      ),
    );
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
              setState(() {
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
        icon: BitmapDescriptor.defaultMarker,
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

    PolylineId id = PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 3,
    );
    polylines[id] = polyline;
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return Container(
      height: height,
      width: width,
      child: Scaffold(
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
            )
          ),
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
        body: SingleChildScrollView(
          child: Stack(
            children: <Widget>[
              // Map View
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 285),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        20.0), // Adjust the border radius as needed
                    child: Container(
                      height: height * 0.50,
                      width: MediaQuery.of(context).size.width / 1.1,
                      child: GoogleMap(
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
                    ),
                  ),
                ),
              ),

              // Show zoom buttons

              // Show the place input fields & button for
              // showing the route
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: KCard1,
                        borderRadius: BorderRadius.all(
                          Radius.circular(20.0),
                        ),
                      ),
                      width: width * 0.9,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              'Choose Nearby Fuel Stations',
                              style: TextStyle(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.w600,
                                  color: kTitleTextColor),
                            ),
                            SizedBox(height: 20),
                            _textField(
                                label: 'Start',
                                hint: 'Choose starting point',
                                prefixIcon: Icon(Icons.looks_one),
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.my_location),
                                  onPressed: () {
                                    startAddressController.text =
                                        _currentAddress;
                                    _startAddress = _currentAddress;
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
                            SizedBox(height: 10),
                            _textField(
                              label: 'Destination',
                              hint: 'Choose destination',
                              prefixIcon: Icon(Icons.looks_two),
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
                            SizedBox(height: 10),
                            Visibility(
                              visible: _destinationAddress.isNotEmpty && _placeDistance != null,
                              child: Text(
                                'DISTANCE: $_placeDistance km',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width / 3,
                                  height:
                                      MediaQuery.of(context).size.height / 20,
                                  child:
                                  ElevatedButton(
                                    onPressed: (_startAddress.isNotEmpty &&
                                            _destinationAddress.isNotEmpty)
                                        ? () async {
                                            startAddressFocusNode.unfocus();
                                            desrinationAddressFocusNode
                                                .unfocus();
                                            setState(() {
                                              if (markers.isNotEmpty) markers.clear();
                                              if (polylines.isNotEmpty) polylines.clear();
                                              if (polylineCoordinates.isNotEmpty) polylineCoordinates.clear();
                                              _placeDistance = null;
                                            });

                                            if (await _calculateDistance()) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Distance Calculated Successfully'),
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Error Calculating Distance'),
                                                ),
                                              );
                                            }
                                          }
                                        : () {
                                            // Destination field is empty, show a message
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Destination field is empty!'),
                                              ),
                                            );
                                          },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Route'.toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          fontSize: 16.0,
                                        ),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      // primary: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width / 3,
                                  height:
                                      MediaQuery.of(context).size.height / 20,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(
                                        20.0), // Adjust the border radius as needed
                                  ),
                                  child: InkWell(
                                    onTap: () async {
                                      if (_destinationAddress.isNotEmpty) {
                                        // Convert the destination address to LatLng
                                        final destination =
                                            await _getLatLngFromAddress(
                                                _currentAddress);

                                        if (destination != null) {
                                          // Call the method to fetch petrol pumps and gas stations
                                          final petrolPumpsMarkers =
                                              await _fetchPetrolPumpsAndGasStations(
                                                  destination);

                                          // Update the markers on the map
                                          setState(() {
                                            markers.clear();
                                            markers.addAll(petrolPumpsMarkers);
                                          });
                                        }
                                      } else {
                                        // Destination field is empty, show a snackbar message
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Destination field is empty!'),
                                          ),
                                        );
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        Center(
                                          child: Text(
                                            '          Nearby \n     Fuel stations',
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontSize:
                                                  14, // Adjust the font size as needed
                                              fontWeight: FontWeight
                                                  .bold, // Adjust the font weight as needed
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                            width:
                                                10), // Adjust the spacing between text and button
                                        // Icon(Icons.search, color: Colors.white), // You can customize the icon as needed
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 10.0, top: 480, right: 30),
                    child: Column(
                      children: <Widget>[
                        ClipOval(
                          child: Material(
                            color: Colors.blue.shade100, // button color
                            child: InkWell(
                              splashColor: Colors.blue, // inkwell color
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: Icon(Icons.add),
                              ),
                              onTap: () {
                                mapController.animateCamera(
                                  CameraUpdate.zoomIn(),
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        ClipOval(
                          child: Material(
                            color: Colors.blue.shade100, // button color
                            child: InkWell(
                              splashColor: Colors.blue, // inkwell color
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: Icon(Icons.remove),
                              ),
                              onTap: () {
                                mapController.animateCamera(
                                  CameraUpdate.zoomOut(),
                                );
                              },
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 720),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BluetoothApp()),
                      );
                    },
                    child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.red,
                        ),
                        height: MediaQuery.of(context).size.height / 18,
                        width: MediaQuery.of(context).size.width / 1.2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bluetooth,
                                color: Colors.white60, size: 25),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              "Connect Your device to vehicle ",
                              style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        )),
                  ),
                ),
              ),
              // Show current location button
              SafeArea(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: 30.0,
                      top: 300.0,
                    ),
                    child: ClipOval(
                      child: Material(
                        color: Colors.orange, // button color
                        child: InkWell(
                          splashColor: Colors.orange, // inkwell color
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: Icon(Icons.my_location),
                          ),
                          onTap: () {
                            mapController.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: LatLng(
                                    _currentPosition.latitude,
                                    _currentPosition.longitude,
                                  ),
                                  zoom: 18.0,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
