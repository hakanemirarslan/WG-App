/// Folds text for product search (SPEC 7): case-insensitive and
/// umlaut/accent-insensitive, so "Spulmittel" matches "Spülmittel".
String normalizeForSearch(String input) {
  const folds = {
    'a': 'äàáâãå',
    'o': 'öòóôõ',
    'u': 'üùúû',
    'e': 'éèêë',
    'i': 'íìîï',
    'n': 'ñ',
    'c': 'ç',
  };
  var result = input.toLowerCase().replaceAll('ß', 'ss');
  folds.forEach((plain, accented) {
    for (final char in accented.split('')) {
      result = result.replaceAll(char, plain);
    }
  });
  return result.trim();
}
