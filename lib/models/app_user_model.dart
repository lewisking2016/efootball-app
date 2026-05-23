class AppUser {
  final String uid;
  final String email;
  final bool isAdmin;
  final String? teamId;

  AppUser({
    required this.uid,
    required this.email,
    this.isAdmin = false,
    this.teamId,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String documentId) {
    return AppUser(
      uid: documentId,
      email: data['email'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      teamId: data['teamId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'email': email, 'isAdmin': isAdmin, 'teamId': teamId};
  }
}
