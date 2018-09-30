import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_blue_example/widgets.dart';
import 'timer_settting.dart';
import 'ble_util.dart';

class FlutterBlueApp extends StatefulWidget {
  FlutterBlueApp({Key key, this.title, this.isLayoutTest}) : super(key: key);

  final bool isLayoutTest;
  final String title;

  @override
  _FlutterBlueAppState createState() => new _FlutterBlueAppState(bleUtil: new BleUtil());
}

class _FlutterBlueAppState extends State<FlutterBlueApp> {
  _FlutterBlueAppState({Key key, this.bleUtil});

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
    setState(() {});
  }

  _readCharacteristic(BluetoothCharacteristic c) {
    bleUtil.readCharacteristic(c);
    setState(() {});
  }

  _writeCharacteristic(BluetoothCharacteristic c) {
    bleUtil.writeCharacteristic(c);
    setState(() {});
  }

  _readDescriptor(BluetoothDescriptor d) {
    bleUtil.readDescriptor(d);
    setState(() {});
  }

  _writeDescriptor(BluetoothDescriptor d) {
    bleUtil.writeDescriptor(d);
    setState(() {});
  }

  _setNotification(BluetoothCharacteristic c) {
    bleUtil.setNotification(c);
    setState(() {});
  }

  _refreshDeviceState(BluetoothDevice d) async {
    bleUtil.refreshDeviceState(d);
    setState(() {});
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

  /// 接続したデバイスのサービスを表示
  List<Widget> _buildServiceTiles() {
    return bleUtil.services
        .map(
          (s) => new ServiceTile(
                service: s,
                characteristicTiles: s.characteristics
                    .map(
                      (c) => new CharacteristicTile(
                            characteristic: c,
                            onReadPressed: () => _readCharacteristic(c),
                            onWritePressed: () => _writeCharacteristic(c),
                            onNotificationPressed: () => _setNotification(c),
                            descriptorTiles: c.descriptors
                                .map(
                                  (d) => new DescriptorTile(
                                        descriptor: d,
                                        onReadPressed: () => _readDescriptor(d),
                                        onWritePressed: () => _writeDescriptor(d),
                                      ),
                                )
                                .toList(),
                          ),
                    )
                    .toList(),
              ),
        )
        .toList();
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

  Widget _buildTimerPicker() {
    return new TimerPicker();
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
      tiles.add(_buildTimerPicker());
      tiles.addAll(_buildServiceTiles());
    } else if (widget.isLayoutTest) {
      tiles.add(_buildTimerPicker());
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
