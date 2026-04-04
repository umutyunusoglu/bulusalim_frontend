import 'package:flutter_test/flutter_test.dart';
import 'package:outnest/presentation/shared/form/sanitizer.dart';

void main() {
  group('sanitizeInput', () {
    test('trims whitespace', () {
      expect(sanitizeInput('  hello  '), 'hello');
    });

    test('removes control characters', () {
      expect(sanitizeInput('hello\x00world'), 'helloworld');
      expect(sanitizeInput('test\x08value'), 'testvalue');
      expect(sanitizeInput('a\x0Bb\x0Cc'), 'abc');
    });

    test('preserves tabs and newlines', () {
      expect(sanitizeInput('hello\tworld'), 'hello\tworld');
      expect(sanitizeInput('hello\nworld'), 'hello\nworld');
    });

    test('preserves special characters without encoding', () {
      expect(sanitizeInput('Tom & Jerry'), 'Tom & Jerry');
      expect(
        sanitizeInput('<script>alert("xss")</script>'),
        '<script>alert("xss")</script>',
      );
      expect(sanitizeInput("it's a test"), "it's a test");
    });

    test('returns empty string for whitespace-only input', () {
      expect(sanitizeInput('   '), '');
    });
  });

  group('sanitizeUrl', () {
    test('trims whitespace', () {
      expect(sanitizeUrl('  https://example.com  '), 'https://example.com');
    });

    test('allows http URLs', () {
      expect(sanitizeUrl('http://example.com'), 'http://example.com');
    });

    test('allows https URLs', () {
      expect(sanitizeUrl('https://example.com/path?q=1&b=2'),
          'https://example.com/path?q=1&b=2');
    });

    test('blocks javascript scheme', () {
      expect(sanitizeUrl('javascript:alert(1)'), isNull);
    });

    test('blocks data scheme', () {
      expect(sanitizeUrl('data:text/html,<h1>hi</h1>'), isNull);
    });

    test('blocks vbscript scheme', () {
      expect(sanitizeUrl('vbscript:msgbox("hi")'), isNull);
    });

    test('blocks ftp scheme', () {
      expect(sanitizeUrl('ftp://files.example.com'), isNull);
    });

    test('allows empty string', () {
      expect(sanitizeUrl(''), '');
    });

    test('allows relative URL without scheme', () {
      expect(sanitizeUrl('example.com/path'), 'example.com/path');
    });

    test('removes control characters from URL', () {
      expect(sanitizeUrl('https://example\x00.com'), 'https://example.com');
    });
  });

  group('sanitizeEmail', () {
    test('trims and lowercases', () {
      expect(sanitizeEmail('  Test@Uni.EDU.TR  '), 'test@uni.edu.tr');
    });

    test('removes angle brackets', () {
      expect(sanitizeEmail('<user@uni.edu.tr>'), 'user@uni.edu.tr');
    });

    test('removes spaces', () {
      expect(sanitizeEmail('user @uni.edu.tr'), 'user@uni.edu.tr');
    });

    test('removes control characters', () {
      expect(sanitizeEmail('user\x00@uni.edu.tr'), 'user@uni.edu.tr');
    });

    test('preserves valid email characters', () {
      expect(sanitizeEmail('user.name+tag@uni.edu.tr'),
          'user.name+tag@uni.edu.tr');
    });
  });

  group('sanitizeUsername', () {
    test('trims and lowercases', () {
      expect(sanitizeUsername('  TestUser  '), 'testuser');
    });

    test('strips disallowed characters', () {
      expect(sanitizeUsername('user<script>'), 'userscript');
      expect(sanitizeUsername('user@name!'), 'username');
    });

    test('preserves dots and underscores', () {
      expect(sanitizeUsername('user.name_01'), 'user.name_01');
    });

    test('removes control characters', () {
      expect(sanitizeUsername('user\x00name'), 'username');
    });
  });

  group('sanitizeName', () {
    test('trims whitespace', () {
      expect(sanitizeName('  Ali Veli  '), 'Ali Veli');
    });

    test('preserves Turkish characters', () {
      expect(sanitizeName('Güneş Öztürk'), 'Güneş Öztürk');
    });

    test('preserves apostrophes and hyphens', () {
      expect(sanitizeName("O'Brien"), "O'Brien");
      expect(sanitizeName('Jean-Pierre'), 'Jean-Pierre');
    });

    test('strips disallowed characters', () {
      expect(sanitizeName('Ali<script>'), 'Aliscript');
      expect(sanitizeName('Ali123'), 'Ali');
    });

    test('removes control characters', () {
      expect(sanitizeName('Ali\x00 Veli'), 'Ali Veli');
    });
  });

  group('sanitizePhone', () {
    test('strips non-digit characters', () {
      expect(sanitizePhone('+90 532 123 45 67'), '905321234567');
    });

    test('returns empty for non-digit input', () {
      expect(sanitizePhone('abc'), '');
    });

    test('preserves digits only', () {
      expect(sanitizePhone('5321234567'), '5321234567');
    });
  });
}
