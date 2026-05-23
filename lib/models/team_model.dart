class Team {
  final String id;
  final String tournamentId;
  final String name;
  final String shortName;
  final String logoUrl;
  final String managerId;
  String managerName;
  String? playerId;
  String? playerEmail;

  Team({
    required this.id,
    this.tournamentId = '',
    required this.name,
    required this.shortName,
    required this.logoUrl,
    required this.managerId,
    required this.managerName,
    this.playerId,
    this.playerEmail,
  });

  factory Team.fromMap(Map<String, dynamic> data, String documentId) {
    return Team(
      id: documentId,
      tournamentId: data['tournamentId'] ?? '',
      name: data['name'] ?? '',
      shortName: data['shortName'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      managerId: data['managerId'] ?? '',
      managerName: data['managerName'] ?? 'Unknown',
      playerId: data['playerId'],
      playerEmail: data['playerEmail'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tournamentId': tournamentId,
      'name': name,
      'shortName': shortName,
      'logoUrl': logoUrl,
      'managerId': managerId,
      'managerName': managerName,
      'playerId': playerId,
      'playerEmail': playerEmail,
    };
  }
}
