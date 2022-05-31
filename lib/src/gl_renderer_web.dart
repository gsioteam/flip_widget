import 'dart:typed_data';

import 'package:gl_canvas/gl_canvas.dart';

import 'gl_renderer.dart';
import 'package:flip_renderer/flip_renderer.dart';

class GLRendererWeb extends GLRenderer {
  FlipRenderer _renderer;

  @override
  void destroy() {
    _renderer.destroy();
  }

  @override
  void draw(double percent, double tilt) {
    _renderer.draw(percent, tilt);
  }

  @override
  void initialize() {
    _renderer.initialize();
  }

  @override
  void updateTexture(int width, int height, Uint8List bytes) {
    _renderer.updateTexture(width, height, bytes);
  }

  GLRendererWeb({
    required int textureWidth,
    required int textureHeight,
    required bool leftToRight,
    required GLCanvasController controller,
    double rollSize = 12,
  }) : _renderer = FlipRenderer(
            textureWidth: textureWidth,
            textureHeight: textureHeight,
            leftToRight: leftToRight,
            context: controller.context as dynamic);
}

GLRenderer createRenderer({
  required int textureWidth,
  required int textureHeight,
  required bool leftToRight,
  required GLCanvasController controller,
  double rollSize = 12,
}) {
  return GLRendererWeb(
      textureWidth: textureWidth,
      textureHeight: textureHeight,
      leftToRight: leftToRight,
      controller: controller,
      rollSize: rollSize);
}
