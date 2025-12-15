import 'package:flutter/material.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';

class MapDemoPage extends StatefulWidget {
  @override
  _MapDemoPageState createState() => _MapDemoPageState();
}

class _MapDemoPageState extends State<MapDemoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('地图 Demo')),
      body: Column(
        children: [
          Container(
            height: 400,
            child: AMapWidget(
              privacyStatement: const AMapPrivacyStatement(
                hasContains: true,
                hasShow: true,
                hasAgree: true,
              ),
              apiKey: const AMapApiKey(
                androidKey: 'your_android_key',
                iosKey: 'your_ios_key',
              ),
              initialCameraPosition: const CameraPosition(
                target: LatLng(39.909187, 116.397451), // 北京天安门
                zoom: 15,
              ),
              markers: <Marker>{
                Marker(
                  position: const LatLng(39.909187, 116.397451),
                  icon: BitmapDescriptor.defaultMarker,
                ),
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('导航功能（Mock）')),
                    );
                  },
                  child: const Text('开始导航（Mock）'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('搜索地点（Mock）')),
                    );
                  },
                  child: const Text('搜索地点（Mock）'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
