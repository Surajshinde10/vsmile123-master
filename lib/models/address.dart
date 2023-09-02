class Address {
  String placeName; // Name of the place
  String placeId; // Unique identifier for the place
  String street; // Street address
  String city; // City
  String state; // State or region
  String postalCode; // Postal code
  double latitude; // Latitude coordinate
  double longitude; // Longitude coordinate

  Address({
    this.placeName = '',
    this.placeId = '',
    this.street = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  // Factory constructor to create an Address object from a JSON map
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      placeName: json['placeName'] ?? '',
      placeId: json['placeId'] ?? '',
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postalCode'] ?? '',
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
    );
  }

  // Convert the Address object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'placeName': placeName,
      'placeId': placeId,
      'street': street,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
