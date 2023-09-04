import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:vsmile/allWidgets/Divider.dart';
import 'package:vsmile/allWidgets/searchScreen.dart';
import 'package:vsmile/assistance/assistantMethod.dart';
import 'package:vsmile/dataHandler/appData.dart';

import '../bluetooth/bluetooth_main_page.dart';
import '../constant/const.dart';
import 'placesFetch.dart';

class MainScreen extends StatefulWidget {
  static const String idScreen = "mainScreen";
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

Future<Position> getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if location services are enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are disabled, handle accordingly
    return Future.error('Location services are disabled.');
  }

  // Check location permission status
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    // Request location permission
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Location permission denied, handle accordingly
      return Future.error('Location permission denied.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Location permissions are permanently denied, handle accordingly
    return Future.error('Location permissions are permanently denied.');
  }

  // Get the current position
  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

Future<void> fetchPlaces() async {
  final mapkey = 'AIzaSyDGiDTfpX3lDemEOcxvkPALFEK9Z-RnjPs';
  final placesService = PlacesService(mapkey);

  final currentLocation =
      await getCurrentLocation();

  final fetchedPlaces = await placesService.getPlaces(
      currentLocation.latitude, currentLocation.longitude);

  // setState(() {
  //   places = fetchedPlaces;
  // });
  @override
  void initState() {
    fetchPlaces();
  }
}

Marker _carMarker = Marker(
  markerId: MarkerId('car'),
  position: LatLng(18.429890  ,73.122772),
  icon: BitmapDescriptor.defaultMarker,
);

final Completer<GoogleMapController> _controllerGoogleMap =
    Completer<GoogleMapController>();

late GoogleMapController newGoogleMapController;

GlobalKey<ScaffoldState> scaffoldkey = new GlobalKey<ScaffoldState>();

List<LatLng> pLineCoordinates = [];

Set<Polyline> polylineSet = {};

late Position currentPosition;
var geoLocator = Geolocator();

double bottomPaddingOfMap = 0;

Set<Marker> markersSet = {};
Set<Circle> circlesSet = {};
Future<Position> _determinePosition(BuildContext context) async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled, handle this case appropriately
    // (e.g., show a dialog to prompt the user to enable location services).
    throw Exception('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, handle this case appropriately
      // (e.g., show a dialog to inform the user about the importance
      // of location permissions and prompt them to grant the permissions).
      throw Exception('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle this case appropriately
    // (e.g., show a dialog to inform the user about the importance
    // of location permissions and guide them to app settings to grant
    // the necessary permissions manually).
    throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted, and we can
  // continue accessing the position of the device.
  Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
  String address =
      await AssistantMethods.searchCoordinateAddress(position, context);

  print("This is my address: $address");

  return position;
}

class _MainScreenState extends State<MainScreen> {
  List<Place> places = [];
  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(18.429890, 73.122772),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      key: scaffoldkey,
      appBar: AppBar(
        backgroundColor: KCard1,
        title: GestureDetector(
          onTap: () async {
            var res = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SearchScreen( )));

            if (res == "obtainDirection") {
              await  getPlaceDirection();
            }
          },
          child: Container(
            height: 38,
            width: MediaQuery.of(context).size.width / 1.4,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 2.0,
                  offset: Offset(0.7, 0.7),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  color: Colors.grey,
                ),
                SizedBox(
                  width: 8.0,
                ),
                Text(
                  "Search for gas Station",
                  style: TextStyle(color: Colors.grey,fontSize: 18),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                // Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //         builder: (context) => MapScreen()));
              },
              child: CircleAvatar(
                backgroundColor: KCard1,
                child: Icon(
                  Icons.notification_add_outlined,
                  color: Colors.black,size: 25,
                ),
                radius: 20.0,
              ),
            ),
          ),
        ],
      ),
      drawer: Container(
        // color: Colors.white,
        width: 255.0,
        child: Drawer(

          child: ListView(
            children: [
              Container(
                height: 165.0,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      Image.asset(
                        "images/user_icon.png",
                        height: 65.0,
                        width: 65.0,
                        color: Colors.black54,
                      ),
                      SizedBox(
                        width: 16.0,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Profile Name",
                            style: TextStyle(
                                fontSize: 16.0, fontFamily: "Brand-Bold"),
                          ),
                          SizedBox(
                            height: 6.0,
                          ),
                          Text("Visit Profile"),
                        ],
                      )
                    ],
                  ),
                ),
              ),

              DividerWidget(),
              SizedBox(
                height: 12.0,
              ),
              //drawer body controller

              ListTile(
                leading: Icon(Icons.history),
                title: Text(
                  "History",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text(
                  "Visit Profile",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text(
                  "About",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),
            ],
          ),
        ),
      ),
      body:
          Stack(
            children: [

            ],
          )
      SingleChildScrollView(
        child: Column(
            children: [
              SizedBox(height: 8,),
              Column(
                children: [
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color:  KCard1,
                      ),

                      height: MediaQuery.of(context).size.height/18,
                      width: MediaQuery.of(context).size.width/1.2,
                      child:
                      Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MapScreen()));
                          },
                          child: CircleAvatar(
                            backgroundColor: KCard1,
                            child: Icon(
                              Icons.local_gas_station_outlined,
                              color: Colors.black,
                            ),
                            radius: 40.0,
                          ),
                        ),
                        Text("List of nearby gas Station",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),)
                      ],
                      )

                    ),
                  ),
                  SizedBox(height: 5,),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.red,
                    ),
                    height: MediaQuery.of(context).size.height/1.4,
                    width: double.infinity,
                    child: GoogleMap(
                      padding: EdgeInsets.only(bottom: bottomPaddingOfMap, top: 400),
                      mapType: MapType.normal,
                      myLocationButtonEnabled: true,
                      initialCameraPosition: _kGooglePlex,
                      myLocationEnabled: true,
                      zoomGesturesEnabled: true,
                      zoomControlsEnabled: false,
                      // markers: markersSet,
                      markers: Set.of([_carMarker]),
                      circles: circlesSet,
                      polylines: polylineSet,
                      onMapCreated: (GoogleMapController controller) {
                        _controllerGoogleMap.complete(controller);
                        newGoogleMapController = controller;
                        fetchPlaces();

                        setState(() {
                          bottomPaddingOfMap = 300.0;
                        });
                        _determinePosition(context);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),

              InkWell(
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
                  child:Row(
                    mainAxisAlignment: MainAxisAlignment.center,
    children: [
        Icon(Icons.bluetooth, color: Colors.white60, size: 25),
SizedBox(width: 10,),
        Text("Connect Your device to vehicle ",style: TextStyle(color: Colors.white60,fontSize: 14,fontWeight: FontWeight.bold),),
    ],
    )

                ),
              )







            ],
        ),
      ),

    );
  }


  Future<void> getPlaceDirection() async {
    var initialPos = Provider.of<AppData>(context as BuildContext, listen: false,).pickUpLocation;

    var finalPos = Provider.of<AppData>(context as BuildContext, listen: false,).dropOffLocation;

    var pickUpLatlng = LatLng(initialPos.latitude, initialPos.longitude);

    var dropOffLatlng = LatLng(finalPos.latitude, finalPos.longitude);

    showDialog(
        context: context as BuildContext,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: <Widget>[
                CircularProgressIndicator(),
                SizedBox(width: 15),
                Text(
                  "Setting Dropoff, Please Wait ...",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );


          //   AlertDialog(
          //   content: Flex(
          //     direction: Axis.horizontal,
          //     children: <Widget>[
          //       CircularProgressIndicator(),
          //       Padding(
          //         padding: EdgeInsets.only(left: 15),
          //       ),
          //       Flexible(
          //           flex: 8,
          //           child: Text(
          //             "Setting Dropoff , Please Wait ...",
          //             style:
          //                 TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          //           )),
          //     ],
          //   ),
          // );
        });

    var details = await AssistantMethods.obtainPlaceDirectionDetails(
        pickUpLatlng, dropOffLatlng);

    Navigator.pop(context );

    print("This is EncodedPoints ::");
    print(details?.encodedPoints);

    PolylinePoints polylinePoints = PolylinePoints();

    List<PointLatLng> decodedPolyLinePointsResult =
        polylinePoints.decodePolyline(details!.encodedPoints);

    polylineSet.clear();

    if (decodedPolyLinePointsResult.isNotEmpty) {
      decodedPolyLinePointsResult.forEach((PointLatLng pointLatLng) {
        pLineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }
    polylineSet.clear();
    setState(() {


      Polyline polyline = Polyline(
        color: Colors.pink,
        polylineId: PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polylineSet.add(polyline);
    });

    LatLngBounds latLngBounds;
    if (pickUpLatlng.latitude > dropOffLatlng.latitude &&
        pickUpLatlng.longitude > dropOffLatlng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropOffLatlng, northeast: pickUpLatlng);
    } else if (pickUpLatlng.longitude > dropOffLatlng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickUpLatlng.latitude, dropOffLatlng.longitude),
          northeast: LatLng(dropOffLatlng.latitude, pickUpLatlng.longitude));
    } else if (pickUpLatlng.latitude > dropOffLatlng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropOffLatlng.latitude, pickUpLatlng.longitude),
          northeast: LatLng(pickUpLatlng.latitude, dropOffLatlng.longitude));
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLatlng, northeast: dropOffLatlng);
    }
    newGoogleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickUpLocMarker = Marker(
      markerId: MarkerId("pickUpId"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      infoWindow:
          InfoWindow(title: initialPos.placeName, snippet: "My Location"),
      position: pickUpLatlng,
    );

    Marker dropOffLocMarker = Marker(
      markerId: MarkerId("dropOffId"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow:
          InfoWindow(
              title: finalPos.placeName, snippet: "DropOff Location"),
      position: pickUpLatlng,
    );

    setState(() {
      markersSet.add(pickUpLocMarker);
      markersSet.add(dropOffLocMarker);
    });

    Circle pickUpLocCircle = Circle(
        circleId: CircleId("pickUpId"),
        fillColor: Colors.blueAccent,
        center: pickUpLatlng,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.blueAccent);

    Circle dropOffLocCircle = Circle(
        circleId: CircleId("dropOffId"),
        fillColor: Colors.deepPurple,
        center: dropOffLatlng,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.deepPurple);

    setState(() {
      circlesSet.add(pickUpLocCircle);
      circlesSet.add(dropOffLocCircle);
    });
  }
}
