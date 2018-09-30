import 'dart:async';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:ui';

class BleUtil {
  FlutterBlue _flutterBlue = FlutterBlue.instance;

  /// Scanning
  StreamSubscription _scanSubscription;
  Map<DeviceIdentifier, ScanResult> scanResults = new Map();
  bool isScanning = false;

  /// State
  StreamSubscription _stateSubscription;
  BluetoothState state = BluetoothState.unknown;

  /// Device
  BluetoothDevice device;
  bool get isConnected => (device != null);
  StreamSubscription deviceConnection;
  StreamSubscription deviceStateSubscription;
  List<BluetoothService> services = new List();
  Map<Guid, StreamSubscription> valueChangedSubscriptions = {};
  BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;

  void initState(VoidCallback onStateChange) {
    // Immediately get the state of FlutterBlue
    _flutterBlue.state.then((s) {
      state = s;
      onStateChange();
    });
    // Subscribe to state changes
    _stateSubscription = _flutterBlue.onStateChanged().listen((s) {
      state = s;
      onStateChange();
    });
  }

  // Future<BluetoothState> init

  void dispose() {
    _stateSubscription?.cancel();
    _stateSubscription = null;
    _scanSubscription?.cancel();
    _scanSubscription = null;
    deviceConnection?.cancel();
    deviceConnection = null;
  }

  void startScan(VoidCallback onStateChange) {
    _scanSubscription = _flutterBlue
        .scan(
      timeout: const Duration(seconds: 10),
      /*withServices: [
          new Guid('0000180F-0000-1000-8000-00805F9B34FB')
        ]*/
    )
        .listen((scanResult) {
      print('localName: ${scanResult.advertisementData.localName}');
      print('manufacturerData: ${scanResult.advertisementData.manufacturerData}');
      print('serviceData: ${scanResult.advertisementData.serviceData}');
      scanResults[scanResult.device.id] = scanResult;
      onStateChange();
    }, onDone: stopScan);

    isScanning = true;
    onStateChange();
  }

  void stopScan() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    isScanning = false;
  }

  void connect(VoidCallback onStateChange, BluetoothDevice d) async {
    device = d;
    // Connect to device
    deviceConnection = _flutterBlue.connect(device, timeout: const Duration(seconds: 4)).listen(
          null,
          onDone: disconnect,
        );

    // Update the connection state immediately
    device.state.then((s) {
      deviceState = s;
      onStateChange();
    });

    // Subscribe to connection changes
    deviceStateSubscription = device.onStateChanged().listen((s) {
      deviceState = s;
      onStateChange();

      if (s == BluetoothDeviceState.connected) {
        device.discoverServices().then((s) {
          services = s;
          onStateChange();
        });
      }
    });
  }

  void disconnect() {
    // Remove all value changed listeners
    valueChangedSubscriptions.forEach((uuid, sub) => sub.cancel());
    valueChangedSubscriptions.clear();
    deviceStateSubscription?.cancel();
    deviceStateSubscription = null;
    deviceConnection?.cancel();
    deviceConnection = null;
    device = null;
  }

  void readCharacteristic(BluetoothCharacteristic c) async {
    await device.readCharacteristic(c);
  }

  void writeCharacteristic(BluetoothCharacteristic c) async {
    await device.writeCharacteristic(c, [0x41, 0x42], type: CharacteristicWriteType.withResponse);
  }

  void readDescriptor(BluetoothDescriptor d) async {
    await device.readDescriptor(d);
  }

  void writeDescriptor(BluetoothDescriptor d) async {
    await device.writeDescriptor(d, [0x12, 0x34]);
  }

  void setNotification(BluetoothCharacteristic c) async {
    if (c.isNotifying) {
      await device.setNotifyValue(c, false);
      // Cancel subscription
      valueChangedSubscriptions[c.uuid]?.cancel();
      valueChangedSubscriptions.remove(c.uuid);
    } else {
      await device.setNotifyValue(c, true);
      // ignore: cancel_subscriptions
      final sub = device.onValueChanged(c).listen((d) {
        print('onValueChanged $d');
      });
      // Add to map
      valueChangedSubscriptions[c.uuid] = sub;
    }
  }

  void refreshDeviceState(BluetoothDevice d) async {
    var state = await d.state;
    deviceState = state;
    print('State refreshed: $deviceState');
  }
}
