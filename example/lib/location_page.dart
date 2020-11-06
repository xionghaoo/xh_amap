import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xhamap/amap_location_service.dart';

class LocationPage extends StatefulWidget {
  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {

  final _locationService = AmapLocationService();
  double _lat = 0;
  double _lng = 0;
  String _address;
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    _locationService.stop();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RaisedButton(
              child: Text("开启定位"),
              onPressed: () async {
                if (await Permission.location.request().isGranted) {
                  _locationService.locationOnce((lat, lng, province, district, city, address) {
                    print("position: $lat, $lng");
                    print("province: $province");
                    print("district: $district");
                    print("city: $city");
                    print("address: $address");
                    setState(() {
                      _lat = lat;
                      _lng = lng;
                      _address = address;
                    });
                  });
                } else {
                  Map<Permission, PermissionStatus> statuses = await [Permission.location,].request();
                  print(statuses[Permission.location]);
                }
              },
            ),
            Text("当前位置：$_lat, $_lng, $_address")
          ],
        ),
      ),
    );
  }
}