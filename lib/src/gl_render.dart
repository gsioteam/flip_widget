
import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:opengl_es_bindings/opengl_es_bindings.dart';
import 'package:ffi/ffi.dart';

const String _VertexShader = """
attribute vec4 position;
attribute vec2 tex_coord;
varying vec2 uv;
void main(void)
{
    gl_Position = position;
    uv = tex_coord;
}
""";
const String _FragmentShader = """
precision mediump float;
uniform sampler2D texture;
uniform float percent;
uniform float tilt;
varying vec2 uv;
void main()
{
    float x1 = uv.x;
    float y1 = 1.0 - uv.y;
    if (tilt * (x1 - percent) > y1) {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
    } else {
        float x0 = (x1 / tilt + y1 + percent * tilt) / (tilt + 1.0/tilt);
        float x2 = 2.0 * x0 - x1;
        float dis = abs(x1 - x0);
        float y2 = 2.0 * (x1 - x0) / tilt + y1 - max(0.0, x2 - percent) * (1.0 - x2) / (1.0 - percent);
        if (y2 > 0.0 && x2 < 1.0) {
            vec4 val = mix(vec4(0.6, 0.6, 0.6, 1.0), vec4(0.98, 0.98, 0.98, 1.0), min(1.0, dis/0.1));
            gl_FragColor = texture2D(texture, vec2(x2, 1.0 - y2)) * val;
        } else {
            gl_FragColor = texture2D(texture, vec2(x1, 1.0 - y1));
        }
    }
}
""";

class GLRender {
  LibOpenGLES GLES20 = LibOpenGLES(
      Platform.isAndroid ?
      DynamicLibrary.open("libGLESv2.so"):
      DynamicLibrary.process()
  );

  int loadProgram(String vertex, String fragment) {
    int vertexShader = loadShader(GL_VERTEX_SHADER, vertex);
    if (vertexShader == 0)
      return 0;

    int fragmentShader = loadShader(GL_FRAGMENT_SHADER, fragment);
    if (fragmentShader == 0) {
      GLES20.glDeleteShader(vertexShader);
      return 0;
    }

    // Create the program object
    int programHandle = GLES20.glCreateProgram();
    if (programHandle == 0)
      return 0;

    GLES20.glAttachShader(programHandle, vertexShader);
    GLES20.glAttachShader(programHandle, fragmentShader);

    // Link the program
    GLES20.glLinkProgram(programHandle);

    GLES20.glDeleteShader(vertexShader);
    GLES20.glDeleteShader(fragmentShader);

    return programHandle;
  }

  int loadShader(int type, String shaderStr) {
    int shader = GLES20.glCreateShader(type);
    if (shader == 0) {
      print("Error: failed to create shader.");
      return 0;
    }

    var shaderPtr = shaderStr.toNativeUtf8();
    Pointer<Pointer<Int8>> thePtr = malloc.allocate(sizeOf<Pointer>());
    thePtr.value = shaderPtr.cast<Int8>();
    GLES20.glShaderSource(shader, 1, thePtr, Pointer.fromAddress(0));
    malloc.free(shaderPtr);
    malloc.free(thePtr);

    // Compile the shader
    GLES20.glCompileShader(shader);

    return shader;
  }

  int _programHandle = 0;
  int _positionAttr = 0;
  int _texCoordAttr = 0;
  int _textureUniform = 0;
  int _percentUniform = 0;
  int _tiltUniform = 0;

  late Pointer<Uint32> buffers;
  int _mainTexture = -1;

  late Pointer<Int8> _templateString;

  Pointer<Int8> _n(String str) {
    final units = utf8.encode(str);
    final Int8List nativeString = _templateString.asTypedList(units.length + 1);
    nativeString.setAll(0, units);
    nativeString[units.length] = 0;
    return _templateString;
  }

  void initialize() {
    _templateString = malloc.allocate(sizeOf<Int8>() * 512);

    _programHandle = loadProgram(_VertexShader, _FragmentShader);

    Pointer<Int32> ret = malloc.allocate(sizeOf<Int32>());
    GLES20.glGetProgramiv(_programHandle, GL_LINK_STATUS, ret);
    if(ret[0] == 0)
    {
      GLES20.glGetProgramInfoLog(_programHandle, 512, Pointer<Int32>.fromAddress(0), _templateString);
      print("FlipTexture:${_templateString.cast<Utf8>().toDartString()}");
    }

    GLES20.glUseProgram(_programHandle);
    _positionAttr = GLES20.glGetAttribLocation(_programHandle, _n("position"));
    _texCoordAttr = GLES20.glGetAttribLocation(_programHandle, _n("tex_coord"));
    _textureUniform = GLES20.glGetUniformLocation(_programHandle, _n("texture"));
    _percentUniform = GLES20.glGetUniformLocation(_programHandle, _n("percent"));
    _tiltUniform = GLES20.glGetUniformLocation(_programHandle, _n("tilt"));

    List<double> pos = [
      -1.0, 1.0, 0.0,
      1.0, 1.0, 0.0,
      -1.0, -1.0, 0.0,
      1.0, -1.0, 0.0,
    ];

    List<double> uv = [
      0, 0,
      1, 0,
      0, 1,
      1, 1,
    ];

    buffers = malloc.allocate(sizeOf<Uint32>() * 2);
    GLES20.glGenBuffers(2, buffers);
    GLES20.glBindBuffer(GL_ARRAY_BUFFER, buffers[0]);

    int len = sizeOf<Float>() * pos.length;
    Pointer<Float> buffer = malloc.allocate(len);
    Float32List list = buffer.asTypedList(pos.length);
    list.setAll(0, pos);
    GLES20.glBufferData(GL_ARRAY_BUFFER, len, buffer.cast<Void>(), GL_STATIC_DRAW);
    malloc.free(buffer);

    GLES20.glBindBuffer(GL_ARRAY_BUFFER, buffers[1]);

    len = sizeOf<Float>() * uv.length;
    buffer = malloc.allocate(len);
    list = buffer.asTypedList(pos.length);
    list.setAll(0, uv);
    GLES20.glBufferData(GL_ARRAY_BUFFER, len, buffer.cast<Void>(), GL_STATIC_DRAW);
    malloc.free(buffer);
  }

  void updateTexture(int width, int height, Uint8List bytes) {

    Pointer<Uint32> textures = malloc.allocate(sizeOf<Uint32>());
    if (_mainTexture != -1) {
      textures[0] = _mainTexture;
      GLES20.glDeleteTextures(1, textures);
    }

    GLES20.glGenTextures(1, textures);
    _mainTexture = textures[0];
    malloc.free(textures);

    GLES20.glBindTexture(GL_TEXTURE_2D, _mainTexture);
    GLES20.glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
    GLES20.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    GLES20.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    GLES20.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    GLES20.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    Pointer<Uint8> buffer = malloc.allocate(bytes.length);
    var bufferBytes = buffer.asTypedList(bytes.length);
    bufferBytes.setAll(0, bytes);
    GLES20.glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, buffer.cast<Void>());
    malloc.free(buffer);
  }

  void draw(double percent, double tilt) {

    GLES20.glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    GLES20.glClearColor(0, 0, 0, 0);
    GLES20.glClear(GL_COLOR_BUFFER_BIT);

    GLES20.glViewport(0, 0, 512, 512);

    GLES20.glUseProgram(_programHandle);

    GLES20.glEnableVertexAttribArray(_positionAttr);
    GLES20.glBindBuffer(GL_ARRAY_BUFFER, buffers[0]);
    GLES20.glVertexAttribPointer(_positionAttr, 3, GL_FLOAT, 0, 0, Pointer.fromAddress(0) );

    GLES20.glEnableVertexAttribArray(_texCoordAttr);
    GLES20.glBindBuffer(GL_ARRAY_BUFFER, buffers[1]);
    GLES20.glVertexAttribPointer(_texCoordAttr, 2, GL_FLOAT, 0, 0, Pointer.fromAddress(0) );

    GLES20.glActiveTexture(GL_TEXTURE0);
    GLES20.glBindTexture(GL_TEXTURE_2D, _mainTexture);
    GLES20.glUniform1i(_textureUniform, 0);

    GLES20.glUniform1f(_percentUniform, percent);
    GLES20.glUniform1f(_tiltUniform, tilt);

    GLES20.glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  }

  void destroy() {
    GLES20.glDeleteBuffers(2, buffers);
    malloc.free(buffers);
    malloc.free(_templateString);
    if (_mainTexture != -1) {
      Pointer<Uint32> textures = malloc.allocate(sizeOf<Uint32>());
      textures[0] = _mainTexture;
      GLES20.glDeleteTextures(1, textures);
      malloc.free(textures);
    }
    GLES20.glDeleteProgram(_programHandle);
  }
}