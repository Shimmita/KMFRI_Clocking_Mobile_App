import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_clocking/features/authentication/model/mobile_user.dart';
import 'package:mobile_app_clocking/features/authentication/model/remembered_account.dart';

void main() {
  group('RememberedAccount', () {
    test('restores the cached user and device enrollment metadata', () {
      const user = MobileUser(
        id: 'user-id',
        name: 'Example User',
        email: 'user@kmfri.go.ke',
        role: 'employee',
        employeeId: 'KMFRI-42',
        department: 'Research',
      );
      final account = RememberedAccount(
        userId: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        identifier: user.employeeId,
        salt: 'salt',
        verifier: 'verifier',
        deviceId: 'device-id',
        installationId: 'installation-id',
        userProfile: user.toJson(),
        authUsername: 'KMFRI-42',
        authIsStaff: true,
      );

      final restored = RememberedAccount.fromJson(account.toJson());

      expect(restored.deviceId, 'device-id');
      expect(restored.installationId, 'installation-id');
      expect(restored.authUsername, 'KMFRI-42');
      expect(restored.authIsStaff, isTrue);
      expect(restored.toMobileUser().toJson(), user.toJson());
      expect(restored.toJson(), isNot(contains('password')));
    });

    test('supports older remembered accounts without cached profile', () {
      final account = RememberedAccount.fromJson({
        'userId': 'user-id',
        'name': 'Example User',
        'email': 'user@kmfri.go.ke',
        'role': 'employee',
        'identifier': 'KMFRI-42',
        'salt': 'salt',
        'verifier': 'verifier',
      });

      final user = account.toMobileUser();

      expect(user.id, 'user-id');
      expect(user.name, 'Example User');
      expect(user.employeeId, 'KMFRI-42');
    });

    test('routes remembered accounts using backend account roles', () {
      RememberedAccount accountWithRole(String role) => RememberedAccount(
        userId: 'user-id',
        name: 'Example User',
        email: 'user@kmfri.go.ke',
        role: role,
        identifier: 'user@kmfri.go.ke',
        salt: 'salt',
        verifier: 'verifier',
      );

      expect(accountWithRole('employee').usesStaffSignIn, isTrue);
      expect(accountWithRole('intern').usesStaffSignIn, isFalse);
      expect(accountWithRole('attachee').usesStaffSignIn, isFalse);
      expect(accountWithRole('attache').usesStaffSignIn, isFalse);
    });

    test(
      'routes legacy accounts from identifiers when role is unavailable',
      () {
        RememberedAccount legacyAccount(String identifier) => RememberedAccount(
          userId: 'user-id',
          name: 'Example User',
          email: 'user@kmfri.go.ke',
          role: '',
          identifier: identifier,
          salt: 'salt',
          verifier: 'verifier',
        );

        expect(legacyAccount('user@kmfri.go.ke').usesStaffSignIn, isFalse);
        expect(legacyAccount('KMFRI-42').usesStaffSignIn, isTrue);
      },
    );
  });
}
