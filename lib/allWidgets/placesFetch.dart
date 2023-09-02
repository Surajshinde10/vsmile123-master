import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:vsmile/allWidgets/confiMap.dart';


class PlacesService {
  final String mapKey;

  PlacesService(this.mapKey);

  Future<List<Place>> getPlaces(double lat, double lng) async {
    final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=5000&type=gas_station|petrol_station&key=$mapKey'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'] as List<dynamic>;

      List<Place> places = [];
      for (var result in results) {
        final name = result['name'];
        final geometry = result['geometry'];
        final location = geometry['location'];
        final lat = location['lat'];
        final lng = location['lng'];

        final place = Place(name: name, lat: lat, lng: lng, vicinity: "vici");
        places.add(place);
      }

      return places;
    } else {
      throw Exception('Failed to load places');
    }
  }
}

// class Place {
//   final String name;
//   final double lat;
//   final double lng;
//
//   Place({required this.name, required this.lat, required this.lng});
// }


class Place {
  String name;
  double lat;
  double lng;
  String vicinity;

  Place({
    required this.name,
    required this.lat,
    required this.lng,
    required this.vicinity,
  });

  // Create a factory method to parse the JSON data and construct a Place object
  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      name: json['name'],
      lat: json['geometry']['location']['lat'],
      lng: json['geometry']['location']['lng'],
      vicinity: json['vicinity'],
    );
  }
}








class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Place> places = [];

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

    final currentLocation = await getCurrentLocation();

    final fetchedPlaces =
    await placesService.getPlaces(currentLocation.latitude, currentLocation.longitude);

    setState(() {
      places = fetchedPlaces;
    });


  }

  @override
  void initState() {
    super.initState();
    fetchPlaces();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
      ListView.builder(
        itemCount: places.length,
        itemBuilder: (context, index) {
          final place = places[index];
          return GestureDetector(
            onTap: () {

              Navigator.pop(context,"obtainDirection");

            },
            child: ListTile(
              title: Text(place.name),
              // subtitle: Text('Lat: ${place.lat}, Lng: ${place.lng}'),
            ),
          );
        },
      ),
    );
  }
}


