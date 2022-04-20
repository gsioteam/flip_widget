
import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gl_canvas/gl_canvas.dart';

import './gl_renderer.dart';
import './factory_stub.dart'
if (dart.library.io) 'gl_renderer_io.dart'
if (dart.library.html) 'gl_renderer_web.dart';

class FlipWidget extends StatefulWidget {

  final Widget? child;
  final Size textureSize;
  final bool leftToRight;

  /// [child] is the widget you want to flip.
  /// [textureSize] is the pixel size of effect layer.
  FlipWidget({
    Key? key,
    this.child,
    this.textureSize = const Size(512, 512),
    this.leftToRight = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => FlipWidgetState();
}

typedef FlipAction<T> = FutureOr<T> Function();
class FlipWidgetState extends State<FlipWidget> {

  GlobalKey _renderKey = GlobalKey();
  ValueNotifier<bool> _flipping = ValueNotifier(false);
  late GLCanvasController controller;

  late GLRenderer _render;

  bool _disposed = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: _flipping,
          builder: (context, value, child) {
            return IgnorePointer(
              ignoring: value,
              child: Opacity(
                opacity: value ? 0 : 1,
                child: child!,
              ),
            );
          },
          child: RepaintBoundary(
            key: _renderKey,
            child: widget.child,
          ),
        ),
        if (kIsWeb) IgnorePointer(
          child: ValueListenableBuilder<bool>(
            valueListenable: _flipping,
            builder: (context, value, child) {
              return Opacity(
                  opacity: value ? 1 : 0,
                  child: child!
              );
            },
            child: GLCanvas(
              controller: controller,
            ),
          ),
        )
        else ValueListenableBuilder<bool>(
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
    controller = GLCanvasController(
      width: widget.textureSize.width,
      height: widget.textureSize.height,
    );
    _render = createRenderer(
      textureWidth: widget.textureSize.width.toInt(),
      textureHeight: widget.textureSize.height.toInt(),
      leftToRight: widget.leftToRight,
      controller: controller,
    );
    controller.ready.then((value) {
      _render.initialize();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _render.destroy();
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
        var image = await boundary.toImage(
          pixelRatio: MediaQuery.of(context).devicePixelRatio,
        );
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

  /// [percent] is the position for flipping at the bottom.
  /// [tilt] is the `a` of `y = a*x + b`(line equation).
  Future<void> flip(double percent, double tilt) {
    return _queueAction(() {
      if (_disposed) return;
      controller.beginDraw();
      _render.draw(1 - percent, tilt);
      controller.endDraw();
    });
  }

  /// Dismiss effect layer and show the original widget.
  Future<void> stopFlip() {
    return _queueAction(() {
      _flipping.value = false;
    });
  }
}
