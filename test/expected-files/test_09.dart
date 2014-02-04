import 'dart:js' as js;
import 'dart:html' as html;

import 'package:js_wrapping_generator/dart_generator.dart';
import 'package:js_wrapping/js_wrapping.dart' as jsw;

class Enum extends jsw.IsEnum<int> {
  static Enum $wrap(int jsValue) => _FINDER.find(jsValue);

  static final E1 = new Enum._(1);

  static final _FINDER = new jsw.EnumFinder<int, Enum>([E1]);

  Enum._(int value)
      : super(value);
}

class Person extends jsw.TypedJsObject {
  static Person $wrap(js.JsObject jsObject) => jsObject == null ? null : new Person.fromJsObject(jsObject);
  Person.fromJsObject(js.JsObject jsObject) : super.fromJsObject(jsObject);
  set f1(String f1) => $unsafe['f1'] = f1;
  String get f1 => $unsafe['f1'];
  set f2(String f2) => $unsafe.callMethod('setF2', [f2]);
  String get f2 => $unsafe.callMethod('getF2');
  set f3(String f3) => $unsafe['f3'] = f3;
  String get f3 => $unsafe['f3'];
  set f4(String f4) => $unsafe['f4'] = f4;
  String get f4 => $unsafe['f4'];
  set f5(Person f5) => $unsafe['f5'] = f5 == null ? null : f5.$unsafe;
  Person get f5 => Person.$wrap($unsafe['f5']);
  set f6(List<Person> f6) => $unsafe['f6'] = jsw.jsify(f6);
  List<Person> get f6 => jsw.TypedJsArray.$wrapSerializables($unsafe['f6'], Person.$wrap);
  set f7(List<String> f7) => $unsafe['f7'] = jsw.jsify(f7);
  List<String> get f7 => jsw.TypedJsArray.$wrap($unsafe['f7']);
  set f8(List f8) => $unsafe['f8'] = jsw.jsify(f8);
  List get f8 => jsw.TypedJsArray.$wrap($unsafe['f8']);
  set f9Rox(String f9Rox) => $unsafe['f9_rox'] = f9Rox;
  String get f9Rox => $unsafe['f9_rox'];
  set f10(Enum f10) => $unsafe['f10'] = f10 == null ? null : f10.$unsafe;
  Enum get f10 => Enum.$wrap($unsafe['f10']);
  set f11(dynamic f11) => $unsafe['f11'] = f11 is html.Node ? f11 : f11 is String ? f11 : f11 == null ? null : throw "bad type";
  dynamic get f11 => ((v2) => v2 is html.Node ? v2 : ((v1) => v1 is String ? v1 : ((v0) => v0)(v1))(v2))($unsafe['f11']);
}
