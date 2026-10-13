import 'mobile_user.dart';

class RememberedAccount {
  const RememberedAccount({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.identifier,
    required this.salt,
    required this.verifier,
    this.deviceId = '',
    this.installationId = '',
    this.userProfile,
    this.authUsername = '',
    this.authIsStaff,
  });

  final String userId;
  final String name;
  final String email;
  final String role;
  final String identifier;
  final String salt;
  final String verifier;
  final String deviceId;
  final String installationId;
  final Map<String, dynamic>? userProfile;
  final String authUsername;
  final bool? authIsStaff;

  bool get usesStaffSignIn {
    if (authIsStaff != null) return authIsStaff!;

    switch (role.trim().toLowerCase()) {
      case 'employee':
      case 'staff':
        return true;
      case 'intern':
      case 'attachee':
      case 'attache':
      case 'attachment':
        return false;
    }

    return identifier.trim().isNotEmpty && !identifier.contains('@');
  }

  factory RememberedAccount.fromJson(Map<String, dynamic> json) =>
      RememberedAccount(
        userId: (json['userId'] ?? json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        role: (json['role'] ?? '').toString(),
        identifier: (json['identifier'] ?? json['staffNumber'] ?? '')
            .toString(),
        salt: (json['salt'] ?? '').toString(),
        verifier: (json['verifier'] ?? '').toString(),
        deviceId: (json['deviceId'] ?? '').toString(),
        installationId: (json['installationId'] ?? '').toString(),
        userProfile: json['userProfile'] is Map
            ? Map<String, dynamic>.from(json['userProfile'] as Map)
            : null,
        authUsername: (json['authUsername'] ?? '').toString(),
        authIsStaff: json['authIsStaff'] is bool
            ? json['authIsStaff'] as bool
            : null,
      );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'email': email,
    'role': role,
    'identifier': identifier,
    'salt': salt,
    'verifier': verifier,
    'deviceId': deviceId,
    'installationId': installationId,
    if (userProfile != null) 'userProfile': userProfile,
    'authUsername': authUsername,
    if (authIsStaff != null) 'authIsStaff': authIsStaff,
  };

  MobileUser toMobileUser() {
    final profile = userProfile;
    if (profile != null && profile.isNotEmpty) {
      return MobileUser.fromStorageJson(profile);
    }
    return MobileUser(
      id: userId,
      name: name,
      email: email,
      role: role,
      employeeId: identifier.contains('@') ? '' : identifier,
    );
  }

  String get label => name.isNotEmpty
      ? name
      : email.isNotEmpty
      ? email
      : userId;
}
