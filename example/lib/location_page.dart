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
                  _locationService.start();
                  _locationService.startLocationStream().listen((location) {
                    _address = location['address'];
                    _lat = location['lat'];
                    _lng = location['lng'];
                    if (_lat != null && _lng != null) {
                      if (mounted) {
                        setState(() {

                        });
                      }
                    }
                    
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