import 'package:flutter/cupertino.dart';
import 'package:vsmile/models/address.dart';

class AppData extends ChangeNotifier {
  // late Address pickUpLocation = Address("", "", "", 0.0, 0.0),dropOffLocation;
  // late Address pickUpLocation;
  late Address pickUpLocation = Address();
  late Address dropOffLocation = Address();




  void updatePickupLocationAddress(Address pickUpAddress){
    pickUpLocation = pickUpAddress ;
    notifyListeners();

  }
  void updateDropOffLocationAddress(Address dropOffAddress)
  {
    dropOffLocation = dropOffAddress;
    notifyListeners();
  }
}