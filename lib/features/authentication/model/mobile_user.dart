class MobileUser {
  const MobileUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.rank = 'user',
    this.employeeId = '',
    this.department = '',
    this.station = '',
    this.isAccountActive,
    this.isOnLeave = false,
    this.canClockOutside = false,
    this.outsideClockingReason = '',
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String rank;
  final String employeeId;
  final String department;
  final String station;
  final bool? isAccountActive;
  final bool isOnLeave;
  final bool canClockOutside;
  final String outsideClockingReason;

  factory MobileUser.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['userId'] ?? json['id'] ?? '').toString();
    if (id.isEmpty) {
      throw const FormatException('The sign-in response did not include a user ID.');
    }

    final outsideDetails = json['outsideClockingDetails'];
    String reason = '';
    if (outsideDetails is Map<String, dynamic>) {
      reason = (outsideDetails['reason'] ?? '').toString();
    } else {
      reason = (json['outsideClockingReason'] ?? '').toString();
    }

    return MobileUser(
      id: id,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      rank: (json['rank'] ?? json['userRole'] ?? 'user').toString(),
      employeeId: (json['employeeId'] ?? '').toString(),
      department: (json['department'] ?? '').toString(),
      station: (json['station'] ?? '').toString(),
      isAccountActive: json['isAccountActive'] is bool
          ? json['isAccountActive'] as bool
          : null,
      isOnLeave: json['isOnLeave'] == true,
      canClockOutside: json['canClockOutside'] == true,
      outsideClockingReason: reason,
    );
  }

  factory MobileUser.fromStorageJson(Map<String, dynamic> json) =>
      MobileUser.fromJson(json);

  Map<String, dynamic> toJson() => {
    'userId': id,
    'name': name,
    'email': email,
    'role': role,
    'rank': rank,
    'employeeId': employeeId,
    'department': department,
    'station': station,
    'isAccountActive': isAccountActive,
    'isOnLeave': isOnLeave,
    'canClockOutside': canClockOutside,
    'outsideClockingDetails': {
      'reason': outsideClockingReason,
    },
  };

  String get accountType {
    switch (role.toLowerCase()) {
      case 'employee':
      case 'staff':
        return 'Employee';
      case 'intern':
        return 'Intern';
      case 'attachee':
      case 'attachment':
        return 'Attaché';
      default:
        return role.isEmpty ? 'Employee' : role;
    }
  }

  String get rankLabel {
    switch (rank.toLowerCase()) {
      case 'superadmin':
        return 'Superadmin';
      case 'hr':
        return 'HR';
      case 'auditor':
        return 'Auditor';
      case 'supervisor':
        return 'Supervisor';
      case 'admin':
        return 'Admin';
      default:
        return 'User';
    }
  }
}
