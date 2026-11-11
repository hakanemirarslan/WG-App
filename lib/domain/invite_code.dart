/// The invite code from whatever the user pasted into "Join with code": the bare
/// code, `/join/<code>`, or the whole invite link (with any host, `?` or `#` after
/// it). Null when nothing usable is in there.
String? extractInviteCode(String input) {
  final text = input.trim();
  if (text.isEmpty) return null;
  // Last `/join/<code>` wins; a code never contains a slash.
  final link = RegExp(r'/join/([^/?#\s]+)').allMatches(text).lastOrNull;
  final candidate = link?.group(1) ?? text;
  final code = candidate.trim();
  // Codes are hex (12 chars today, 10 before); refuse anything that is clearly not one.
  return RegExp(r'^[0-9a-fA-F]{6,64}$').hasMatch(code) ? code.toLowerCase() : null;
}
