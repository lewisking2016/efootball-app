import 'package:cloud_firestore/cloud_firestore.dart';

enum TournamentType { epl, uefa, faCup }

class Tournament {
  final String id;
  final String name;
  final String region;
  final TournamentType type;
  final bool active;
  final DateTime createdAt;

  Tournament({
    required this.id,
    required this.name,
    required this.region,
    required this.type,
    this.active = true,
    required this.createdAt,
  });

  factory Tournament.fromMap(Map<String, dynamic> data, String id) {
    return Tournament(
      id: id,
      name: data['name'] ?? '',
      region: data['region'] ?? '',
      type: data['type'] == 'uefa' ? TournamentType.uefa : TournamentType.epl,
      active: data['active'] ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.parse(data['createdAt'].toString()))
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'region': region,
      'type': type == TournamentType.uefa ? 'uefa' : 'epl',
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
