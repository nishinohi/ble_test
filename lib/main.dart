// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'flutter_blue_app.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new MaterialApp(
      title: 'Trap Module Config',
      theme: new ThemeData(
        primaryColor: Colors.blue,
      ),
      home: new FlutterBlueApp(
        isLayoutTest: false,
      ),
    );
  }
}
