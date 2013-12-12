import 'dart:js' as js;

import 'package:js_wrapping_generator/dart_generator.dart';
import 'package:js_wrapping/js_wrapping.dart' as jsw;

class Enum extends jsw.IsEnum<int> {
  static Enum $wrap(int jsValue) => _FINDER.find(jsValue);

  static final E1 = new Enum._(1);

  static final _FINDER = new jsw.EnumFinder<int, Enum>([E1]);

  Enum._(int value) : super(value);
}

@wrapper abstract class Person extends jsw.TypedJsObject {
  static bool isInstance(js.JsObject o) => o.instanceof(js.context['Person']);
  set s1(String value);
  void set s2(Person value);
  void set s3(DateTime value);
  set s4(Enum value);
  void set s5(dynamic value);
  void set s6(@Types(const [Person, num]) dynamic value);
  String get g1;
  Person get g2;
  List<Person> get g3;
  List<String> get g4;
  List get g5;
  DateTime get g6;
  Enum get g7;
  @Types(const [Enum, int]) dynamic get g8;
  @Types(const [Person, num]) dynamic get g9;
  String m1();
  void m2();
  m3();
  Person m4();
  List<Person> m5();
  void m6(List l);
  void m7([List l]);
  Enum m8();
  void m9(@Types(const [Person, num]) dynamic value);
  List<Enum> m10();
}
