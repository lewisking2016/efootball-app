class Match {
  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final int homeScore;
  final int awayScore;
  final String matchweek;
  final String status; // Pending, Verified, Disputed, FT
  final DateTime date;
  final String screenshotBase64;
  final bool aiVerified;

  Match({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeScore,
    required this.awayScore,
    required this.matchweek,
    required this.status,
    required this.date,
    this.screenshotBase64 = '',
    this.aiVerified = false,
  });

  factory Match.fromMap(Map<String, dynamic> data, String documentId) {
    return Match(
      id: documentId,
      homeTeamId: data['homeTeamId'] ?? '',
      awayTeamId: data['awayTeamId'] ?? '',
      homeScore: data['homeScore'] ?? 0,
      awayScore: data['awayScore'] ?? 0,
      matchweek: data['matchweek'] ?? '1',
      status: data['status'] ?? 'Pending',
      date: data['date'] != null ? DateTime.parse(data['date']) : DateTime.now(),
      screenshotBase64: data['screenshotBase64'] ?? '',
      aiVerified: data['aiVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'matchweek': matchweek,
      'status': status,
      'date': date.toIso8601String(),
      'screenshotBase64': screenshotBase64,
      'aiVerified': aiVerified,
    };
  }
}
