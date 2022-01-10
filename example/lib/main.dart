import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flip_widget/flip_widget.dart';
import 'dart:math' as math;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GlobalKey<FlipWidgetState> _flipKey = GlobalKey();

  Offset _oldPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 256,
              height: 256,
              child: GestureDetector(
                child: FlipWidget(
                  key: _flipKey,
                  child: Container(
                    color: Colors.blue,
                    child: Center(
                      child: Text("hello"),
                    ),
                  ),
                ),
                onHorizontalDragStart: (details) {
                  _oldPosition = details.globalPosition;
                  _flipKey.currentState?.startFlip();
                },
                onHorizontalDragUpdate: (details) {
                  Offset off = details.globalPosition - _oldPosition;
                  double percent = math.max(0, -off.dx / 256 / 2);
                  double tilt = math.max(0.3, math.min(8.0, 3.0 + off.dy / 100));
                  percent = percent + math.max(0, percent / 2 * (1-1/tilt));
                  _flipKey.currentState?.flip(percent, tilt);
                },
                onHorizontalDragEnd: (details) {
                  _flipKey.currentState?.stopFlip();
                },
                onHorizontalDragCancel: () {
                  _flipKey.currentState?.stopFlip();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
