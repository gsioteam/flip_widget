# flip_widget

Flip your widget.

![screenrecord](pics/screenrecord.gif)

## Usage

It is very easy to use.

```dart
FlipWidget(
    key: _flipKey,
    child: Container(
        color: Colors.blue,
        child: Center(
            child: Text("hello"),
        ),
    ),
)

//...
// Show effect layer.
_flipKey.currentState?.startFlip();
/// Update the effect layer
/// [percent] is the position for flipping at the bottom.
/// [tilt] is the `a` of `y = a*x + b`(line equation). 
_flipKey.currentState?.flip(percent, tilt);
/// Dismiss the effect layer and show the original widget.
_flipKey.currentState?.stopFlip();
```
