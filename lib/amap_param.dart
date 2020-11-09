
import 'package:flutter/cupertino.dart';

class AmapParam {
  static const int routeMap = 0;
  static const int addressDescriptionMap = 1;

  List<double> initialCenterPoint;
  double initialZoomLevel;
  bool enableMyLocation;
  bool enableMyMarker;
  int mapType;

  final List<AddressInfo> startAddressList;
  final List<AddressInfo> endAddressList;

  final List<AddressInfo> merchantAddressList;

  // final List<int> zoomShowTypes;

  AmapParam({
    @required this.initialCenterPoint,
    this.initialZoomLevel = 14,
    this.enableMyLocation = false,
    this.enableMyMarker = false,
    this.startAddressList = const [],
    this.endAddressList = const [],
    this.merchantAddressList = const [],
    this.mapType = routeMap
  });

  toJson() => <String, dynamic> {
    "initialCenterPoint": initialCenterPoint,
    "initialZoomLevel": initialZoomLevel,
    "enableMyLocation": enableMyLocation,
    "enableMyMarker": enableMyMarker,
    "mapType": mapType,
    "startAddressList": startAddressList,
    "endAddressList": endAddressList,
    "merchantAddressList": merchantAddressList
  };
}

class MarkerParam {
  final List<AddressInfo> markerList;
  MarkerParam(this.markerList);

  toJson() => <String, dynamic> {
    "markerList": markerList
  };
}

class AddressInfo {
  GeoPoint geo;
  String address;
  int index;
  String indexName;
  int showType;
  int id;
  int parentId;
  String provinceCode;
  AddressInfo(this.geo, this.address,{this.index = 0, this.indexName, this.showType, this.id, this.parentId, this.provinceCode});

  toJson() => <String, dynamic> {
    "geo": geo,
    "address": address,
    "index": index,
    "indexName": indexName,
    "showType": showType,
    "id": id,
    "parentId": parentId
  };
}

class GeoPoint {
  double lat;
  double lng;
  GeoPoint(this.lat, this.lng);

  toJson() => <String, dynamic> {
    "lat": lat,
    "lng": lng
  };
}