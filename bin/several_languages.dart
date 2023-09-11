import 'dart:io';

import 'package:process_run/process_run.dart';

const outputDefault = './assets/l10n';
final shell = Shell();

void main(List<String> args) {
  List<String> languages = [];
  for (var arg in args) {
    if (arg.startsWith('languages=')) {
      for (var itemLang in args) {
        if (itemLang.startsWith('languages=')) {
          var splLanguages = itemLang.split('=');
          languages = splLanguages[1].split(',');
        }
      }
      _build(languages);
    } else {
      _build(languages == [] ? null : languages);
    }
  }
  if (args.isEmpty) {
    _build(languages == [] ? null : languages);
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

void updateMaterialApp(List<String>? languages) async {
  // update material app
  final materialAppFile = File('./lib/main.dart');
  final lines = await materialAppFile.readAsLines();

  bool isHasFlutterLocalizations = false;
  bool isHasAppLocalizations = false;

  int? indexStartMaterial;
  int? indexEndMaterial;
  int openParenthesisMaterial = 0;
  int closedParenthesisMaterial = 0;
  RegExp regexOpenParenthesisMaterial = RegExp(r"\(", multiLine: false);
  RegExp regexClosedParenthesisMaterial = RegExp(r"\)", multiLine: false);

  bool isLocalizationsDelegates = false;
  int? indexStartLocalizationsDelegates;
  int? indexEndLocalizationsDelegates;
  int openParenthesisLocalizationsDelegates = 0;
  int closedParenthesisLocalizationsDelegates = 0;
  RegExp regexOpenParenthesisLocalizationsDelegates =
      RegExp(r"\[", multiLine: false);
  RegExp regexClosedParenthesisLocalizationsDelegates =
      RegExp(r"\]", multiLine: false);

  bool isSupportedLocales = false;
  int? indexStartSupportedLocales;
  int? indexEndSupportedLocales;
  int openParenthesisSupportedLocales = 0;
  int closedParenthesisSupportedLocales = 0;
  RegExp regexOpenParenthesisSupportedLocales = RegExp(r"\[", multiLine: false);
  RegExp regexClosedParenthesisSupportedLocales =
      RegExp(r"\]", multiLine: false);

  bool isLocale = false;
  int? indexLocale;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

    // checked add dependency
    if (!isHasFlutterLocalizations &&
        line.contains(
            'import \'package:flutter_localizations/flutter_localizations.dart\';')) {
      isHasFlutterLocalizations = true;
    }
    if (!isHasAppLocalizations &&
        line.contains(
            'import \'package:flutter_gen/gen_l10n/app_localizations.dart\';')) {
      isHasAppLocalizations = true;
    }

    /// Find the beginning and end of material
    if (line.contains('MaterialApp')) {
      for (int j = i; j < lines.length; j++) {
        if (regexOpenParenthesisMaterial.hasMatch(lines[j])) {
          indexStartMaterial ??= j;
          ++openParenthesisMaterial;
          print("open : $openParenthesisMaterial");
        }
        if (regexClosedParenthesisMaterial.hasMatch(lines[j])) {
          ++closedParenthesisMaterial;
          print("close : $closedParenthesisMaterial");
          if (openParenthesisMaterial != 0 &&
              openParenthesisMaterial == closedParenthesisMaterial) {
            indexEndMaterial = j;
            break;
          }
        }
      }

      // Checking whether it is locale or not
      if (indexEndMaterial != null) {
        for (int k = i; k < indexEndMaterial; k++) {
          if (lines[k].contains('locale:')) {
            isLocale = true;
            indexLocale ??= k;
          }
        }
      }
      // Checking whether it is supportedLocales or not
      if (indexEndMaterial != null) {
        for (int k = i; k < indexEndMaterial; k++) {
          if (lines[k].contains('supportedLocales:')) {
            // There are supportedLocales:
            isSupportedLocales = true;
            // First, last, the supporte
            //
            // dLocales: delegate parameter: be specified
            for (int j = k; j < indexEndMaterial; j++) {
              if (regexOpenParenthesisSupportedLocales.hasMatch(lines[j])) {
                indexStartSupportedLocales ??= j;
                ++openParenthesisSupportedLocales;
                print(
                    "open s : $openParenthesisSupportedLocales , line : ${lines[j]}");
              }
              if (regexClosedParenthesisSupportedLocales.hasMatch(lines[j])) {
                ++closedParenthesisSupportedLocales;
                print("close s : $closedParenthesisSupportedLocales");
                if (openParenthesisSupportedLocales != 0 &&
                    openParenthesisSupportedLocales ==
                        closedParenthesisSupportedLocales) {
                  indexEndSupportedLocales = j;
                  break;
                }
              }
            }
          }
        }
      }
      // Checking whether it is localizationsDelegates or not
      if (indexEndMaterial != null) {
        for (int k = i; k < indexEndMaterial; k++) {
          if (lines[k].contains('localizationsDelegates:')) {
            // There are LocalizationsDelegates
            isLocalizationsDelegates = true;
            // First, last, the localization delegate parameter: be specified
            for (int j = k; j < indexEndMaterial; j++) {
              if (regexOpenParenthesisLocalizationsDelegates
                  .hasMatch(lines[j])) {
                indexStartLocalizationsDelegates ??= j;
                ++openParenthesisLocalizationsDelegates;
                print(
                    "open s : $openParenthesisLocalizationsDelegates , line : ${lines[j]}");
              }
              if (regexClosedParenthesisLocalizationsDelegates
                  .hasMatch(lines[j])) {
                ++closedParenthesisLocalizationsDelegates;
                print("close s : $closedParenthesisLocalizationsDelegates");
                if (openParenthesisLocalizationsDelegates != 0 &&
                    openParenthesisLocalizationsDelegates ==
                        closedParenthesisLocalizationsDelegates) {
                  indexEndLocalizationsDelegates = j;
                  break;
                }
              }
            }
          }
        }
      }

      print(
          "if : ${(openParenthesisMaterial != 0 && openParenthesisMaterial == closedParenthesisMaterial)}");
      print("start : $indexStartMaterial , end : $indexEndMaterial , i : $i");
    }
  }

  // todo log info
  print(
      'isLocalizationsDelegates = $isLocalizationsDelegates , start : $indexStartLocalizationsDelegates, end : $indexEndLocalizationsDelegates');
  print(
      'isSupportedLocales = $isSupportedLocales , index start : $indexStartSupportedLocales , index end : $indexEndSupportedLocales');
  print('isLocale = $isLocale , index : $indexLocale');

  // add dependency
  if (!isHasFlutterLocalizations) {
    lines[0] =
        'import \'package:flutter_localizations/flutter_localizations.dart\';\n${lines[0]}';
  }

  if (!isHasAppLocalizations) {
    lines[0] =
        'import \'package:flutter_gen/gen_l10n/app_localizations.dart\';\n${lines[0]}';
  }

  if (indexStartMaterial != null) {
    // lines[indexStartMaterial] = "// :) \n ${lines[indexStartMaterial]}";

    // add SupportedLocales:
    if (!isLocalizationsDelegates) {
      lines[indexStartMaterial] =
          '${lines[indexStartMaterial]}\n\t\t\tlocalizationsDelegates: const [\n\t\t\t\tAppLocalizations.delegate, \n\t\t\t\tGlobalMaterialLocalizations.delegate,\n\t\t\t\tGlobalWidgetsLocalizations.delegate,\n\t\t\t\tGlobalCupertinoLocalizations.delegate,\n\t\t\t],';
    }
    // add SupportedLocales:
    if (!isSupportedLocales) {
      if (languages == null || (languages.length ?? 0) < 1) {
        lines[indexStartMaterial] =
            '${lines[indexStartMaterial]}\n\t\t\tsupportedLocales: const [\n\t\t\t\tLocale(\'en\'), // English\n\t\t\t],';
      } else {
        String listLocal = '';
        for (var language in languages) {
          listLocal += ('\n\t\t\t\tLocale(\'$language\'), ');
        }
        lines[indexStartMaterial] =
            '${lines[indexStartMaterial]}\n\t\t\tsupportedLocales: const [$listLocal \n\t\t\t],';
      }
    }
    // create folder
    final l10nDirectory = Directory('./lib/l10n');
    if (!await l10nDirectory.exists()) {
      await l10nDirectory.create(recursive: true);
    }
    // add .arb file
// تعداد زبان‌ها
    int numLanguages = languages?.length ?? 0;

    // اگر هیچ زبانی مشخص نشده یا تعداد زبان‌ها صفر باشد، یک فایل .arb برای پیشفرض ایجاد کنید
    if (numLanguages == 0) {
      final defaultFile = File('./lib/l10n/app_en.arb');
      await defaultFile.writeAsString("""
{
  "helloWorld": "Hello World!",
  "@helloWorld": {
    "description": "The conventional newborn programmer greeting"
  }
}""");
    } else {
      // برای هر زبان در لیست زبان‌ها، یک فایل .arb ایجاد کنید
      for (var language in languages!) {
        final languageFile = File('./lib/l10n/app_$language.arb');
        await languageFile.writeAsString("""
{
  "helloWorld": "Hello World!",
  "@helloWorld": {
    "description": "The conventional newborn programmer greeting"
  }
}""");
      }
    } // add locale:
    if (!isLocale) {
      if (languages == null || (languages.length ?? 0) < 1) {
        lines[indexStartMaterial] =
            '${lines[indexStartMaterial]}\n\t\t\tlocale: const Locale(\'en\'),';
      } else {
        lines[indexStartMaterial] =
            '${lines[indexStartMaterial]}\n\t\t\tlocale: const Locale(\'${languages[0]}\'),';
      }
    }
  }

  /// update main.dart
  await materialAppFile.writeAsString(lines.join('\n'));
}
