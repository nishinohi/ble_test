import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_blue_example/widgets.dart';
import 'ble_util.dart';
import 'trap_module.dart';

class FlutterBlueApp extends StatefulWidget {
  FlutterBlueApp({Key key, this.title, this.isLayoutTest}) : super(key: key);

  // Service UUID
  final String trapModuleServiceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  // Charactaristic UUID
  final String moduleSettingUuid = "a131c37c-6acb-421d-9640-53bdcd818898";
  final String moduleInfoUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  final GlobalKey<ModuleSettingState> _moduleSettingKey = new GlobalKey<ModuleSettingState>();
  final bool isLayoutTest;
  final String title;

  @override
  _FlutterBlueAppState createState() => new _FlutterBlueAppState(bleUtil: new BleUtil());
}

class _FlutterBlueAppState extends State<FlutterBlueApp> {
  _FlutterBlueAppState({Key key, this.bleUtil});
  BluetoothCharacteristic _moduleInfoCharactaristic;
  BluetoothCharacteristic _moduleSettingCharactaristic;

  final BleUtil bleUtil;

  @override
  void initState() {
    super.initState();
    bleUtil.initState(() => setState(() {}));
  }

  @override
  void dispose() {
    bleUtil.dispose();
    super.dispose();
    _clearState();
  }

  _startScan() {
    bleUtil.startScan(() => setState(() {}));
  }

  _stopScan() {
    bleUtil.stopScan();
    setState(() {});
  }

  _connect(BluetoothDevice d) async {
    bleUtil.connect(() => setState(() {}), d);
    setState(() {});
  }

  _disconnect() {
    bleUtil.disconnect();
    _clearState();
    setState(() {});
  }

  _clearState() {
    _moduleInfoCharactaristic = null;
    _moduleSettingCharactaristic = null;
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

  void _setModuleConfig() async {
    List<int> config = await widget._moduleSettingKey.currentState.getModuleConfig();
    if (_moduleSettingCharactaristic == null) {
      _searchModuleSettingCharactaristic();
    }
    bleUtil.writeCharacteristic(_moduleSettingCharactaristic, config);
  }

  /// 特定のCharactaristicを探す
  BluetoothCharacteristic _searchCharactaristic(String serviceUuid, String charactaristicUuid) {
    for (final BluetoothService trapModuleService in bleUtil.services) {
      // 罠モジュールサービス以外は無視
      if (trapModuleService.uuid.toString() != serviceUuid) {
        continue;
      }
      for (final BluetoothCharacteristic trapModuleCharacteristic in trapModuleService.characteristics) {
        // 罠モジュール情報キャラクタリスティック以外は無視
        if (trapModuleCharacteristic.uuid.toString() == charactaristicUuid) {
          return trapModuleCharacteristic;
        }
      }
    }
    return null;
  }

  bool _searchModuleInfoCharactaristic() {
    _moduleInfoCharactaristic = _searchCharactaristic(widget.trapModuleServiceUuid, widget.moduleInfoUuid);
    return _moduleInfoCharactaristic != null;
  }

  bool _searchModuleSettingCharactaristic() {
    _moduleSettingCharactaristic = _searchCharactaristic(widget.trapModuleServiceUuid, widget.moduleSettingUuid);
    return _moduleSettingCharactaristic != null;
  }

  _buildScanningButton() {
    if (bleUtil.isConnected || bleUtil.state != BluetoothState.on) {
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

  _buildScanResultTiles() {
    return bleUtil.scanResults.values
        .map((r) => ScanResultTile(
              result: r,
              onTap: () => _connect(r.device),
            ))
        .toList();
  }

  // モジュール情報タイルを作成
  Widget _buildModuleInfoTiles() {
    if (_moduleInfoCharactaristic == null) {
      _searchModuleInfoCharactaristic();
    }
    return new ModuleInfoTile(
      moduleInfoCharacteristic: _moduleInfoCharactaristic,
      onReadPressed: () => _readCharacteristic(_moduleInfoCharactaristic),
    );
  }

  /// モジュール設定用タイル作成
  Widget _buildModuleSettingTiles() {
    if (_moduleSettingCharactaristic == null) {
      _searchModuleSettingCharactaristic();
    }
    return new ModuleSetting(
      key: widget._moduleSettingKey,
      moduleSettingCharacteristic: _moduleSettingCharactaristic,
      onWrite: () => _setModuleConfig(),
    );
  }

  List<Widget> _buildActionButtons() {
    if (bleUtil.isConnected) {
      return <Widget>[
        new IconButton(
          icon: const Icon(Icons.cancel),
          onPressed: () => _disconnect(),
        )
      ];
    }
    return null;
  }

  Widget _buildAlertTile() {
    return new Container(
      color: Colors.redAccent,
      child: new ListTile(
        title: new Text(
          'Bluetooth adapter is ${bleUtil.state.toString().substring(15)}',
          style: Theme.of(context).primaryTextTheme.subhead,
        ),
        trailing: new Icon(
          Icons.error,
          color: Theme.of(context).primaryTextTheme.subhead.color,
        ),
      ),
    );
  }

  Widget _buildDeviceStateTile() {
    return new ListTile(
        leading: (bleUtil.deviceState == BluetoothDeviceState.connected)
            ? const Icon(Icons.bluetooth_connected)
            : const Icon(Icons.bluetooth_disabled),
        title: new Text('Device is ${bleUtil.deviceState.toString().split('.')[1]}.'),
        subtitle: new Text('${bleUtil.device.id}'),
        trailing: new IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _refreshDeviceState(bleUtil.device),
          color: Theme.of(context).iconTheme.color.withOpacity(0.5),
        ));
  }

  Widget _buildProgressBarTile() {
    return new LinearProgressIndicator();
  }

  // 画面描画
  @override
  Widget build(BuildContext context) {
    var tiles = new List<Widget>();
    if (bleUtil.state != BluetoothState.on) {
      if (!widget.isLayoutTest) {
        tiles.add(_buildAlertTile());
      }
    }
    if (bleUtil.isConnected) {
      tiles.add(_buildDeviceStateTile());
      tiles.add(_buildModuleSettingTiles());
      tiles.add(_buildModuleInfoTiles());
    } else if (widget.isLayoutTest) {
      tiles.add(_buildModuleSettingTiles());
      tiles.add(_buildModuleInfoTiles());
    } else {
      tiles.addAll(_buildScanResultTiles());
    }
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Trap Module Config'),
        actions: _buildActionButtons(),
      ),
      floatingActionButton: _buildScanningButton(),
      body: new Stack(
        children: <Widget>[
          (bleUtil.isScanning) ? _buildProgressBarTile() : new Container(),
          new ListView(
            children: tiles,
          )
        ],
      ),
    );
  }
}
