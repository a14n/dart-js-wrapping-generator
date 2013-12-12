import 'dart:js' as js;

import 'package:js_wrapping_generator/dart_generator.dart';
import 'package:js_wrapping/js_wrapping.dart' as jsw;

class Enum extends jsw.IsEnum<int> {
  static Enum $wrap(int jsValue) => _FINDER.find(jsValue);

  static final E1 = new Enum._(1);

  static final _FINDER = new jsw.EnumFinder<int, Enum>([E1]);

  Enum._(int value) : super(value);
}

@wrapper @forMethods abstract class Person extends jsw.TypedJsObject {
  String f1;
  set s1(String value);
  Person get g1;
  Enum get g2;
}