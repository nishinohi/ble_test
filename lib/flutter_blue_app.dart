import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_blue_example/widgets.dart';
import 'ble_util.dart';
import 'trap_module.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'common_color_theme.dart';

class FlutterBlueApp extends StatefulWidget {
  FlutterBlueApp({Key key, this.title, this.isLayoutTest}) : super(key: key);
  // deviceNamePrefix
  final String deviceNamePrefix = 'TrapModuleSetting';
  final bool isLayoutTest;
  final String title;

  @override
  _FlutterBlueAppState createState() => new _FlutterBlueAppState(bleUtil: new BleUtil());
}

class _FlutterBlueAppState extends State<FlutterBlueApp> {
  _FlutterBlueAppState({Key key, this.bleUtil});

  final BleUtil bleUtil;
  GeolocationStatus _geoStatus = GeolocationStatus.unknown;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    bleUtil.initState(() => setState(() {}));
  }

  @override
  void dispose() {
    bleUtil.dispose();
    super.dispose();
  }

  _startScan() {
    bleUtil.startScan();
  }

  _stopScan() {
    bleUtil.stopScan();
    setState(() {});
  }

  _connect(BluetoothDevice d) async {
    _isConnecting = true;
    if (bleUtil.isScanning) {
      _stopScan();
    }
    bleUtil.connect(() {
      // 接続確立
      if (bleUtil.deviceState == BluetoothDeviceState.connected) {
        _isConnecting = false;
        _pushTrapModuleWidget();
      }
      // タイムアウト
      if (bleUtil.device == null) {
        _isConnecting = false;
      }
    }, d);
    setState(() {});
  }

  _disconnect() {
    bleUtil.disconnect();
    setState(() {});
  }

  _readCharacteristic(BluetoothCharacteristic c) async {
    await bleUtil.readCharacteristic(c);
    setState(() {});
  }

  _writeCharacteristic(BluetoothCharacteristic c, List<int> value) async {
    await bleUtil.writeCharacteristic(c, value);
    setState(() {});
  }

  _readDescriptor(BluetoothDescriptor d) async {
    await bleUtil.readDescriptor(d);
    setState(() {});
  }

  _writeDescriptor(BluetoothDescriptor d) async {
    await bleUtil.writeDescriptor(d);
    setState(() {});
  }

  _setNotification(BluetoothCharacteristic c) async {
    await bleUtil.setNotification(c);
    setState(() {});
  }

  _refreshDeviceState(BluetoothDevice d) async {
    await bleUtil.refreshDeviceState(d);
    setState(() {});
  }

  // GPS の状態を更新
  void _updateGpsStatu() async {
    if (_geoStatus == GeolocationStatus.granted) {
      return;
    }
    try {
      _geoStatus = await new Geolocator().checkGeolocationPermissionStatus();
      setState(() {});
    } on PlatformException catch (e) {
      print(e);
    }
  }

  _buildScanningButton() {
    if (bleUtil.isConnected || bleUtil.state != BluetoothState.on || _geoStatus != GeolocationStatus.granted) {
      return null;
    }
    if (bleUtil.isScanning) {
      return new FloatingActionButton(
        child: new Icon(Icons.stop),
        onPressed: _stopScan,
        backgroundColor: Colors.red,
      );
    } else {
      return new FloatingActionButton(child: new Icon(Icons.search), onPressed: _startScan);
    }
  }

  // TrapModuleのデバイス名を持つBLEのみ表示する
  List<Widget> _buildScanResultTiles() {
    List<Widget> scanResultTiles = new List();
    for (final scanResult in bleUtil.scanResults.values) {
      if (scanResult.device.name.length <= 0) {
        continue;
      }
      if (!scanResult.device.name.contains(widget.deviceNamePrefix)) {
        continue;
      }
      scanResultTiles.add(new ScanResultTile(
        result: scanResult,
        onTap: () => _connect(scanResult.device),
      ));
    }
    return scanResultTiles;
  }

  List<Widget> _buildDisconnectButtons() {
    // if (bleUtil.isConnected) {
    return <Widget>[
      new IconButton(
        icon: const Icon(Icons.cancel),
        onPressed: () => _disconnect(),
      )
    ];
  }

  // エラータイル作成
  Widget _buildAlertTile(String alertMessage) {
    return new Container(
      color: Colors.redAccent,
      child: new ListTile(
        title: new Text(
          alertMessage,
          // 'Bluetooth adapter is ${bleUtil.state.toString().substring(15)}',
          style: Theme.of(context).primaryTextTheme.subhead,
        ),
        trailing: new Icon(
          Icons.error,
          color: Theme.of(context).primaryTextTheme.subhead.color,
        ),
      ),
    );
  }

  Widget _buildProgressBarTile() {
    return new LinearProgressIndicator();
  }

  Widget _buildConnectIndicator() {
    return new Stack(
      children: <Widget>[
        new Opacity(
          opacity: 0.3,
          child: const ModalBarrier(
            dismissible: false,
            color: Colors.grey,
          ),
        ),
        new Center(
          child: new CircularProgressIndicator(),
        )
      ],
    );
  }

  // 罠モジュール設定画面へ遷移
  void _pushTrapModuleWidget() {
    if (Navigator.of(context).canPop()) {
      return;
    }
    Navigator.of(context).push(new MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return new TrapModule(
          bleUtil: bleUtil,
        );
      },
    ));
  }

  // 画面描画
  @override
  Widget build(BuildContext context) {
    var tiles = new List<Widget>();
    // Bluetooth、gps のアクティベートを確認
    if (bleUtil.state != BluetoothState.on) {
      tiles.add(_buildAlertTile('Bluetooth adapter is ${bleUtil.state.toString().substring(15)}'));
    }
    if (_geoStatus != GeolocationStatus.granted) {
      tiles.add(_buildAlertTile('GPS status is ${describeEnum(_geoStatus)}'));
    }
    _updateGpsStatu();
    // 周辺の罠モジュールを表示
    tiles.addAll(_buildScanResultTiles());
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Trap Module'),
        actions: _buildDisconnectButtons(),
      ),
      floatingActionButton: _buildScanningButton(),
      body: new Stack(
        children: <Widget>[
          (bleUtil.isScanning) ? _buildProgressBarTile() : new Container(),
          new ListView(
            children: tiles,
          ),
          _isConnecting ? _buildConnectIndicator() : new Container(),
        ],
      ),
    );
  }
}
