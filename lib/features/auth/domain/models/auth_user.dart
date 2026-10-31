/// Basic authenticated user model
class AuthUser {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String? displayName;
  final bool isAnonymous;

  const AuthUser({
    required this.uid,
    this.email,
    this.phoneNumber,
    this.displayName,
    this.isAnonymous = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}
