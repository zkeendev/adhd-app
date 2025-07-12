import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  static const String collectionName = 'users';
  static const String fcmTokensField = 'fcmTokens';

  final String uid;
  final String? email;
  final String? displayName;
  final Timestamp? createdAt;
  final List<String>? fcmTokens;

  UserProfile({
    required this.uid,
    this.email,
    this.displayName,
    this.createdAt,
    this.fcmTokens,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      fcmTokensField: fcmTokens ?? [],
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      createdAt: json['createdAt'] as Timestamp?,
      fcmTokens: json[fcmTokensField] != null
          ? List<String>.from(json[fcmTokensField] as List)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.uid == uid &&
        other.email == email &&
        other.displayName == displayName &&
        other.createdAt == createdAt &&
        other.fcmTokens == fcmTokens;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        email.hashCode ^
        displayName.hashCode ^
        createdAt.hashCode ^
        fcmTokens.hashCode;
  }

  @override
  String toString() {
    return 'UserProfile(uid: $uid, email: $email, displayName: $displayName, createdAt: $createdAt)';
  }
}