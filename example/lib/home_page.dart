import 'package:flutter/material.dart';

import 'address_select_page.dart';
import 'location_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("高德地图Demo"),),
      body: Column(
        children: [
          GestureDetector(
            child: Container(
              alignment: Alignment.center,
              height: 40,
              child: Text("地址选点"),
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AddressSelectPage()));
            },
          ),
          SizedBox(height: 20,),
          GestureDetector(
            child: Container(
              alignment: Alignment.center,
              height: 40,
              child: Text("定位"),
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPage()));
            },
          )
        ],
      ),
    );
  }
}