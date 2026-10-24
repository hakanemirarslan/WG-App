/// Folds text for product search (SPEC 7): case-insensitive and
/// umlaut/accent-insensitive, so "Spulmittel" matches "Spülmittel" and
/// "sut" matches "süt" (Turkish ş ğ ı İ fold to s g i i).
String normalizeForSearch(String input) {
  const folds = {
    'a': 'äàáâãå',
    'o': 'öòóôõ',
    'u': 'üùúû',
    'e': 'éèêë',
    'i': 'íìîï',
    'n': 'ñ',
    'c': 'ç',
    's': 'ş',
    'g': 'ğ',
  };
  // 'İ' lower-cases to 'i' plus a combining dot (U+0307), 'ı' is the dotless i.
  var result = input
      .toLowerCase()
      .replaceAll('\u0307', '')
      .replaceAll('ı', 'i')
      .replaceAll('ß', 'ss');
  folds.forEach((plain, accented) {
    for (final char in accented.split('')) {
      result = result.replaceAll(char, plain);
    }
  });
  return result.trim();
}
