import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:convert';
import 'activate_timer_settting.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';

class ModuleInfoTile extends StatefulWidget {
  final BluetoothCharacteristic moduleInfoCharacteristic;
  final VoidCallback onReadPressed;
  // final VoidCallback onNotificationPressed;

  const ModuleInfoTile({
    Key key,
    this.moduleInfoCharacteristic,
    this.onReadPressed,
    // this.onNotificationPressed,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new ModuleInfoTileState();
  }
}

class ModuleInfoTileState extends State<ModuleInfoTile> {
  @override
  Widget build(BuildContext context) {
    List<Widget> moduleInfoTiles = this._createModuleInfoTiles(context, widget.moduleInfoCharacteristic);
    print("read moduleInfo");

    return new ExpansionTile(
      title: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Text(
            "Module Info",
          ),
        ],
      ),
      trailing: new IconButton(
        icon: new Icon(
          Icons.sync,
          color: Theme.of(context).iconTheme.color,
        ),
        onPressed: widget.onReadPressed,
      ),
      children: moduleInfoTiles,
    );
  }

  // モジュール情報リストタイルを作成
  List<Widget> _createModuleInfoTiles(BuildContext context, BluetoothCharacteristic infoCharacteristic) {
    Map moduleInfoJson;
    try {
      moduleInfoJson = jsonDecode(String.fromCharCodes(infoCharacteristic.value));
    } catch (e) {
      print(e);
      // モジュール設定値読み取りエラー
      return [
        new ListTile(
          title: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Text(
                "no data available",
                style: Theme.of(context).textTheme.body1.copyWith(color: Colors.red[300]),
              )
            ],
          ),
        )
      ];
    }

    // json データに従ってリストタイルを作成
    List<Widget> moduleInfoTiles = new List();
    moduleInfoJson.keys.forEach((key) {
      Widget title = new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Text('$key : ${moduleInfoJson[key].toString()}'),
        ],
      );
      moduleInfoTiles.add(new ListTile(
        title: title,
      ));
    });

    return moduleInfoTiles;
  }
}

class ModuleSetting extends StatefulWidget {
  final BluetoothCharacteristic moduleSettingCharacteristic;
  final VoidCallback onWrite;
  final BluetoothDeviceState state;

  // 設定値JSONキー
  static final String keyWorkTime = "work_time";
  static final String keyActiveStart = "active_start";
  static final String keyActiveEnd = "active_end";
  static final String keyTrapMode = "trap_mode";
  static final String keyTrapFire = "trap_fire";
  static final String keyGpsLat = "lat";
  static final String keyGpsLon = "lon";
  static final String keyParentNodeId = "parent_id";
  static final String keyNodeNum = "node_num";
  static final String keyWakeTime = "wake_time";
  static final String keyCurrentTime = "current_time";

  const ModuleSetting({
    Key key,
    this.moduleSettingCharacteristic,
    this.onWrite,
    this.state,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new ModuleSettingState();
  }
}

class ModuleSettingState extends State<ModuleSetting> {
  GlobalKey<ActivateTimeSettingState> activateTimeKey = new GlobalKey<ActivateTimeSettingState>();

  @override
  Widget build(BuildContext context) {
    return new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[new ActivateTimeSetting(key: activateTimeKey), _buildSettingButton()],
    );
  }

  /// モジュールの設定値を取得する
  Future<List<int>> getModuleConfig() async {
    // 位置情報
    Position position;
    try {
      Geolocator locator = new Geolocator();
      GeolocationStatus geoStatus = await locator.checkGeolocationPermissionStatus();
      position = geoStatus == GeolocationStatus.granted
          ? await locator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
          : null;
    } on PlatformException catch (e) {
      print(e);
      position = null;
    }
    // 現在時刻(ESP32ではエポックタイムは秒単位で扱う)
    int nowEpoch = (new DateTime.now().millisecondsSinceEpoch / 1000).round();
    // 設定値用Json
    Map configMap = new Map();
    configMap[ModuleSetting.keyTrapMode] = true;
    configMap[ModuleSetting.keyActiveStart] = activateTimeKey.currentState.startTime.hour;
    configMap[ModuleSetting.keyActiveEnd] = activateTimeKey.currentState.endTime.hour;
    configMap[ModuleSetting.keyCurrentTime] = nowEpoch;
    configMap[ModuleSetting.keyGpsLat] = position.latitude.toString();
    configMap[ModuleSetting.keyGpsLon] = position.longitude.toString();
    String temp = json.encode(configMap);
    List<int> config = utf8.encode(temp);
    return config;
    // return null;
  }

  /// モジュール設定ボタン
  Widget _buildSettingButton() {
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        new RaisedButton(
          child: new Text(
            '罠作動',
          ),
          textColor: Colors.white,
          color: Colors.blue,
          onPressed: widget.state == BluetoothDeviceState.connected ? () => _confirmTrapStart() : null,
        ),
      ],
    );
  }

  // 罠作動ボタンが謳歌されたときに実行するか
  Future<Null> _confirmTrapStart() async {
    TimeOfDay startTime = activateTimeKey.currentState.startTime;
    TimeOfDay endTime = activateTimeKey.currentState.endTime;
    return showDialog<Null>(
      context: context,
      // barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('罠を作動開始しますか？'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  '稼働開始時刻 : ${startTime.hour}',
                  style: Theme.of(context).textTheme.caption,
                ),
                Text(
                  '稼働終了時刻 : ${endTime.hour}',
                  style: Theme.of(context).textTheme.caption,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('はい'),
              onPressed: () {
                widget.onWrite();
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('いいえ'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
