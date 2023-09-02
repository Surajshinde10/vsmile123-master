class PlacePredictions {
  late String secondary_text;
  late String place_id;
  late String main_text;
  double? distance;
  double? distanceInKilometers;
  double? latitude; // Add latitude property
  double? longitude; // Add longitude property

  PlacePredictions.fromJson(Map<String, dynamic> json) {
    secondary_text = json["structured_formatting"]["secondary_text"];
    place_id = json["place_id"];
    main_text = json["structured_formatting"]["main_text"];
    distance = json["distance"] != null ? double.tryParse(json["distance"]) ?? 0.0 : 0.0;
    distanceInKilometers = distance != null ? distance! / 1000.0 : 0.0;

    // Parse latitude and longitude
    final geometry = json["geometry"];
    if (geometry != null) {
      final location = geometry["location"];
      if (location != null) {
        latitude = location["lat"] != null ? double.tryParse(location["lat"]) ?? 0.0 : 0.0;
        longitude = location["lng"] != null ? double.tryParse(location["lng"]) ?? 0.0 : 0.0;
      }
    }
  }
}
