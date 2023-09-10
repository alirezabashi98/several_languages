import 'dart:io';

import 'package:process_run/process_run.dart';

const outputDefault = './assets/l10n';
final shell = Shell();

void main(List<String> args) {
  List<String> splLanguages = [];
  for (var arg in args) {
    if (arg.startsWith('languages=')) {
      for (var itemLang in args) {
        if (itemLang.startsWith('languages=')) {
          var splLanguages = itemLang.split('=');
          print('spl = $splLanguages');
          splLanguages.addAll(splLanguages[1].split(','));
          print('splList = ${splLanguages[1].split(',')}');
          break;
        }
      }
      _build(splLanguages);
    } else {
      _build([]);
    }
  }
}

void _build(List<String>? languages) async {
  // add dependency
  // shell.run(
  //     'flutter pub add flutter_localizations --sdk=flutter && flutter pub add intl:any');

  // update pubspec.yaml
  final pubspecFile = File('./pubspec.yaml');
  final lines = await pubspecFile.readAsLines();
  final updatedLines = _updatePubspec(lines);
  await pubspecFile.writeAsString(updatedLines.join('\n'));

  // add l10n.yaml
  _createL10nYaml();

  // update material app
  updateMaterialApp(languages);
}

List<String> _updatePubspec(List<String> lines) {
  String previousLine = '';
  int previousIndex = 0;
  int howManyFlutter = 0;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

    if (previousIndex < i) {
      previousLine = lines[i];
      previousIndex++;
    }

    // Check if we are inside the "flutter" section
    if (line.trim().startsWith('generate:')) {
      lines[i] = '  generate: true';
      break;
    } else if (previousLine != 'dependencies:' &&
        line.trim() == 'flutter:' &&
        howManyFlutter > 0) {
      for (int j = i; j < lines.length; j++) {
        final line = lines[j];
        if (line.trim().startsWith('generate:')) {
          lines[i] = 'flutter:';
          lines[j] = '  generate: true';
          break;
        }
      }
    } else if (line.trim() == 'flutter:') {
      ++howManyFlutter;
    }
  }

  return lines;
}

void _createL10nYaml() async {
  var text = """
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
  """;
  final pubspecFile = File('./l10n.yaml');
  await pubspecFile.writeAsString(text);
}

void updateMaterialApp(List<String>? languages) async{
  // update material app
  final materialAppFile = File('./lib/main.dart');
  final lines = await materialAppFile.readAsLines();
  await materialAppFile.writeAsString(lines.join('\n'));

  bool isLocalizationsDelegates = false;
  int indexStartLocalizationsDelegates;

  bool isSupportedLocales = false;
  bool isLocale = false;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

// todo
//     if(i == 0){
//       lines[i] = """
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'flan';
// $line
//       """;
//     }

    if (line.contains('MaterialApp(')) {
      for (int j = 0; j < lines.length; j++) {
        final line = lines[j];
        final pattern = RegExp('supportedLocales:');

        for (var j in pattern.allMatches(line)) {
          print(j);
        }

        if (pattern.allMatches(line).isNotEmpty) {
          isLocalizationsDelegates = true;
          indexStartLocalizationsDelegates = i;
        }
      }
      // todo
      print('isLocalizationsDelegates = $isLocalizationsDelegates');
      print('isSupportedLocales = $isSupportedLocales');
      print('isLocale = $isLocale');
    }
  }
}
