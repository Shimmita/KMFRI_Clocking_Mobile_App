import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_clocking/features/authentication/model/mobile_user.dart';

void main() {
  group('MobileUser', () {
    test('maps the existing backend user response without retaining password', () {
      final user = MobileUser.fromJson({
        '_id': 'user-id',
        'name': 'Example User',
        'email': 'example@kmfri.go.ke',
        'employeeId': 'KMFRI-42',
        'role': 'employee',
        'department': 'Research',
        'station': 'MOMBASA CENTRE',
        'password': 'never-store-this',
      });

      expect(user.id, 'user-id');
      expect(user.accountType, 'Employee');
      expect(user.employeeId, 'KMFRI-42');
      expect(user.toJson(), isNot(contains('password')));
    });

    test('accepts wrapped model identifiers from tolerant API responses', () {
      final user = MobileUser.fromJson({
        'userId': 'user-id',
        'name': 'Example Intern',
        'email': 'intern@kmfri.go.ke',
        'role': 'intern',
      });

      expect(user.id, 'user-id');
      expect(user.accountType, 'Intern');
    });

    test('rejects a sign-in payload without an account identifier', () {
      expect(
        () => MobileUser.fromJson({'name': 'Missing ID'}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
