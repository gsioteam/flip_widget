
import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gl_canvas/gl_canvas.dart';

import './gl_render.dart';

class FlipWidget extends StatefulWidget {

  final Widget? child;

  FlipWidget({
    Key? key,
    this.child,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => FlipWidgetState();
}

typedef FlipAction<T> = FutureOr<T> Function();
class FlipWidgetState extends State<FlipWidget> {

  GlobalKey _renderKey = GlobalKey();
  ValueNotifier<bool> _flipping = ValueNotifier(false);
  late GLCanvasController controller;

  GLRender _render = GLRender();

  bool _disposed = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: _flipping,
          builder: (context, value, child) {
            return Visibility(
                visible: !value,
                child: child!
            );
          },
          child: RepaintBoundary(
            key: _renderKey,
            child: widget.child,
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _flipping,
          builder: (context, value, child) {
            return Visibility(
                visible: value,
                child: child!
            );
          },
          child: GLCanvas(
            controller: controller,
          ),
        )
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    controller = GLCanvasController();
    controller.ready.then((value) {
      _render.initialize();
    });
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    _disposed = true;
  }

  Future? _pending;
  Future<T> _queueAction<T>(FlipAction<T> action) async {
    _pending = _innerAction<T>(action);
    dynamic ret = await _pending;
    return ret;
  }

  Future<T> _innerAction<T>(FlipAction<T> action) async {
    await _pending;
    return action();
  }

  Future<void> startFlip() async {
    RenderObject? boundary = _renderKey.currentContext?.findRenderObject();
    if (boundary is RenderRepaintBoundary) {
      await _queueAction(() async {
        var image = await boundary.toImage();
        var buffer = await image.toByteData(format: ImageByteFormat.rawRgba);
        if (buffer != null) {
          var bytes = buffer.buffer.asUint8List(buffer.offsetInBytes, buffer.lengthInBytes);
          if (!_disposed) {
            controller.beginDraw();
            _render.updateTexture(image.width, image.height, bytes);
            _render.draw(1, 1);
            controller.endDraw();

            _flipping.value = true;
          }
        }
      });
    }
  }

  Future<void> flip(double percent) {
    return _queueAction(() {
      controller.beginDraw();
      print('Percent ${1 - (percent * 2)}');
      _render.draw(1 - (percent * 2), 1);
      controller.endDraw();
    });
  }

  Future<void> stopFlip() {
    return _queueAction(() {
      _flipping.value = false;
    });
  }
}