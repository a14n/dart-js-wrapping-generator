import 'dart:js' as js;

import 'package:js_wrapping_generator/dart_generator.dart';
import 'package:js_wrapping/js_wrapping.dart' as jsw;

abstract class Person extends jsw.TypedJsObject {
  Person.fromJsObject(js.JsObject jsObject): super.fromJsObject(jsObject);
}
