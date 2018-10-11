import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:convert';

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

  const ModuleSetting({
    Key key,
    this.moduleSettingCharacteristic,
    this.onWrite,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new ModuleSettingState();
  }
}

class ModuleSettingState extends State {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return null;
  }
}
