import 'package:intl/intl.dart';

/// Upper bound from SPEC 2: a single expense is at most 100.000,00 EUR.
const int maxAmountCents = 100000 * 100;

final _amountPattern = RegExp(r'^\d+([.,]\d{1,2})?$');

String formatCents(int cents, {required String locale}) {
  final fullLocale = locale == 'de' ? 'de_DE' : 'en_US';
  final format = NumberFormat.currency(locale: fullLocale, symbol: '€');
  return format.format(cents / 100);
}

/// Plain amount for text fields, without currency symbol or grouping
/// ("3,34" in German, "3.34" in English), so [parseToCents] reads it back.
String formatCentsPlain(int cents, {required String locale}) {
  final separator = locale == 'de' ? ',' : '.';
  return '${cents ~/ 100}$separator${(cents % 100).toString().padLeft(2, '0')}';
}

/// Digits of "23,5" / "23.50" / "23" as cents, 0 allowed; null if malformed.
int? _parseNonNegativeCents(String trimmed) {
  if (!_amountPattern.hasMatch(trimmed)) return null;

  final separatorIndex = trimmed.indexOf(RegExp(r'[.,]'));
  final String integerPart;
  final String fractionPart;
  if (separatorIndex == -1) {
    integerPart = trimmed;
    fractionPart = '00';
  } else {
    integerPart = trimmed.substring(0, separatorIndex);
    fractionPart = trimmed.substring(separatorIndex + 1).padRight(2, '0');
  }
  return int.parse(integerPart) * 100 + int.parse(fractionPart);
}

/// Parses user input like "23,5", "23.50" or "23" into cents.
/// Returns null for anything invalid: wrong format, more than 2 decimals,
/// zero/negative, or above [maxAmountCents].
int? parseToCents(String input) {
  final cents = _parseNonNegativeCents(input.trim());
  if (cents == null || cents <= 0 || cents > maxAmountCents) return null;
  return cents;
}

/// Like [parseToCents] but for one person's share in "amount" split mode:
/// an empty field or zero is a valid share of 0 cents.
int? parseShareCents(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return 0;
  final cents = _parseNonNegativeCents(trimmed);
  if (cents == null || cents > maxAmountCents) return null;
  return cents;
}
