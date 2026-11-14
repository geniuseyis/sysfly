import 'package:flutter/widgets.dart';

import '../../data/generated/country_names.dart';
import 'translations.dart';

/// Languages the app can be shown in. English is the source language.
enum AppLanguage {
  en('English', 'English'),
  tr('Türkçe', 'Turkish'),
  de('Deutsch', 'German'),
  fr('Français', 'French'),
  es('Español', 'Spanish'),
  ru('Русский', 'Russian'),
  ar('العربية', 'Arabic');

  const AppLanguage(this.nativeName, this.englishName);

  /// The language's own name.
  final String nativeName;

  /// Its English name. Shown translated into the selected language, so the
  /// picker reads "Turkish" in English and "Türkisch" in German.
  final String englishName;

  String get code => name;
}

/// Translates the app's English text into the selected language.
///
/// Screens are written in English. Text is translated when it is drawn, so a
/// string assembled from parts ("Departs in 10h 35m", "Fri, 4 Sep · Economy")
/// is handled as a whole:
///
///  1. an exact entry in [kTranslations];
///  2. a template from [kTemplates], whose placeholders are translated in turn;
///  3. splitting on separators (" · ", " → ", line breaks);
///  4. dates and month or weekday names.
///
/// Anything unmatched (names, codes, amounts) is shown as it is.
abstract final class L10n {
  static AppLanguage _language = AppLanguage.en;
  static AppLanguage get language => _language;

  static final Map<String, String> _cache = {};

  static void use(AppLanguage language) {
    if (language == _language) return;
    _language = language;
    _cache.clear();
  }

  /// Set by tests to learn which strings had no translation.
  static void Function(String text)? debugUntranslated;

  static bool get isRtl => _language == AppLanguage.ar;

  /// Column of [kTranslations] for the current language.
  static int get _column => _language.index - 1;

  /// Localized name of the country with ISO code [code].
  static String country(String code) => kCountryNames[code]?[_language.index] ?? code;

  static String translate(String text) {
    if (_language == AppLanguage.en || text.isEmpty) return text;
    final cached = _cache[text];
    if (cached != null) return cached;
    final result = _translate(text, 0);
    if (identical(result, text)) debugUntranslated?.call(text);
    return _cache[text] = result;
  }

  // ---- Engine ----------------------------------------------------------

  static Map<String, List<String>>? _lowercase;
  static List<_Template>? _templates;

  static String? _exact(String text) {
    final direct = kTranslations[text];
    if (direct != null) return direct[_column].isEmpty ? text : direct[_column];

    final names = _CalendarNames.of(_language);
    final named = names.lookup(text);
    if (named != null) return named;

    // "BOARDING PASS" uses the entry for "Boarding pass".
    if (text == text.toUpperCase() && text != text.toLowerCase()) {
      final index = _lowercase ??= {for (final e in kTranslations.entries) e.key.toLowerCase(): e.value};
      final found = index[text.toLowerCase()];
      if (found != null && found[_column].isNotEmpty) return _upper(found[_column]);
      final upper = names.lookup(text[0] + text.substring(1).toLowerCase());
      if (upper != null) return _upper(upper);
    }
    return null;
  }

  /// Upper case that keeps the Turkish dotted and dotless i apart.
  static String _upper(String text) => _language == AppLanguage.tr
      ? text.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase()
      : text.toUpperCase();

  static String _translate(String text, int depth) {
    final exact = _exact(text);
    if (exact != null) return exact;
    if (depth > 6) return text;

    final templates = _templates ??= [
      for (final e in kTemplates.entries) _Template(e.key, e.value),
    ]..sort((a, b) => b.weight.compareTo(a.weight));
    for (final template in templates) {
      final match = template.pattern.firstMatch(text);
      if (match != null) return template.fill(match, _column, _language, (part) => _translate(part, depth + 1));
    }

    for (final separator in const ['\n', ' · ', '  ·  ', ' → ', '  →  ']) {
      if (text.contains(separator)) {
        return text.split(separator).map((part) => _translate(part, depth + 1)).join(separator);
      }
    }
    return _CalendarNames.of(_language).localizeDates(text);
  }
}

/// Shorthand for [L10n.translate].
String tr(String text) => L10n.translate(text);

/// A [Text] that shows [data] in the selected language.
class TrText extends StatelessWidget {
  const TrText(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
    this.textScaler,
  });

  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool? softWrap;
  final TextScaler? textScaler;

  static final RegExp _arabic = RegExp(r'[؀-ۿ]');

  @override
  Widget build(BuildContext context) {
    final text = tr(data);
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      softWrap: softWrap,
      textScaler: textScaler,
      // The layout stays left-to-right; Arabic runs still read right-to-left.
      textDirection: L10n.isRtl && _arabic.hasMatch(text) ? TextDirection.rtl : null,
    );
  }
}

/// Rebuilds every widget below [context]. Called after the language changes
/// so text computed anywhere in the tree is produced again.
void rebuildAllBelow(BuildContext context) {
  void visit(Element element) {
    element.markNeedsBuild();
    element.visitChildren(visit);
  }

  (context as Element).visitChildren(visit);
}

class _Template {
  _Template(String key, this.values) : pattern = _compile(key), weight = key.replaceAll(RegExp(r'\{\d#?\}'), '').length;

  final RegExp pattern;
  final List<String> values;

  /// Amount of literal text; more specific templates are tried first.
  final int weight;

  /// `{0}` matches anything, `{0#}` matches a number.
  static RegExp _compile(String key) {
    final out = StringBuffer('^');
    var last = 0;
    for (final m in RegExp(r'\{\d(#?)\}').allMatches(key)) {
      out
        ..write(RegExp.escape(key.substring(last, m.start)))
        ..write(m.group(1)!.isEmpty ? '(.+?)' : r'(\d[\d,.]*)');
      last = m.end;
    }
    out
      ..write(RegExp.escape(key.substring(last)))
      ..write(r'$');
    return RegExp(out.toString(), dotAll: true);
  }

  /// Fills the translated template. `{0}` inserts a translated placeholder;
  /// `{0:one|other}` or `{0:one|few|many}` picks a word by that number.
  String fill(RegExpMatch match, int column, AppLanguage language, String Function(String) translate) {
    final value = values[column].isEmpty ? null : values[column];
    if (value == null) return match.group(0)!;
    return value.replaceAllMapped(RegExp(r'\{(\d)(?::([^}]*))?\}'), (m) {
      final group = match.group(int.parse(m.group(1)!) + 1) ?? '';
      final forms = m.group(2)?.split('|');
      if (forms == null) return translate(group);
      final n = int.tryParse(group.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      if (forms.length == 3) {
        // Russian: 1 билет, 2 билета, 5 билетов.
        final mod10 = n % 10, mod100 = n % 100;
        if (mod10 == 1 && mod100 != 11) return forms[0];
        if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return forms[1];
        return forms[2];
      }
      return n == 1 ? forms.first : forms.last;
    });
  }
}

/// Weekday and month names, and the date patterns built from them.
class _CalendarNames {
  _CalendarNames(this.weekdays, this.months, this.monthsLong);

  final List<String> weekdays;
  final List<String> months;
  final List<String> monthsLong;

  static const _enWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _enMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _enMonthsLong = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', //
  ];

  static final Map<AppLanguage, _CalendarNames> _all = {
    AppLanguage.tr: _CalendarNames(
      ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'],
      ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'],
      ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'],
    ),
    AppLanguage.de: _CalendarNames(
      ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'],
      ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'],
      ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'],
    ),
    AppLanguage.fr: _CalendarNames(
      ['lun', 'mar', 'mer', 'jeu', 'ven', 'sam', 'dim'],
      ['janv', 'févr', 'mars', 'avr', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc'],
      ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'],
    ),
    AppLanguage.es: _CalendarNames(
      ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'],
      ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept', 'oct', 'nov', 'dic'],
      ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'],
    ),
    AppLanguage.ru: _CalendarNames(
      ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'],
      ['янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'],
      ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'],
    ),
    AppLanguage.ar: _CalendarNames(
      ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'],
      ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'],
      ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'],
    ),
  };

  static final _CalendarNames _english = _CalendarNames(_enWeekdays, _enMonths, _enMonthsLong);

  static _CalendarNames of(AppLanguage language) => _all[language] ?? _english;

  /// A weekday or month name on its own.
  String? lookup(String text) {
    var i = _enWeekdays.indexOf(text);
    if (i >= 0) return weekdays[i];
    i = _enMonthsLong.indexOf(text);
    if (i >= 0 && text != 'May') return monthsLong[i];
    i = _enMonths.indexOf(text);
    if (i >= 0) return months[i];
    return null;
  }

  static final String _wd = _enWeekdays.join('|');
  static final String _mo = _enMonths.join('|');
  static final RegExp _weekdayDate = RegExp('\\b($_wd),? (\\d{1,2}) ($_mo)\\b', caseSensitive: false);
  static final RegExp _dayMonth = RegExp('\\b(\\d{1,2}) ($_mo)\\b', caseSensitive: false);
  static final RegExp _monthYear = RegExp('\\b(${_enMonthsLong.join('|')}) (\\d{4})\\b');

  String _case(String source, String target) => source == source.toUpperCase() ? target.toUpperCase() : target;

  int _index(List<String> names, String value) => names.indexWhere((n) => n.toLowerCase() == value.toLowerCase());

  /// Rewrites "Fri, 4 Sep", "4 Sep" and "September 2026" inside [text].
  String localizeDates(String text) {
    if (identical(this, _english)) return text;
    var out = text.replaceAllMapped(_monthYear, (m) => '${monthsLong[_enMonthsLong.indexOf(m.group(1)!)]} ${m.group(2)}');
    out = out.replaceAllMapped(_weekdayDate, (m) {
      final comma = m.group(0)!.contains(',') ? ',' : '';
      final weekday = _case(m.group(1)!, weekdays[_index(_enWeekdays, m.group(1)!)]);
      final month = _case(m.group(3)!, months[_index(_enMonths, m.group(3)!)]);
      return '$weekday$comma ${m.group(2)} $month';
    });
    out = out.replaceAllMapped(_dayMonth, (m) => '${m.group(1)} ${_case(m.group(2)!, months[_index(_enMonths, m.group(2)!)])}');
    return out;
  }
}
