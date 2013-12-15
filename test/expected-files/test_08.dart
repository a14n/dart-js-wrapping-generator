import 'dart:js' as js;

import 'package:js_wrapping_generator/dart_generator.dart';
import 'package:js_wrapping/js_wrapping.dart' as jsw;

class Enum extends jsw.IsEnum<int> {
  static Enum $wrap(int jsValue) => _FINDER.find(jsValue);

  static final E1 = new Enum._(1);

  static final _FINDER = new jsw.EnumFinder<int, Enum>([E1]);

  Enum._(int value) : super(value);
}

class Person extends jsw.TypedJsObject {
  static Person $wrap(js.JsObject jsObject) => jsObject == null ? null : new Person.fromJsObject(jsObject);
  Person.fromJsObject(js.JsObject jsObject) : super.fromJsObject(jsObject);
  static bool isInstance(js.JsObject o) => o.instanceof(js.context['Person']);
  set s1(String value) => $unsafe['s1'] = value;
  void set s2(Person value) { $unsafe['s2'] = value == null ? null : value.$unsafe; }
  void set s3(DateTime value) { $unsafe['s3'] = value; }
  set s4(Enum value) => $unsafe['s4'] = value == null ? null : value.$unsafe;
  void set s5(dynamic value) { $unsafe['s5'] = value == null ? null : jsw.mayUnwrap(value); }
  void set s6(dynamic value) { $unsafe['s6'] = value == null ? null : value is Person ? value.$unsafe : value is num ? value :  throw "bad type"; }
  String get g1 => $unsafe['g1'];
  Person get g2 => Person.$wrap($unsafe['g2']);
  List<Person> get g3 => jsw.TypedJsArray.$wrapSerializables($unsafe['g3'], Person.$wrap);
  List<String> get g4 => jsw.TypedJsArray.$wrap($unsafe['g4']);
  List get g5 => jsw.TypedJsArray.$wrap($unsafe['g5']);
  DateTime get g6 => $unsafe['g6'];
  Enum get g7 => Enum.$wrap($unsafe['g7']);
  dynamic get g8 => ((v3) => ((v2) => v2 != null ? v2 : ((v1) => v1 is int ? v1 : ((v0) => v0)(v1))(v3))(Enum.$wrap(v3)))($unsafe['g8']);
  dynamic get g9 => ((v2) => Person.isInstance(v2) ? Person.$wrap(v2) : ((v1) => v1 is num ? v1 : ((v0) => v0)(v1))(v2))($unsafe['g9']);
  String m1() => $unsafe.callMethod('m1');
  void m2() { $unsafe.callMethod('m2'); }
  m3() => $unsafe.callMethod('m3');
  Person m4() => Person.$wrap($unsafe.callMethod('m4'));
  List<Person> m5() => jsw.TypedJsArray.$wrapSerializables($unsafe.callMethod('m5'), Person.$wrap);
  void m6(List l) { $unsafe.callMethod('m6', [l == null ? null : (l is jsw.TypedJsObject ? (l as jsw.TypedJsObject).$unsafe : jsw.jsify(l))]); }
  void m7([List l]) { $unsafe.callMethod('m7', [l == null ? null : (l is jsw.TypedJsObject ? (l as jsw.TypedJsObject).$unsafe : jsw.jsify(l))]); }
  Enum m8() => Enum.$wrap($unsafe.callMethod('m8'));
  void m9(dynamic value) { $unsafe.callMethod('m9', [value == null ? null : value is Person ? value.$unsafe : value is num ? value :  throw "bad type"]); }
  List<Enum> m10() => jsw.TypedJsArray.$wrapSerializables($unsafe.callMethod('m10'), Enum.$wrap);
  void m11([dynamic value]) { $unsafe.callMethod('m11', [value == null ? null : value is Person ? value.$unsafe : value is num ? value :  throw "bad type"]); }
  void m12(value) { $unsafe.callMethod('m12', [value == null ? null : jsw.mayUnwrap(value)]); }
}
