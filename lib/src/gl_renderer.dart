import 'dart:typed_data';

abstract class GLRenderer {
  void initialize();
  void updateTexture(int width, int height, Uint8List bytes);
  void draw(double percent, double tilt);
  void destroy();
}
