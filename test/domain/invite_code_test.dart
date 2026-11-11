import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/domain/invite_code.dart';

void main() {
  group('extractInviteCode', () {
    test('accepts a bare code, trimmed and lower-cased', () {
      expect(extractInviteCode('938e0ebec723'), '938e0ebec723');
      expect(extractInviteCode('  938E0EBEC723 '), '938e0ebec723');
      expect(extractInviteCode('abcdef1234'), 'abcdef1234'); // older 10-char codes
    });

    test('takes the code out of a pasted link or path', () {
      expect(extractInviteCode('http://localhost:5000/join/938e0ebec723'), '938e0ebec723');
      expect(extractInviteCode('https://wg.example/join/938e0ebec723/'), '938e0ebec723');
      expect(extractInviteCode('https://wg.example/join/938e0ebec723?x=1#top'), '938e0ebec723');
      expect(extractInviteCode('/join/938e0ebec723'), '938e0ebec723');
    });

    test('rejects empty input and things that are not a code', () {
      expect(extractInviteCode(''), isNull);
      expect(extractInviteCode('   '), isNull);
      expect(extractInviteCode('https://wg.example/home'), isNull);
      expect(extractInviteCode('hello world'), isNull);
      expect(extractInviteCode('/join/'), isNull);
      expect(extractInviteCode('../join/x'), isNull);
    });
  });
}
