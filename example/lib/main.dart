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
                  _flipKey.currentState?.flip(math.max(0, -off.dx / 256));
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
