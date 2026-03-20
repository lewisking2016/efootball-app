class Team {
  final String id;
  final String name;
  final String shortName;
  final String logoUrl;
  final String managerId;
  final String managerName;

  Team({
    required this.id,
    required this.name,
    required this.shortName,
    required this.logoUrl,
    required this.managerId,
    required this.managerName,
  });

  factory Team.fromMap(Map<String, dynamic> data, String documentId) {
    return Team(
      id: documentId,
      name: data['name'] ?? '',
      shortName: data['shortName'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      managerId: data['managerId'] ?? '',
      managerName: data['managerName'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'shortName': shortName,
      'logoUrl': logoUrl,
      'managerId': managerId,
      'managerName': managerName,
    };
  }
}
