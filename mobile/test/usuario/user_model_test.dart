import 'package:flutter_test/flutter_test.dart';
import 'package:scam_detection/packages/usuario/models/user_model.dart';

void main() {
  group('UserModel', () {
    final json = {
      'id': 'u-1',
      'email': 'ana@example.com',
      'username': 'ana',
      'is_active': true,
      'created_at': '2026-06-22T10:05:00Z',
    };

    test('fromJson mapea todos los campos', () {
      final user = UserModel.fromJson(json);
      expect(user.id, 'u-1');
      expect(user.email, 'ana@example.com');
      expect(user.username, 'ana');
      expect(user.isActive, isTrue);
      expect(user.createdAt, DateTime.parse('2026-06-22T10:05:00Z'));
    });

    test('toJson es el inverso de fromJson (roundtrip)', () {
      final user = UserModel.fromJson(json);
      final out = user.toJson();
      expect(out['id'], 'u-1');
      expect(out['email'], 'ana@example.com');
      expect(out['is_active'], true);
      // El roundtrip preserva los datos al re-parsear.
      final reparsed = UserModel.fromJson(out);
      expect(reparsed.email, user.email);
      expect(reparsed.createdAt, user.createdAt);
    });
  });

  group('AuthTokenModel', () {
    test('fromJson anida el usuario y los tokens', () {
      final token = AuthTokenModel.fromJson({
        'access_token': 'acc',
        'refresh_token': 'ref',
        'token_type': 'bearer',
        'user': {
          'id': 'u-2',
          'email': 'b@example.com',
          'username': 'b',
          'is_active': true,
          'created_at': '2026-01-01T00:00:00Z',
        },
      });
      expect(token.accessToken, 'acc');
      expect(token.refreshToken, 'ref');
      expect(token.tokenType, 'bearer');
      expect(token.user.username, 'b');
    });
  });
}
