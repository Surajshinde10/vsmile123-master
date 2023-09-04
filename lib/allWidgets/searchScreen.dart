  import 'dart:async';
  import 'dart:convert';
  import 'dart:math';
  import 'package:flutter/material.dart';
  import 'package:geolocator/geolocator.dart';
  import 'package:google_maps_flutter/google_maps_flutter.dart';
  import 'package:progress_loading_button/progress_loading_button.dart';
  import 'package:provider/provider.dart';
  import 'package:vsmile/allWidgets/confiMap.dart';
  import 'package:vsmile/assistance/requestAssistant.dart';
  import 'package:vsmile/dataHandler/appData.dart';
  import 'package:vsmile/models/address.dart';
  import 'package:vsmile/models/placePredictions.dart';
  import '../constant/const.dart';
import 'Divider.dart';
  
  class SearchScreen extends StatefulWidget {
    const SearchScreen({super.key});
  
    @override
    State<SearchScreen> createState() => _SearchScreenState();
  }
  
  class _SearchScreenState extends State<SearchScreen> {
    TextEditingController pickuptextEditingController = TextEditingController();
    TextEditingController dropOftextEditingController = TextEditingController();
    List<PlacePredictions> placePredictionList = [];
  
    Timer? _debounceTimer; // Timer for debounce
  
  
  
  
    final Map<String, List<PlacePredictions>> _cachedPredictions = {};
  
    @override
    Widget build(BuildContext context) {
      String placeAddress = Provider.of<AppData>(context).pickUpLocation.placeName ?? "";
      // String dropAddress = Provider.of<AppData>(context).dropOffLocation.placeName ?? "";
  
      pickuptextEditingController.text = placeAddress;
      // dropOftextEditingController.text = dropAddress;
  
  
  
      return Scaffold(
        backgroundColor: kScaffoldBackground,
        body: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height/4,
              decoration: BoxDecoration(
                color: KCard1,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    spreadRadius: 0.5,
                    offset: Offset(0.7, 0.7),
                  )
                ],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(38),
                  topRight: Radius.circular(38),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(left: 25.0, top: 20.0, right: 25.0, bottom: 20.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 20.0,
                    ),
                    Stack(

                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(Icons.arrow_back),
                        ),
                        Center(
                          child: Text(
                            "Set Destination Here",
                            style: TextStyle(fontSize: 18.0, fontFamily: "Brand-Bold",fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 16.0,
                    ),
                    Row(
                      children: [
                        Icon(Icons.home,color: Colors.black45,),
                        SizedBox(
                          width: 18.0,
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              // color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(3.0),
                              child: TextField(
                                controller: pickuptextEditingController,
                                decoration: InputDecoration(
                                  hintText: "Current Location",
                                  fillColor: kScaffoldBackground,
                                  filled: true,
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.only(left: 11.0, top: 8.0, bottom: 8.0),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on,color: Colors.black45,),
                        SizedBox(
                          width: 18.0,
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              // color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(3.0),
                              child: TextField(
                                onChanged: (val) {
                                  findPlace(val);
                                },
                                controller: dropOftextEditingController,
                                decoration: InputDecoration(
                                  hintText: "Search Your Desired Gas Station?",
                                  fillColor: kScaffoldBackground,
                                  filled: true,
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.only(left: 11.0, top: 8.0, bottom: 8.0),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 10.0,
            ),
            (placePredictionList.length > 0)
                ? Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child:
                ListView.separated(
                  padding: EdgeInsets.all(0.0),
                  itemBuilder: (context, index) {
                    return
                      PredictionTile(
                        key: Key(mapKey),
                        placePredictions: placePredictionList[index],
                        getPlaceAddressDetails: getPlaceAddressDetails,
                        sourceLocation: LatLng(
                          Provider.of<AppData>(context, listen: false).pickUpLocation.latitude,
                          Provider.of<AppData>(context, listen: false).pickUpLocation.longitude,
                        ),
                        destinationLocation: LatLng(
                          Provider.of<AppData>(context, listen: false).dropOffLocation.latitude,
                          Provider.of<AppData>(context, listen: false).dropOffLocation.longitude,
                        ),
                      );
  
  
                  },
                  separatorBuilder: (BuildContext context, int index) => DividerWidget(),
                  itemCount: placePredictionList.length,
                  shrinkWrap: true,
                  physics: ClampingScrollPhysics(),
                )
  
            )
                : Container(),
          ],
        ),
      );
    }
  
    Future<Position?> getCurrentLocation() async {
      try {
        final Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        return position;
      } catch (e) {
        print('Error getting location: $e');
        return null;
      }
    }
  
    Future<double> calculateDistanceBetweenLocations(
        double sourceLatitude,
        double sourceLongitude,
        double destinationLatitude,
        double destinationLongitude,
        ) async {
      print("Source Latitude: $sourceLatitude");
      print("Source Longitude: $sourceLongitude");
      print("Destination Latitude: $destinationLatitude");
      print("Destination Longitude: $destinationLongitude");
      try {
        final double distanceInMeters = await Geolocator.distanceBetween(
          sourceLatitude,
          sourceLongitude,
          destinationLatitude,
          destinationLongitude,
        );
        print("Distance in Meters: $distanceInMeters");
  
        // Convert distance from meters to kilometers
        final double distanceInKilometers = distanceInMeters / 1000.0;
        print("Distance in Kilometers: $distanceInKilometers");
  
        return distanceInKilometers;
  
      } catch (e) {
        print('Error calculating distance: $e');
        return 0.0;
      }
    }
  
    double calculateDistance(LatLng start, LatLng end) {
  
      const double earthRadius = 6371.0; // Radius of the Earth in kilometers
  
      // Convert coordinates to radians
      final double lat1 = start.latitude * (pi / 180.0);
      final double lon1 = start.longitude * (pi / 180.0);
      final double lat2 = end.latitude * (pi / 180.0);
      final double lon2 = end.longitude * (pi / 180.0);
  
      // Calculate the differences between the coordinates
      final double dLat = lat2 - lat1;
      final double dLon = lon2 - lon1;
  
      // Apply the Haversine formula
      final double a = sin(dLat / 2) * sin(dLat / 2) +
          cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
      final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
      final double distance = earthRadius * c;
  
      return distance; // Distance in kilometers, add "*1000" to get meters
    }
    void findPlace(String placeName) async {
      // Cancel the previous debounce timer
      if (_debounceTimer != null && _debounceTimer!.isActive) {
        _debounceTimer!.cancel();
      }
  
      // Set a new debounce timer
      _debounceTimer = Timer(Duration(milliseconds: 500), () async {
        if (placeName.length > 1) {
          // Check if predictions are cached
          if (_cachedPredictions.containsKey(placeName)) {
            setState(() {
              placePredictionList = _cachedPredictions[placeName]!;
            });
            return;
          }
  
          String autoCompleteUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=$mapKey&sessiontoken=1234567890&components=country:in&type=gas_station";
  
          var res = await RequestAssistant.getRequest(autoCompleteUrl);
  
          if (res == "failed") {
            return;
          }
  
          if (res["status"] == "OK") {
            var predictions = res["predictions"];
  
            var placelist = (predictions as List).map((e) {
              // Parse distance as double from JSON
              double distance = e.containsKey("distance") ? (e["distance"] as double) / 1000.0 : 0.0;
              // Pass the parsed distance to the constructor
              return PlacePredictions.fromJson(e)..distanceInKilometers = distance;
            }).toList();
  
            setState(() {
              placePredictionList = placelist;
            });
  
            // Cache the predictions
            _cachedPredictions[placeName] = placelist;
          }
        }
      });
    }
    // void findPlace(String placeName) async {
    //   if (placeName.length > 1) {
    //     String autoCompleteUrl =
    //         "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=$mapKey&sessiontoken=1234567890&components=country:in&type=gas_station";
    //
    //     var res = await RequestAssistant.getRequest(autoCompleteUrl);
    //
    //     if (res == "failed") {
    //       return;
    //     }
    //
    //     if (res["status"] == "OK") {
    //       var predictions = res["predictions"];
    //
    //       var placelist = (predictions as List).map((e) {
    //         // Parse distance as double from JSON
    //         double distance = e.containsKey("distance") ? (e["distance"] as double) / 1000.0 : 0.0;
    //         // Pass the parsed distance to the constructor
    //         return PlacePredictions.fromJson(e)..distanceInKilometers= distance;
    //       }).toList();
    //
    //
    //       setState(() {
    //         placePredictionList = placelist;
    //       });
    //     }
    //   }
    // }
  
    Future<void> getPlaceAddressDetails(String placeId, BuildContext context) async { // Define context within the method
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Flex(
              direction: Axis.horizontal,
              children: <Widget>[
                CircularProgressIndicator(),
                Padding(
                  padding: EdgeInsets.only(left: 15),
                ),
                Flexible(
                  flex: 8,
                  child: Text(
                    "Setting Dropoff, Please Wait ...",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      );
  
      String placeDetailsUrl = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey";
  
      var res = await RequestAssistant.getRequest(placeDetailsUrl);
  
      Navigator.pop(context);
  
      if (res == "failed") {
        return;
      }
      if (res["status"] == "OK") {
        Address address = Address();
        address.placeName = res["result"]["name"];
        address.placeId = placeId;
        address.latitude = res["result"]["geometry"]["location"]["lat"];
        address.longitude = res["result"]["geometry"]["location"]["lng"];
  
        Provider.of<AppData>(context, listen: false).updateDropOffLocationAddress(address);
  
        // Calculate the distance here
        double sourceLatitude = Provider.of<AppData>(context, listen: false).pickUpLocation.latitude;
        double sourceLongitude = Provider.of<AppData>(context, listen: false).pickUpLocation.longitude;
        // double destinationLatitude = Provider.of<AppData>(context, listen: false).dropOffLocation.latitude;
        // double destinationLongitude = Provider.of<AppData>(context, listen: false).dropOffLocation.longitude;
        double destinationLatitude = address.latitude;
        double destinationLongitude = address.longitude;
  
        double distance = await calculateDistanceBetweenLocations(
          sourceLatitude,
          sourceLongitude,
          destinationLatitude,
          destinationLongitude,
        );
  
        print("This is Drop Off Location");
        print(address.placeName);
        print("Distance: $distance km"); // Print the distance
  
        Navigator.pop(context, "obtainDirection");
      }
    }
  }
  
  class PredictionTile extends StatelessWidget {
    final PlacePredictions placePredictions;
    final Function(String, BuildContext) getPlaceAddressDetails; // Function reference
    final LatLng sourceLocation; // Add this parameter
    final LatLng destinationLocation; // Add this parameter
  
    PredictionTile({
      required Key key,
      required this.placePredictions,
      required this.getPlaceAddressDetails,
      required this.sourceLocation,
      required this.destinationLocation,
    }) : super(key: key);
  
    double calculateDistance(LatLng start, LatLng end) {
      const double earthRadius = 6371.0;
  
  
      final double lat1 = start.latitude * (pi / 180.0);
      final double lon1 = start.longitude * (pi / 180.0);
      final double lat2 = end.latitude * (pi / 180.0);
      final double lon2 = end.longitude * (pi / 180.0);
  
      // Calculate the differences between the coordinates
      final double dLat = lat2 - lat1;
      final double dLon = lon2 - lon1;
  
      // Apply the Haversine formula
      final double a = sin(dLat / 2) * sin(dLat / 2) +
          cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
      final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
      final double distance = earthRadius * c;
  
      return distance; // Distance in kilometers, add "*1000" to get meters
    }
  
    @override
    Widget build(BuildContext context) {
      // Calculate the distance using the source and destination locations
      final double distanceInKilometers =
      calculateDistance(sourceLocation, destinationLocation);
  
      return LoadingButton(
        defaultWidget: Container(
          height: 150,
          child: SingleChildScrollView(
            child: Expanded(
              child: Column(
                children: [
                  SizedBox(
                    width: 10.0,
                  ),
                  Row(
                    children: [
                      Icon(Icons.add_location),
                      SizedBox(
                        width: 14.0,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 8.0,
                            ),
                            Text(
                              placePredictions.main_text!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 16.0),
                            ),
                            SizedBox(
                              height: 8.0,
                            ),
                            Text(
                              placePredictions.secondary_text!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12.0, color: Colors.black),
                            ),
                            SizedBox(
                              height: 8.0,
                            ),
                            Text(
                              '${distanceInKilometers.toStringAsFixed(2)} km',
                              style: TextStyle(fontSize: 12.0, color: Colors.black),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    width: 10.0,
                  ),
                ],
              ),
            ),
          ),
        ),
        onPressed: () async {
          await getPlaceAddressDetails(placePredictions.place_id!, context); // Call the function
        },
      );
    }
  }
  
