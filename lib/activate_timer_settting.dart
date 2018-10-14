import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:numberpicker/numberpicker.dart';

/// 稼働時間設定クラス
class ActivateTimeSetting extends StatefulWidget {
  ActivateTimeSetting({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new ActivateTimeSettingState();
  }
}

class ActivateTimeSettingState extends State<ActivateTimeSetting> {
  bool _isStart = true;

  TimeOfDay _startTime = new TimeOfDay.now();
  TimeOfDay _endTime = new TimeOfDay.now();

  TimeOfDay get startTime => _startTime;
  TimeOfDay get endTime => _endTime;

  Widget _buildTitle() {
    return new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[Text("稼働時間帯")],
    );
  }

  void _updateWorkTime(int newValue) {
    setState(() {
      if (_isStart) {
        _startTime = new TimeOfDay(hour: newValue, minute: 0);
      } else {
        _endTime = new TimeOfDay(hour: newValue, minute: 0);
      }
    });
  }

  // 稼働時刻設定ダイアログ表示
  // 終了時刻は開始時刻より後の時間しか選択できない
  // ただしこのウィジェットの使用上 Picker の min、max に同じ値を設定できないので、
  // 開始時刻に23時を選択した場合は終了時刻が23 - 24時になる
  void _showWorkTimePicker() {
    showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return new NumberPickerDialog.integer(
            minValue: _isStart ? 0 : _startTime.hour + 1 > 23 ? 23 : _startTime.hour + 1,
            maxValue: _isStart ? 23 : 24,
            title: _isStart
                ? new Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "開始時刻",
                        style: new TextStyle(fontSize: 18.0),
                      ),
                    ],
                  )
                : new Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "終了時刻",
                        style: new TextStyle(fontSize: 18.0),
                      ),
                    ],
                  ),
            initialIntegerValue:
                _isStart ? 0 : _endTime.hour > _startTime.hour + 1 ? _endTime.hour : _startTime.hour + 1,
          );
        }).then((int value) {
      if (value == null) {
        _isStart = true;
        return;
      }
      setState(() => _updateWorkTime(value));
      if (_isStart) {
        _showWorkTimePicker();
      }
      _isStart = !_isStart;
    });
  }

  Widget _buildTimeList() {
    return new Container(
      padding: EdgeInsets.only(left: 30.0, bottom: 10.0),
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              new Text(
                '稼働開始時刻 : ${_startTime.hour}',
                style: Theme.of(context).textTheme.caption,
              ),
            ],
          ),
          new Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              new Text(
                '稼働終了時刻 : ${_endTime.hour}',
                style: Theme.of(context).textTheme.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new ExpansionTile(
      title: _buildTitle(),
      trailing: new RaisedButton(
        child: Text(
          'SET',
        ),
        textColor: Colors.white,
        color: Colors.blue,
        onPressed: () {
          _showWorkTimePicker();
        },
      ),
      children: <Widget>[
        _buildTimeList(),
      ],
    );
  }
}
