// Copyright (c) 2013, Alexandre Ardhuin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library js_wrapping.dart_generator;

import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/services/formatter_impl.dart';

import 'package:path/path.dart' as p;

const _LIBRARY_NAME = 'js_wrapping.dart_generator';

// TODO add @withInstanceOf
// TODO instanceof for anoynmous object
// TODO add @remove to avoid super.method() - see MVCArray
// TODO remove @wrapper ?
// TODO add handling of "dynamic/*String|Type*/" syntax to handle thing like List<String|MapTypeId>

const wrapper = const _Wrapper();
class _Wrapper {
  const _Wrapper();
}

const keepAbstract = const _KeepAbstract();
class _KeepAbstract {
  const _KeepAbstract();
}

const skipWrap = const _SkipWrap();
class _SkipWrap {
  const _SkipWrap();
}

const skipConstructor = const _SkipConstructor();
class _SkipConstructor {
  const _SkipConstructor();
}

const forMethods = const _PropertyMapping('method');
const namesWithUnderscores = const _PropertyMapping('property_underscore');
class _PropertyMapping {
  final String type;
  const _PropertyMapping(this.type);
}

const generate = const _Generate();
class _Generate {
  const _Generate();
}

class Types {
  final List<Type> types;
  const Types(this.types);
}

class Generator {
  final _context = AnalysisEngine.instance.createAnalysisContext();
  String dartConstructorNS;

  Generator(String packagesDir) {
    _context
      ..analysisOptions.hint = false
      ..analysisOptions.dart2jsHint = false
      ..sourceFactory = new SourceFactory.con2([
          new DartUriResolver(DirectoryBasedDartSdk.defaultSdk),
          new FileUriResolver(),
          new PackageUriResolver([new JavaFile(p.absolute('packages'))])]
      );
  }

  void transformLibrary(File libraryFile, Directory to) {}

  void transformDirectory(File libraryFile, Directory from, Directory to) {
    from.listSync().forEach((FileSystemEntity fse){
      final name = p.basename(fse.path);
      if (fse is File) {
        transformFile(libraryFile, fse, to);
      } else if (fse is Directory) {
        final d = new Directory(p.join(to.path, name));
        if (d.existsSync()) d..deleteSync(recursive: true);
        d.createSync(recursive: true);
        transformDirectory(libraryFile, fse, d);
      }
    });
  }

  void transformFile(File libraryFile, File from, Directory to) {
    final name = p.basename(from.path);
    final generatedFile = new File(p.join(to.path, name));

    // reset generatedFile
    if (generatedFile.existsSync()) generatedFile..deleteSync();
    generatedFile.createSync(recursive: true);

    // transform
    final unit = parseDartFile(libraryFile, from);
    final code = from.readAsStringSync();
    final transformations = _buildTransformations(unit, code);
    final source = _applyTransformations(code, transformations);
    try {
      generatedFile.writeAsStringSync(new CodeFormatter().format(CodeKind.COMPILATION_UNIT, source).source);
    } on FormatterException {
      generatedFile.writeAsStringSync(source);
    }
  }

  /// Parses a Dart file into an AST.
  CompilationUnit parseDartFile(File libraryFile, File file) {
    final librarySource = new FileBasedSource.con1(_context.sourceFactory.contentCache, new JavaFile(p.absolute(libraryFile.path)));
    final fileSource = new FileBasedSource.con1(_context.sourceFactory.contentCache, new JavaFile(p.absolute(file.path)));
    final library = _context.computeLibraryElement(librarySource);
    return _context.resolveCompilationUnit(fileSource, library);
  }

  List<_Transformation> _buildTransformations(CompilationUnit unit, String code) {
    final result = new List<_Transformation>();
    for (final declaration in unit.declarations) {
      if (declaration is ClassDeclaration && _hasAnnotation(declaration, 'wrapper')) {
        // remove @wrapper
        _removeMetadata(result, declaration, (m) => m.name.name == 'wrapper');

        // @forMethods on class
        final forMethodsOnClass = _hasAnnotation(declaration, 'forMethods');
        _removeMetadata(result, declaration, (m) => m.name.name == 'forMethods');

        // @namesWithUnderscores on class
        final namesWithUnderscoresOnClass = _hasAnnotation(declaration, 'namesWithUnderscores');
        _removeMetadata(result, declaration, (m) => m.name.name == 'namesWithUnderscores');

        // @skipWrap on class
        final skipWrap = _hasAnnotation(declaration, 'skipWrap');
        _removeMetadata(result, declaration, (m) => m.name.name == 'skipWrap');

        // @skipConstructor on class
        final skipConstructor = _hasAnnotation(declaration, 'skipConstructor');
        _removeMetadata(result, declaration, (m) => m.name.name == 'skipConstructor');

        // remove @keepAbstract or abstract
        final keepAbstract = _hasAnnotation(declaration, 'keepAbstract');
        if (keepAbstract) {
          _removeMetadata(result, declaration, (m) => m.name.name == 'keepAbstract');
        } else if (declaration.abstractKeyword != null) {
          final abstractKeyword = declaration.abstractKeyword;
          _removeToken(result, abstractKeyword);
        }

        // add cast and constructor
        final name = declaration.name;
        final position = declaration.leftBracket.offset;
        final alreadyExtends = declaration.extendsClause != null;
        result.add(new _Transformation(position, position + 1,
            (alreadyExtends ? '' : 'extends jsw.TypedJsObject ') + '{' +
            (skipWrap || keepAbstract ? '' : '\n  static $name \$wrap(js.JsObject jsObject) => jsObject == null ? null : new $name.fromJsObject(jsObject);') +
            (skipConstructor ? '' : '\n  $name.fromJsObject(js.JsObject jsObject) : super.fromJsObject(jsObject);')
            ));

        // generate constructors
        // generate member
        declaration.members.forEach((m){
          final access = forMethodsOnClass || _hasAnnotation(m, 'forMethods') ? forMethods :
            namesWithUnderscoresOnClass || _hasAnnotation(m, 'namesWithUnderscores') ? namesWithUnderscores : null;
          final generate = _hasAnnotation(m, 'generate');
          _removeMetadata(result, declaration, (m) => m.name.name == 'generate');
          if (m is ConstructorDeclaration && generate) {
            final constr = new StringBuffer();
            constr
              ..write(m.returnType)
              ..write(m.name == null ? '' : '.${m.name}')
              ..write(m.parameters)
              ..write(':');
            if (m.initializers.isNotEmpty) {
              constr.write(m.initializers.where((e) => e is! SuperConstructorInvocation).join(','));
              constr.write(',');
            }
            constr
              ..write("super(${dartConstructorNS != null ? dartConstructorNS : 'js.context'}['${m.returnType}'], [${m.parameters.parameters.map(_handleFormalParameter).join(', ')}])")
              ..write(m.body != null ? m.body : ';');
            result.add(new _Transformation(m.offset, m.end, constr.toString()));
          } else if (m is FieldDeclaration) {
            final content = new StringBuffer();
            final type = m.fields.type;
            final metadatas = m.metadata;
            for (final VariableDeclaration v in m.fields.variables) {
              final name = v.name.name;
              if (name.startsWith('_')) {
                return; // skip fieldDeclaration
              } else {
                _writeSetterForField(content, name, type, metadatas, access: access);
                content.write('\n');
                _writeGetter(content, name, type, metadatas, access: access);
                content.write('\n');
              }
            }
            result.add(new _Transformation(m.offset, m.endToken.next.offset, content.toString()));
          } else if (m is MethodDeclaration && m.name.name == '\$wrap') {
            if (!skipWrap) {
              _removeNode(result, m);
            }
          } else if (m is MethodDeclaration && (m.isAbstract || generate) && !m.isStatic && !m.isOperator && !_hasAnnotation(m, 'keepAbstract')) {
            final method = new StringBuffer();
            if (m.isSetter){
              _writeSetterForSetter(method, m, access: access);
            } else if (m.isGetter) {
              _writeGetter(method, m.name.name, m.returnType, m.metadata, access: access);
            } else {
              if (m.returnType != null) {
                method..write(m.returnType)..write(' ');
              }
              method..write(m.name)..write(m.parameters)..write(_handleReturn("\$unsafe.callMethod('${m.name.name}'" +
                  (m.parameters.parameters.isEmpty ? ")" : ", [${m.parameters.parameters.map(_handleFormalParameter).join(', ')}])"), m.returnType, m.metadata));
            }
            result.add(new _Transformation(m.offset, m.end, method.toString()));
          }
        });
      }
    }
    return result;
  }
}

void _writeSetterForSetter(StringBuffer sb, MethodDeclaration setter, {_PropertyMapping access}) {
  final FormalParameter param = setter.parameters.parameters.first;
  final NodeList<Annotation> metadatas = param is SimpleFormalParameter ? param.metadata : null;
  final Type2 paramType = param.element != null && param.element.type != null ? param.element.type : null;
  final String paramTypeAsString = param is SimpleFormalParameter ? param.type.name.name : '';
  final String paramName = param.identifier.name;
  _writeSetter(sb, setter.name.name, setter.returnType, paramTypeAsString, paramName, _handleParameter(paramName, paramType, metadatas), access: access);
}

void _writeSetterForField(StringBuffer sb, String name, TypeName type, NodeList<Annotation> metadatas, {_PropertyMapping access}) {
  final Type2 paramType = type != null && type.type != null ? type.type : null;
  final String paramTypeAsString = type.toString();
  final String paramName = name;
  _writeSetter(sb, name, null, paramTypeAsString, paramName, _handleParameter(paramName, paramType, metadatas), access: access);
}

void _writeSetter(StringBuffer sb, String name, TypeName returnType, String paramType, String paramName, String value, {_PropertyMapping access}) {
  if (returnType != null) sb.write("${returnType} ");
  sb.write('set ${name}(${paramType} ${paramName})');
  if (access == forMethods) {
    final nameCapitalized = _capitalize(name);
    sb.write(_handleReturn("\$unsafe.callMethod('set${nameCapitalized}', [${value}])", returnType, []));
  } else if (access == namesWithUnderscores) {
    final nameWithUnderscores = _withUnderscores(name);
    sb.write(_handleReturn("\$unsafe['${nameWithUnderscores}'] = ${value}", returnType, []));
  } else {
    sb.write(_handleReturn("\$unsafe['${name}'] = ${value}", returnType, []));
  }
}

void _writeGetter(StringBuffer content, String name, TypeName returnType, NodeList<Annotation> metadatas, {_PropertyMapping access}) {
  if (access == forMethods) {
    final nameCapitalized = _capitalize(name);
    content..write("${returnType} get ${name}${_handleReturn("\$unsafe.callMethod('get${nameCapitalized}')", returnType, metadatas)}");
  } else if (access == namesWithUnderscores) {
    final nameWithUnderscores = _withUnderscores(name);
    content..write("${returnType} get ${name}${_handleReturn("\$unsafe['${nameWithUnderscores}']", returnType, metadatas)}");
  } else {
    content..write("${returnType} get ${name}${_handleReturn("\$unsafe['${name}']", returnType, metadatas)}");
  }
}

String _handleFormalParameter(FormalParameter fp) {
  final Type2 paramType = fp.element != null && fp.element.type != null ? fp.element.type : null;
  if (fp is DefaultFormalParameter) fp = (fp as DefaultFormalParameter).parameter;
  final NodeList<Annotation> annotations = fp is NormalFormalParameter ? fp.metadata : null;
  return _handleParameter(fp.identifier.name, paramType, annotations);
}

String _handleParameter(String name, Type2 type, NodeList<Annotation> metadatas) =>
    type != null ? _mayTransformParameter(name, type, metadatas) : "jsw.jsify($name)";

String _mayTransformParameter(String name, Type2 type, List<Annotation> metadatas, {skipNull: false}) {
  if (_isTypeSerializable(type)) return skipNull ? "$name.\$unsafe" : "$name == null ? null : $name.\$unsafe";
  if (_isTypeTransferable(type)) return name;
  if (_isTypeJsObject(type)) return name;
  final filterTypesMetadata = (Annotation a) => _isElementTypedWith(a.element is ConstructorElement ? a.element.enclosingElement : a.element, _LIBRARY_NAME, 'Types');
  if (metadatas != null && metadatas.any(filterTypesMetadata)) {
    final types = metadatas.firstWhere(filterTypesMetadata);
    final ListLiteral listOfTypes = types.arguments.arguments.first;
    return listOfTypes.elements.map((Identifier e){
      final ClassElement classElement = e.staticElement;
      final value = _mayTransformParameter(name, classElement.type, [], skipNull: true);
      return '$name is $e ? ${(value != null ? value : name)} : ';
    }).join() + ' $name == null ? null : throw "bad type"';
  }
  return "jsw.jsify($name)";
}

String _handleReturn(String content, TypeName returnType, List<Annotation> metadatas) {
  var wrap = (String s) => ' => $s;';
  if (returnType != null) {
    if (_isVoid(returnType)) {
      wrap = (String s) => ' { $s; }';
    } else if (returnType.type.element != null) {
      if (_isTypeTypedWith(returnType.type, 'dart.core', 'List')) {
        // List<?> or List
        if (returnType.typeArguments != null && _isTypeSerializable(returnType.typeArguments.arguments.first.type)) {
          // List<T extends Serializable>
          final genericType = returnType.typeArguments.arguments.first;
          wrap = (String s) => ' => jsw.TypedJsArray.\$wrapSerializables($s, $genericType.\$wrap);';
        } else {
          // List or List<T>
          wrap = (String s) => ' => jsw.TypedJsArray.\$wrap($s);';
        }
      } else if (_isTypeSerializable(returnType.type)) {
        wrap = (String s) => ' => ${returnType}.\$wrap($s);';
      }
    }
    if (returnType.type.element == null || returnType.type.isDynamic) {
      final filterTypesMetadata = (Annotation a) => _isElementTypedWith(a.element is ConstructorElement ? a.element.enclosingElement : a.element, _LIBRARY_NAME, 'Types');
      if (metadatas.any(filterTypesMetadata)) {
        String t = '(v0) => v0';
        int i = 1;
        final types = metadatas.firstWhere(filterTypesMetadata);
        final ListLiteral listOfTypes = types.arguments.arguments.first;
        listOfTypes.elements.reversed.forEach((Identifier e){
          final ClassElement classElement = e.staticElement;
          if (_isTypeAssignableWith(classElement.type, 'js_wrapping', 'IsEnum')) {
            t = '(v${i+1}) => ((v$i) => v$i != null ? v$i : ($t)(v${i+1}))($e.\$wrap(v${i+1}))';
            i += 2;
          } else if (_isTypeAssignableWith(classElement.type, 'js_wrapping', 'TypedJsObject')) {
            t = '(v$i) => $e.isInstance(v$i) ? $e.\$wrap(v$i) : ($t)(v$i)';
            i++;
          } else {
            t = '(v$i) => v$i is $e ? v$i : ($t)(v$i)';
            i++;
          }
        });
        wrap = (String s) => ' => ($t)($s);';
      }
    }
  }
  return wrap(content);
}

/// return [true] if the type is transferable through dart:js (see https://api.dartlang.org/docs/channels/stable/latest/dart_js.html)
bool _isTypeTransferable(Type2 type) {
  final transferables = <String, List<String>>{
    'dart.core': ['num', 'bool', 'String', 'DateTime'],
    'dart.dom.html': ['Blob', 'Event', 'ImageData', 'Node', 'Window'],
    'dart.dom.indexed_db': ['KeyRange'],
    'dart.typed_data': ['TypedData'],
  };
  for (final libraryName in transferables.keys) {
    if (transferables[libraryName].any((className) =>
        _isTypeAssignableWith(type, libraryName, className))) {
      return true;
    }
  }
  return false;
}

bool _isTypeSerializable(Type2 type) => type != null && _isTypeAssignableWith(type, 'js_wrapping', 'Serializable');

bool _isTypeJsObject(Type2 type) => type != null && _isTypeAssignableWith(type, 'dart.js', 'JsObject');

bool _isVoid(TypeName typeName) => typeName.type.name == 'void';

bool _isTypeAssignableWith(Type2 type, String libraryName, String className) =>
    type != null && _isElementAssignableWith(type.element, libraryName, className);

bool _isTypeTypedWith(Type2 type, String libraryName, String className) =>
    type != null && _isElementTypedWith(type.element, libraryName, className);

bool _isElementAssignableWith(Element element, String libraryName, String className) =>
    _isElementTypedWith(element, libraryName, className) ||
    (element is ClassElement && element.allSupertypes.any((supertype) => _isTypeTypedWith(supertype, libraryName, className)));

bool _isElementTypedWith(Element element, String libraryName, String className) =>
    element.library != null && element.library.name == libraryName && element.name == className;

void _removeMetadata(List<_Transformation> transformations, AnnotatedNode n, bool testMetadata(Annotation a)) {
  n.metadata.where(testMetadata).forEach((a){
    _removeNode(transformations, a);
  });
}
void _removeNode(List<_Transformation> transformations, ASTNode n) {
  transformations.add(new _Transformation(n.offset, n.endToken.next.offset, ''));
}
void _removeToken(List<_Transformation> transformations, Token t) {
  transformations.add(new _Transformation(t.offset, t.next.offset, ''));
}

bool _hasAnnotation(Declaration declaration, String name) =>
    declaration.metadata != null &&
    declaration.metadata.any((m) =>
        m.element.library.name == _LIBRARY_NAME &&
        m.element.name == name);

String _applyTransformations(String code, List<_Transformation> transformations) {
  int padding = 0;
  for (final t in transformations) {
    code = code.substring(0, t.begin + padding) + t.replace + code.substring(t.end + padding);
    padding += t.replace.length - (t.end - t.begin);
  }
  return code;
}

String _capitalize(String s) => s.length == 0 ? '' : (s.substring(0, 1).toUpperCase() + s.substring(1));

String _withUnderscores(String s) => s.replaceAllMapped(new RegExp('([A-Z])'), (Match match) => '_' + match[1].toLowerCase());

class _Transformation {
  final int begin;
  final int end;
  final String replace;
  _Transformation(this.begin, this.end, this.replace);
}