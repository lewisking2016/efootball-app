class StandingsEntry {
  final int position;
  final int previousPosition;
  final String teamId;
  final String tournamentId;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;
  final List<String> form; // e.g., ['W', 'D', 'L', 'W', 'W']

  StandingsEntry({
    required this.position,
    this.previousPosition = 0,
    required this.teamId,
    required this.tournamentId,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
    required this.form,
  });

  factory StandingsEntry.fromMap(Map<String, dynamic> data, String documentId) {
    return StandingsEntry(
      position: data['position'] ?? 0,
      previousPosition: data['previousPosition'] ?? (data['position'] ?? 0),
      teamId: data['teamId'] ?? '',
      tournamentId: data['tournamentId'] ?? '',
      played: data['played'] ?? 0,
      won: data['won'] ?? 0,
      drawn: data['drawn'] ?? 0,
      lost: data['lost'] ?? 0,
      goalsFor: data['goalsFor'] ?? 0,
      goalsAgainst: data['goalsAgainst'] ?? 0,
      goalDifference: data['goalDifference'] ?? 0,
      points: data['points'] ?? 0,
      form: List<String>.from(data['form'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'position': position,
      'previousPosition': previousPosition,
      'teamId': teamId,
      'tournamentId': tournamentId,
      'played': played,
      'won': won,
      'drawn': drawn,
      'lost': lost,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
      'goalDifference': goalDifference,
      'points': points,
      'form': form,
    };
  }
}
