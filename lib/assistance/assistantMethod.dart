

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'package:vsmile/allWidgets/confiMap.dart';
import 'package:vsmile/assistance/requestAssistant.dart';
import 'package:vsmile/dataHandler/appData.dart';
import 'package:vsmile/models/address.dart';
import 'package:vsmile/models/directionDetails.dart';

class AssistantMethods{

  static Future<String> searchCoordinateAddress(Position position , context) async
  {
    String placeAddress = "" ;
    String st1,st2,st3,st4;

    String url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";

    var response =  await RequestAssistant.getRequest(url);
    if(response != "failed")
    {
      placeAddress = response["results"][0]["formatted_address"];
      st1 = response["results"][0]["address_components"][0]["long_name"];
      st2 = response["results"][0]["address_components"][1]["long_name"];
      st3 = response["results"][0]["address_components"][5]["long_name"];
      st4 = response["results"][0]["address_components"][6]["long_name"];
      placeAddress = st1 + " ," + st2 + ", " + st3 + " ," + st4  ;


      late     Address userPickupAddress = Address( );


      userPickupAddress.longitude = position.longitude;
      userPickupAddress.latitude = position.latitude;
      userPickupAddress.placeName = placeAddress;

      Provider.of<AppData>(context,listen: false).updatePickupLocationAddress(userPickupAddress);

    }
    return placeAddress;
  }
  static Future<DirectionDetails?> obtainPlaceDirectionDetails(LatLng initialPosition ,LatLng finalPosition) async {

    String directionUrl = "https://maps.googleapis.com/maps/api/directions/json?origin=${initialPosition.latitude},${initialPosition.longitude}&destination=${finalPosition.latitude},${finalPosition.longitude}&key=$mapKey" ;

    var res = await RequestAssistant.getRequest(directionUrl);

    if(res == "failed"){

      return null;
      // return DirectionDetails(distanceValue: 0, durationValue: 0, distanceText: "", durationText: "", encodedPoints: "encodedPoints") ;
    }

    DirectionDetails directionDetails = DirectionDetails(distanceValue: 0, durationValue: 0, distanceText: "", durationText: "", encodedPoints: "");

    directionDetails.encodedPoints = res["routes"][0]["overview_polyline"]["points"] ;

    directionDetails.distanceText = res["routes"][0]["legs"][0]["distance"]["text"] ;

    directionDetails.distanceValue = res["routes"][0]["legs"][0]["distance"]["value"] ;


    directionDetails.durationText = res["routes"][0]["legs"][0]["duration"]["text"] ;

    directionDetails.durationValue = res["routes"][0]["legs"][0]["duration"]["value"] ;

    return directionDetails;

  }

  Future<void> getPlaceDirection(BuildContext context)  async
  {
    var initialPos = Provider.of<AppData>(context as BuildContext,listen: false, ).pickUpLocation;

    var finalPos = Provider.of<AppData>(context as BuildContext,listen: false, ).dropOffLocation  ;

    var pickUpLatlng = LatLng(initialPos.latitude, initialPos.longitude);

    var dropOffLatlng = LatLng(finalPos.latitude, finalPos.longitude);

    showDialog(
        context: context as BuildContext,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Flex(
              direction: Axis.horizontal,
              children: <Widget>[
                CircularProgressIndicator(),
                Padding(padding: EdgeInsets.only(left: 15),),
                Flexible(
                    flex: 8,
                    child: Text(
                      "Setting Dropoff , Please Wait ...",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    )),
              ],
            ),
          );
        });

    var details = await AssistantMethods.obtainPlaceDirectionDetails(pickUpLatlng, dropOffLatlng);

    Navigator.pop(context as BuildContext);

    print("This is EncodedPoints ::");
    print(details?.encodedPoints);

    Navigator.pop(context as BuildContext,"obtainDirection");


  }
}