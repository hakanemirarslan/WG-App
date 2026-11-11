import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/core/router.dart';

void main() {
  group('safeReturnPath', () {
    test('keeps paths inside the app, with their query', () {
      expect(safeReturnPath('/join/abc123def456'), '/join/abc123def456');
      expect(safeReturnPath('/group/g1/expenses'), '/group/g1/expenses');
      expect(safeReturnPath('/home?tab=1'), '/home?tab=1');
    });

    test('falls back to /home without a value', () {
      expect(safeReturnPath(null), '/home');
      expect(safeReturnPath(''), '/home');
    });

    test('rejects other sites in every spelling', () {
      expect(safeReturnPath('https://evil.example'), '/home');
      expect(safeReturnPath('//evil.example/join/x'), '/home');
      expect(safeReturnPath(r'/\evil.example'), '/home');
      expect(safeReturnPath('javascript:alert(1)'), '/home');
      expect(safeReturnPath('evil.example'), '/home');
    });

    test('does not return to the login or signup page (no loop)', () {
      expect(safeReturnPath('/login'), '/home');
      expect(safeReturnPath('/signup?from=/join/x'), '/home');
    });
  });
}
