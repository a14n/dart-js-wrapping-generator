Dart Js Wrapping Generator
==========================

This project provides a generator for Dart libraries that wraps JS libraries.

Generated wrappers are based on _dart:js_.

## Example of generation based on Dart template ##

Given a template _class_ like :

```dart
import 'dart:js' as js;

import 'package:js_wrapping_generator/dart_generator.dart';
import 'package:js_wrapping/js_wrapping.dart' as jsw;

@wrapper abstract class Point {
  num x;
  num y;

  bool equals(Point other);
  Point middleWith(Point other);
}
```

The generated wrapper will be :

```dart
import 'dart:js' as js;

import 'package:js_wrapping_generator/dart_generator.dart';
import 'package:js_wrapping/js_wrapping.dart' as jsw;

class Point extends jsw.TypedJsObject {
  static Point cast(js.JsObject jsObject) => jsObject == null ? null : new Point.fromJsObject(jsObject);
  Point.fromJsObject(js.JsObject jsObject) : super.fromJsObject(jsObject);

  set x(num x) => $unsafe['x'] = x;
  num get x => $unsafe['x'];
  set y(num y) => $unsafe['y'] = y;
  num get y => $unsafe['y'];

  bool equals(Point other) => $unsafe.callMethod('equals', [other]);
  Point middleWith(Point other) => Point.cast($unsafe.callMethod('middleWith', [other]));
}
```

## License ##
Apache 2.0
