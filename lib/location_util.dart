import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LocationUtil {
  Geolocator locator = Geolocator();
  StreamSubscription<Position> _positionStream;
  GeolocationStatus _status;
  GeolocationStatus get status => _status;
  Position _currentPosition;
  Position get currentPosition => (_currentPosition);

  // 初期化
  Future<bool> init() async {
    GeolocationStatus status = await locator.checkGeolocationPermissionStatus();
    return status == GeolocationStatus.granted;
  }

  void setPositionStream(VoidCallback onPositionChange) {
    LocationOptions locationOptions = LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);
    locator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((Position position) {
      _currentPosition = position;
      onPositionChange();
    });

    _positionStream = locator.getPositionStream(locationOptions).listen((Position position) {
      _currentPosition = position;
      onPositionChange();
    });
  }

  Widget _buildGpsInfoTile(String gpsInfo, BuildContext context) {
    return new ListTile(
      title: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Text(
            gpsInfo,
            style: Theme.of(context).textTheme.body2,
          )
        ],
      ),
    );
  }

  List<Widget> buildGpsInfoTiles(BuildContext context) {
    List<Widget> gpsInfoTiles = List();
    if (_currentPosition == null) {
      return [Container()];
    }
    gpsInfoTiles.add(_buildGpsInfoTile("経緯度 : ${_currentPosition.latitude} , ${_currentPosition.longitude}", context));
    gpsInfoTiles.add(_buildGpsInfoTile("高度 : ${_currentPosition.altitude}", context));
    gpsInfoTiles.add(_buildGpsInfoTile("精度 : ${_currentPosition.accuracy}", context));
    return gpsInfoTiles;
  }
}
