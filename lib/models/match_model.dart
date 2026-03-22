class Match {
  final String id;
  final String tournamentId;
  final String homeTeamId;
  final String awayTeamId;
  final int? homeScore;
  final int? awayScore;
  final int? homeSubmittedScore;
  final int? awaySubmittedScore;
  final String matchweek;
  final String status; // Pending, Verified, Disputed, FT, Postponed
  final DateTime date;
  final String screenshotBase64;
  final bool aiVerified;
  final int postponedCount;

  Match({
    required this.id,
    required this.tournamentId,
    required this.homeTeamId,
    required this.awayTeamId,
    this.homeScore,
    this.awayScore,
    this.homeSubmittedScore,
    this.awaySubmittedScore,
    required this.matchweek,
    required this.status,
    required this.date,
    this.screenshotBase64 = '',
    this.aiVerified = false,
    this.postponedCount = 0,
  });

  factory Match.fromMap(Map<String, dynamic> data, String documentId) {
    return Match(
      id: documentId,
      tournamentId: data['tournamentId'] ?? '',
      homeTeamId: data['homeTeamId'] ?? '',
      awayTeamId: data['awayTeamId'] ?? '',
      homeScore: data['homeScore'],
      awayScore: data['awayScore'],
      homeSubmittedScore: data['homeSubmittedScore'],
      awaySubmittedScore: data['awaySubmittedScore'],
      matchweek: data['matchweek'] ?? '1',
      status: data['status'] ?? 'Pending',
      date: data['date'] != null ? DateTime.parse(data['date']) : DateTime.now(),
      screenshotBase64: data['screenshotBase64'] ?? '',
      aiVerified: data['aiVerified'] ?? false,
      postponedCount: data['postponedCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tournamentId': tournamentId,
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'homeSubmittedScore': homeSubmittedScore,
      'awaySubmittedScore': awaySubmittedScore,
      'matchweek': matchweek,
      'status': status,
      'date': date.toIso8601String(),
      'screenshotBase64': screenshotBase64,
      'aiVerified': aiVerified,
      'postponedCount': postponedCount,
    };
  }
}
