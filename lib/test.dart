// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:google_maps_webservice/places.dart';
// import 'package:vsmile/allWidgets/confiMap.dart'; // Assuming this contains your API key
// import 'package:geolocator/geolocator.dart';
//
// class MapScreen extends StatefulWidget {
//   @override
//   _MapScreenState createState() => _MapScreenState();
// }
//
// class _MapScreenState extends State<MapScreen> {
//   late GoogleMapController mapController;
//   final Set<Marker> _markers = Set();
//   GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: mapKey); // Replace with your Google Maps API key
//
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   void _onMapCreated(GoogleMapController controller) {
//     setState(() {
//       mapController = controller;
//     });
//   }
//
//   Future<void> _fetchNearbyPetrolPumps(LatLng currentLocation) async {
//     PlacesSearchResponse response = await _places.searchNearbyWithRadius(
//       Location(lng: currentLocation.longitude, lat: currentLocation.latitude),
//       5000, // Adjust this radius as needed
//       type: 'gas_station', // This type is for petrol pumps
//     );
//
//     setState(() {
//       _markers.clear();
//       if (response.status == 'OK') {
//         for (PlacesSearchResult result in response.results) {
//           _markers.add(
//             Marker(
//               markerId: MarkerId(result.placeId),
//               position: LatLng(
//                 result.geometry?.location.lat ?? 0.0,
//                 result.geometry?.location.lng ?? 0.0,
//               ),
//               infoWindow: InfoWindow(
//                 title: result.name,
//                 snippet: result.vicinity,
//               ),
//             ),
//           );
//         }
//       }
//     });
//   }
//
//   void _getUserLocation() async {
//     // Get the user's current location using the Geolocator package
//     Position position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );
//
//     // Fetch nearby petrol pumps with the obtained location
//     _fetchNearbyPetrolPumps(LatLng(position.latitude, position.longitude));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Petrol Pumps Near Me'),
//       ),
//       body: GoogleMap(
//         onMapCreated: _onMapCreated,
//         initialCameraPosition: CameraPosition(
//           target: LatLng(0.0, 0.0), // Initial map center
//           zoom: 15.0,
//         ),
//         markers: _markers,
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _getUserLocation, // Fetch nearby petrol pumps when the button is pressed
//         child: Icon(Icons.search),
//       ),
//     );
//   }
// }
