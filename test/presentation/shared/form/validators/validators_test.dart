import 'package:flutter_test/flutter_test.dart';
import 'package:outnest/presentation/shared/form/validators/validate_bio.dart';
import 'package:outnest/presentation/shared/form/validators/validate_date_of_birth.dart';
import 'package:outnest/presentation/shared/form/validators/validate_name_surname.dart';
import 'package:outnest/presentation/shared/form/validators/validate_university_mail.dart';
import 'package:outnest/presentation/shared/form/validators/validate_event_name.dart';
import 'package:outnest/presentation/shared/form/validators/validate_group_name.dart';
import 'package:outnest/presentation/shared/form/validators/validate_post_caption.dart';
import 'package:outnest/presentation/shared/form/validators/validate_username.dart';
import '../../../../test_helpers/test_helpers.dart';

void main() {
  group('validateBio', () {
    test('returns null when bio length is within limit', () {
      final result = validateBio('Hello world');

      expect(result, isNull);
    });

    test('returns error when bio exceeds 160 chars', () {
      final longBio = 'a' * 161;

      final result = validateBio(longBio);

      expect(result, 'En fazla 160 karakter olmalı');
    });
  });

  group('validateDateOfBirth', () {
    test('returns error when date is null', () {
      final result = validateDateOfBirth(null);

      expect(result, 'Lütfen doğum tarihinizi seçin');
    });

    test('returns error when user is younger than 18', () {
      final under18 = TestHelpers.dateYearsAgo(17);

      final result = validateDateOfBirth(under18);

      expect(result, "Outnest'e katılmak için 18 yaşını doldurmuş olmalısın");
    });

    test('returns null when user is exactly 18', () {
      final exactly18 = TestHelpers.dateYearsAgo(18);

      final result = validateDateOfBirth(exactly18);

      expect(result, isNull);
    });
  });

  group('validateNameSurname', () {
    test('returns error for null input', () {
      final result = validateNameSurname(null);

      expect(result, 'Ad - Soyad boş olamaz');
    });

    test('returns error for one-word input', () {
      final result = validateNameSurname('Ilke');

      expect(result, 'Lütfen adınızı ve soyadınızı tam giriniz');
    });

    test('returns null for valid full name', () {
      final result = validateNameSurname('Ilke Demirkir');

      expect(result, isNull);
    });
  });

  group('validateUniversityMail', () {
    test('returns error for empty email', () {
      final result = validateUniversityMail('', 'Bogazici University');

      expect(result, 'Mail adresi boş olamaz');
    });

    test('returns error when detected university is null', () {
      final result = validateUniversityMail('name@boun.edu.tr', null);

      expect(result, 'Tanınan bir üniversite maili giriniz');
    });

    test('returns null for valid recognized university mail', () {
      final result = validateUniversityMail(
        'name@boun.edu.tr',
        'Bogazici University',
      );

      expect(result, isNull);
    });
  });

  group('validateUsername', () {
    test('returns error when username is null', () {
      final result = validateUsername(null);

      expect(result, 'Kullanıcı adı boş olamaz');
    });

    test('returns error when username is too short', () {
      final result = validateUsername('ab');

      expect(result, 'En az 3 karakter olmalı');
    });

    test('returns error when username has invalid characters', () {
      final result = validateUsername('Ilke-Demir');

      expect(result, 'Sadece küçük harf, rakam, "." ve "_" kullanabilirsiniz');
    });

    test('returns null for valid username', () {
      final result = validateUsername('ilke.demir_01');

      expect(result, isNull);
    });
  });

  group('validateEventName', () {
    test('returns error for null input', () {
      expect(validateEventName(null), 'Buluşma adı boş olamaz');
    });

    test('returns error for empty input', () {
      expect(validateEventName(''), 'Buluşma adı boş olamaz');
    });

    test('returns error for whitespace-only input', () {
      expect(validateEventName('   '), 'Buluşma adı boş olamaz');
    });

    test('returns error when trimmed length exceeds 128', () {
      final longName = 'a' * 129;
      expect(validateEventName(longName), 'En fazla 128 karakter olmalı');
    });

    test('returns null for valid event name', () {
      expect(validateEventName('Kahve Buluşması'), isNull);
    });

    test('returns null for exactly 128 chars', () {
      expect(validateEventName('a' * 128), isNull);
    });
  });

  group('validateGroupName', () {
    test('returns error for null input', () {
      expect(validateGroupName(null), 'Küme adı boş olamaz');
    });

    test('returns error for empty input', () {
      expect(validateGroupName(''), 'Küme adı boş olamaz');
    });

    test('returns error when trimmed length exceeds 32', () {
      final longName = 'a' * 33;
      expect(validateGroupName(longName), 'En fazla 32 karakter olmalı');
    });

    test('returns null for valid group name', () {
      expect(validateGroupName('Liseden Çocuklar'), isNull);
    });

    test('returns null for exactly 32 chars', () {
      expect(validateGroupName('a' * 32), isNull);
    });
  });

  group('validatePostCaption', () {
    test('returns null for null input', () {
      expect(validatePostCaption(null), isNull);
    });

    test('returns null for empty input', () {
      expect(validatePostCaption(''), isNull);
    });

    test('returns error when trimmed length exceeds 64', () {
      final longCaption = 'a' * 65;
      expect(validatePostCaption(longCaption), 'En fazla 64 karakter olmalı');
    });

    test('returns null for valid caption', () {
      expect(validatePostCaption('Güzel bir gün!'), isNull);
    });

    test('returns null for exactly 64 chars', () {
      expect(validatePostCaption('a' * 64), isNull);
    });
  });
}
