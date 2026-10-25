/// Input checks for the signup and settings forms. Pure Dart, no Flutter/Supabase.
library;

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

/// A plausible email address: something@domain.tld, no spaces.
/// Whether the mailbox exists is only known once Supabase sends a mail.
bool isValidEmail(String input) => _emailPattern.hasMatch(input.trim());

final _phoneSeparators = RegExp(r'[\s\-()/.]');
final _phonePattern = RegExp(r'^\+[0-9]{8,15}$');

/// A phone number with country code in the stored form (`+491512345678`), or null if
/// [input] is not one. Spaces, dashes, brackets, slashes and dots are dropped and a
/// leading `00` is read as `+`, so "+49 151 234-5678" and "0049 1512345678" both work.
/// 8-15 digits after the `+` (E.164 allows at most 15).
String? normalizePhone(String input) {
  var phone = input.trim().replaceAll(_phoneSeparators, '');
  if (phone.startsWith('00')) phone = '+${phone.substring(2)}';
  return _phonePattern.hasMatch(phone) ? phone : null;
}
