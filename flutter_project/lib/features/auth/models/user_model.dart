enum MemberStatus { gold, silver, bronze }

class UserModel {
  final String uid;
  final String phone;
  final String name;
  final MemberStatus memberStatus;
  final int points;
  final bool isAdmin;
  final DateTime createdAt;
  final bool isDeleted;

  UserModel({
    required this.uid,
    required this.phone,
    required this.name,
    this.memberStatus = MemberStatus.bronze,
    this.points = 0,
    this.isAdmin = false,
    required this.createdAt,
    this.isDeleted = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    MemberStatus status = MemberStatus.bronze;
    if (map['memberStatus'] != null) {
      switch (map['memberStatus'].toString().toLowerCase()) {
        case 'gold':
          status = MemberStatus.gold;
          break;
        case 'silver':
          status = MemberStatus.silver;
          break;
        default:
          status = MemberStatus.bronze;
      }
    }

    return UserModel(
      uid: id,
      phone: map['phone'] ?? '',
      name: map['name'] ?? '',
      memberStatus: status,
      points: (map['points'] as num?)?.toInt() ?? 0,
      isAdmin: map['isAdmin'] as bool? ?? false,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone': phone,
      'name': name,
      'memberStatus': memberStatus.name.toUpperCase(),
      'points': points,
      'isAdmin': isAdmin,
      'createdAt': createdAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }
}
