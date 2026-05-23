import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/team_model.dart';
import '../models/match_model.dart';
import '../models/standings_model.dart';
import '../models/tournament_model.dart';
import '../models/app_user_model.dart';
import 'mock_data.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<StandingsEntry> _standingsCache = const [];
  List<Match> _matchesCache = const [];
  List<Team> _teamsCache = const [];
  List<Tournament> _tournamentsCache = const [];

  late final Stream<List<StandingsEntry>> _standingsStream = _db
      .collection('standings')
      .orderBy('position')
      .snapshots(includeMetadataChanges: true)
      .map((snapshot) {
        _standingsCache = snapshot.docs
            .map((doc) => StandingsEntry.fromMap(doc.data(), doc.id))
            .toList();
        return _standingsCache;
      })
      .handleError((Object error) {
        debugPrint('Standings stream error: $error');
      })
      .asBroadcastStream();

  late final Stream<List<Match>> _matchesStream = _db
      .collection('matches')
      .orderBy('date')
      .snapshots(includeMetadataChanges: true)
      .map((snapshot) {
        _matchesCache = snapshot.docs
            .map((doc) => Match.fromMap(doc.data(), doc.id))
            .toList();
        return _matchesCache;
      })
      .handleError((Object error) {
        debugPrint('Matches stream error: $error');
      })
      .asBroadcastStream();

  late final Stream<List<Team>> _teamsStream = _db
      .collection('teams')
      .snapshots(includeMetadataChanges: true)
      .map((snapshot) {
        _teamsCache = snapshot.docs
            .map((doc) => Team.fromMap(doc.data(), doc.id))
            .toList();
        return _teamsCache;
      })
      .handleError((Object error) {
        debugPrint('Teams stream error: $error');
      })
      .asBroadcastStream();

  late final Stream<List<Tournament>> _tournamentsStream = _db
      .collection('tournaments')
      .snapshots(includeMetadataChanges: true)
      .map((snapshot) {
        _tournamentsCache = snapshot.docs
            .map((doc) => Tournament.fromMap(doc.data(), doc.id))
            .toList();
        return _tournamentsCache;
      })
      .handleError((Object error) {
        debugPrint('Tournaments stream error: $error');
      })
      .asBroadcastStream();

  // -- Streams -- //

  Stream<List<StandingsEntry>> getStandings() {
    return _standingsStream;
  }

  Stream<List<Match>> getMatches() {
    return _matchesStream;
  }

  Stream<List<Team>> getTeams() {
    return _teamsStream;
  }

  Stream<List<Tournament>> getTournaments() {
    return _tournamentsStream;
  }

  List<StandingsEntry> get cachedStandings =>
      List.unmodifiable(_standingsCache);
  List<Match> get cachedMatches => List.unmodifiable(_matchesCache);
  List<Team> get cachedTeams => List.unmodifiable(_teamsCache);
  List<Tournament> get cachedTournaments =>
      List.unmodifiable(_tournamentsCache);
  // For background tasks (Free alternative to Cloud Functions)
  Future<List<Match>> getTeamMatchesTodaySync(String uid) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) return [];
      final teamId = userDoc.data()?['teamId'];
      if (teamId == null) return [];

      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      // Query matches where team plays and date starts with today
      final homeQuery = await _db
          .collection('matches')
          .where('homeTeamId', isEqualTo: teamId)
          .where('status', isEqualTo: 'Pending')
          .get();

      final awayQuery = await _db
          .collection('matches')
          .where('awayTeamId', isEqualTo: teamId)
          .where('status', isEqualTo: 'Pending')
          .get();

      List<Match> all = [
        ...homeQuery.docs.map((d) => Match.fromMap(d.data(), d.id)),
        ...awayQuery.docs.map((d) => Match.fromMap(d.data(), d.id)),
      ];

      return all
          .where((m) => m.date.toIso8601String().startsWith(todayStr))
          .toList();
    } catch (e) {
      debugPrint("Sync Error: $e");
      return [];
    }
  }

  Stream<List<Match>> getTeamMatchesToday(String teamId) {
    final now = DateTime.now();
    final todayStr = DateTime(
      now.year,
      now.month,
      now.day,
    ).toIso8601String().split('T')[0];

    return _db
        .collection('matches')
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Match.fromMap(doc.data(), doc.id))
              .where((m) {
                final mDateStr = m.date.toIso8601String().split('T')[0];
                return mDateStr == todayStr &&
                    (m.homeTeamId == teamId || m.awayTeamId == teamId);
              })
              .toList();
        });
  }

  // Helper method to fetch a team directly (for UI joining)
  Future<Team?> getTeamById(String teamId) async {
    final doc = await _db.collection('teams').doc(teamId).get();
    if (doc.exists) {
      return Team.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // -- Updating Standings Engine -- //

  bool _isFinalMatchStatus(String status) =>
      status == 'FT' || status == 'Finished';

  Future<void> updateStandings(
    String tournamentId,
    String homeTeamId,
    String awayTeamId,
    int homeScore,
    int awayScore, {
    int? oldHomeScore,
    int? oldAwayScore,
  }) async {
    await _rebuildStandings(tournamentId);
  }

  Future<void> _rebuildStandings(String tournamentId) async {
    final standingsSnapshot = await _db
        .collection('standings')
        .where('tournamentId', isEqualTo: tournamentId)
        .get();
    final teamsSnapshot = await _db
        .collection('teams')
        .where('tournamentId', isEqualTo: tournamentId)
        .get();
    final matchesSnapshot = await _db
        .collection('matches')
        .where('tournamentId', isEqualTo: tournamentId)
        .get();

    final previousPositions = {
      for (final doc in standingsSnapshot.docs)
        doc.data()['teamId'] as String: (doc.data()['position'] as int?) ?? 0,
    };

    final statsByTeam = <String, _StandingsAccumulator>{
      for (final doc in teamsSnapshot.docs)
        doc.id: _StandingsAccumulator(teamId: doc.id),
    };

    final finalMatches =
        matchesSnapshot.docs
            .map((doc) => Match.fromMap(doc.data(), doc.id))
            .where(
              (match) =>
                  _isFinalMatchStatus(match.status) &&
                  match.homeScore != null &&
                  match.awayScore != null,
            )
            .toList()
          ..sort((a, b) {
            final byDate = a.date.compareTo(b.date);
            if (byDate != 0) return byDate;
            return a.id.compareTo(b.id);
          });

    for (final match in finalMatches) {
      final homeStats = statsByTeam.putIfAbsent(
        match.homeTeamId,
        () => _StandingsAccumulator(teamId: match.homeTeamId),
      );
      final awayStats = statsByTeam.putIfAbsent(
        match.awayTeamId,
        () => _StandingsAccumulator(teamId: match.awayTeamId),
      );

      homeStats.applyMatch(match.homeScore!, match.awayScore!);
      awayStats.applyMatch(match.awayScore!, match.homeScore!);
    }

    final rankedEntries = statsByTeam.values.toList()
      ..sort((a, b) {
        if (b.points != a.points) return b.points.compareTo(a.points);
        if (b.goalDifference != a.goalDifference) {
          return b.goalDifference.compareTo(a.goalDifference);
        }
        if (b.goalsFor != a.goalsFor) return b.goalsFor.compareTo(a.goalsFor);
        return a.teamId.compareTo(b.teamId);
      });

    final batch = _db.batch();
    for (int i = 0; i < rankedEntries.length; i++) {
      final entry = rankedEntries[i];
      final newPosition = i + 1;
      final previousPosition = previousPositions[entry.teamId] ?? 0;
      batch.set(
        _db.collection('standings').doc('${tournamentId}_${entry.teamId}'),
        {
          'teamId': entry.teamId,
          'tournamentId': tournamentId,
          'position': newPosition,
          'previousPosition': previousPosition,
          'played': entry.played,
          'won': entry.won,
          'drawn': entry.drawn,
          'lost': entry.lost,
          'goalsFor': entry.goalsFor,
          'goalsAgainst': entry.goalsAgainst,
          'goalDifference': entry.goalDifference,
          'points': entry.points,
          'form': entry.form,
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  // -- User Roles & Access Control -- //

  bool _isLocalAdmin(String uid) {
    final user = _auth.currentUser;
    return user?.uid == uid && user?.email?.toLowerCase() == 'admin@admin.com';
  }

  Future<void> createOrUpdateUser(
    String uid,
    String email, [
    String? displayName,
    bool? isAdmin,
  ]) async {
    final docRefs = _db.collection('users').doc(uid);
    final data = <String, dynamic>{
      'email': email,
      'displayName': displayName ?? email.split('@')[0],
      'lastSeenAt': FieldValue.serverTimestamp(),
    };

    if (isAdmin != null || _isLocalAdmin(uid)) {
      data['isAdmin'] = isAdmin ?? true;
    }

    try {
      await docRefs.set({...data}, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      debugPrint('User profile write failed: ${e.code} ${e.message}');
      if (e.code != 'permission-denied') rethrow;
    }
  }

  Future<AppUser?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (_isLocalAdmin(uid)) {
          data['isAdmin'] = true;
        }
        return AppUser.fromMap(data, doc.id);
      }
    } on FirebaseException catch (e) {
      debugPrint('User profile read failed: ${e.code} ${e.message}');
      if (e.code != 'permission-denied') rethrow;
    }
    if (_isLocalAdmin(uid)) {
      return AppUser(
        uid: uid,
        email: _auth.currentUser?.email ?? 'admin@admin.com',
        isAdmin: true,
      );
    }
    return null;
  }

  Future<bool> isAdmin(String uid) async {
    if (_isLocalAdmin(uid)) return true;
    final user = await getUserProfile(uid);
    return user?.isAdmin ?? false;
  }

  Future<void> claimTeam(String uid, String teamId, String email) async {
    await _db.runTransaction((transaction) async {
      final userRef = _db.collection('users').doc(uid);
      final teamRef = _db.collection('teams').doc(teamId);
      final userDoc = await transaction.get(userRef);
      final teamDoc = await transaction.get(teamRef);

      if (!teamDoc.exists) {
        throw Exception("This team no longer exists.");
      }

      final existingOwner = teamDoc.data()?['playerId'];
      if (existingOwner != null &&
          existingOwner.toString().isNotEmpty &&
          existingOwner != uid) {
        throw Exception("This team has already been claimed.");
      }

      final currentTeamId = userDoc.data()?['teamId'];
      if (currentTeamId != null &&
          currentTeamId.toString().isNotEmpty &&
          currentTeamId != teamId) {
        throw Exception("Your account is already linked to another team.");
      }

      transaction.set(userRef, {
        'teamId': teamId,
        'email': email,
      }, SetOptions(merge: true));
      transaction.update(teamRef, {'playerId': uid, 'playerEmail': email});
    });
  }

  Future<void> handleDelayedMatches() async {
    final now = DateTime.now();
    // 24-hour grace period (1 full day) after the match date before it's "delayed"
    final graceTime = now.subtract(const Duration(hours: 24));

    try {
      final snapshot = await _db
          .collection('matches')
          .where('status', isEqualTo: 'Pending')
          .get();

      for (var doc in snapshot.docs) {
        final match = Match.fromMap(doc.data(), doc.id);

        if (match.date.isBefore(graceTime)) {
          final newDate = await _findNextDoubleHeaderDate(match, now);

          await doc.reference.update({
            'date': newDate.toIso8601String(),
            'postponedCount': match.postponedCount + 1,
            'postponedFrom': match.date.toIso8601String(),
            'resolutionReason': 'postponed_to_next_team_matchday',
          });
          debugPrint(
            "AUTOMATION: Match ${match.id} postponed to ${newDate.toIso8601String()}",
          );
        }
      }
    } catch (e) {
      debugPrint("Error in handleDelayedMatches: $e");
    }
  }

  Future<DateTime> _findNextDoubleHeaderDate(
    Match delayedMatch,
    DateTime now,
  ) async {
    final snapshot = await _db
        .collection('matches')
        .where('tournamentId', isEqualTo: delayedMatch.tournamentId)
        .where('status', isEqualTo: 'Pending')
        .get();

    final upcomingTeamMatches =
        snapshot.docs
            .where((doc) => doc.id != delayedMatch.id)
            .map((doc) => Match.fromMap(doc.data(), doc.id))
            .where(
              (match) =>
                  match.date.isAfter(now) &&
                  (match.homeTeamId == delayedMatch.homeTeamId ||
                      match.awayTeamId == delayedMatch.homeTeamId ||
                      match.homeTeamId == delayedMatch.awayTeamId ||
                      match.awayTeamId == delayedMatch.awayTeamId),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    if (upcomingTeamMatches.isNotEmpty) {
      return upcomingTeamMatches.first.date;
    }

    return _nextPlayDateAfter(now);
  }

  // -- Seeding Initial Data -- //

  Future<void> seedInitialDatabase() async {
    debugPrint("Synching high-fidelity data into Firestore...");

    // 0. WIPE COLLECTIONS for 100% accurate state
    Future<void> clearCollection(String name) async {
      final snapshots = await _db.collection(name).get();
      for (var doc in snapshots.docs) {
        await doc.reference.delete();
      }
    }

    await clearCollection('teams');
    await clearCollection('standings');
    await clearCollection('matches');
    await clearCollection('tournaments');

    debugPrint("Database wiped. Seeding fresh 2025/26 Season data...");

    // 1. Create a default Tournament
    const tournamentId = 'tournament_king_2025';
    await _db.collection('tournaments').doc(tournamentId).set({
      'name': 'KING LEAGUE 2025',
      'region': 'Global',
      'type': 'epl',
      'createdAt': DateTime.now().toIso8601String(),
    });

    for (var i = 0; i < MockData.standings.length; i++) {
      final teamData = MockData.standings[i];
      final teamId = 'team_$i';

      await _db.collection('teams').doc(teamId).set({
        'name': teamData['name'],
        'tournamentId': tournamentId,
        'shortName': teamData['name'].toString().substring(0, 3).toUpperCase(),
        'logoUrl': teamData['logo'],
        'managerId': 'system',
        'managerName': teamData['manager'] ?? 'Unknown',
      });

      await _db.collection('standings').doc('${tournamentId}_$teamId').set({
        'teamId': teamId,
        'tournamentId': tournamentId,
        'position': teamData['pos'],
        'played': teamData['pl'],
        'won': teamData['w'],
        'drawn': teamData['d'],
        'lost': teamData['l'],
        'goalsFor': teamData['gf'],
        'goalsAgainst': teamData['ga'],
        'goalDifference': teamData['gd'],
        'points': teamData['pts'],
        'form': teamData['form'],
      });
    }

    // 2. Generate initial matches
    for (var i = 0; i < MockData.standings.length; i += 2) {
      if (i + 1 < MockData.standings.length) {
        await _db.collection('matches').doc('match_1_$i').set({
          'tournamentId': tournamentId,
          'homeTeamId': 'team_$i',
          'awayTeamId': 'team_${i + 1}',
          'matchweek': '1',
          'status': 'Pending',
          'date': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        });
      }
    }

    // Also ensure the admin user exists with admin rights
    await _db.collection('users').doc('admin_user_id').set({
      'email': 'admin@admin.com',
      'isAdmin': true,
      'displayName': 'Global Admin',
      'teamId': null,
    }, SetOptions(merge: true));

    debugPrint("Data sync complete!");
  }

  Future<String> createNewTournament(
    Tournament tournament,
    List<Team> teams,
  ) async {
    final batch = _db.batch();

    // 1. Create Tournament Document
    final tournamentRef = _db.collection('tournaments').doc();
    batch.set(tournamentRef, tournament.toMap());

    // 2. Create Teams and initial Standings
    List<String> teamIds = [];
    for (var team in teams) {
      final teamRef = _db.collection('teams').doc();
      final teamData = team.toMap();
      teamData['tournamentId'] = tournamentRef.id;
      batch.set(teamRef, teamData);
      teamIds.add(teamRef.id);

      final standingsRef = _db
          .collection('standings')
          .doc('${tournamentRef.id}_${teamRef.id}');
      batch.set(standingsRef, {
        'teamId': teamRef.id,
        'tournamentId': tournamentRef.id,
        'position': 0,
        'played': 0,
        'won': 0,
        'drawn': 0,
        'lost': 0,
        'goalsFor': 0,
        'goalsAgainst': 0,
        'goalDifference': 0,
        'points': 0,
        'form': [],
      });
    }

    // 3. Generate Fixtures: double round robin over 4 months, 4 play days per week.
    final fixtures = _generateDoubleRoundRobin(teamIds);
    final playDates = _generateFourMonthPlayDates(tournament.createdAt);
    final matchesPerDate = (fixtures.length / playDates.length).ceil().clamp(
      1,
      10,
    );
    var fixtureIndex = 0;

    for (
      var dateIndex = 0;
      dateIndex < playDates.length && fixtureIndex < fixtures.length;
      dateIndex++
    ) {
      final playDate = playDates[dateIndex];
      final matchweek = (dateIndex + 1).toString();

      for (
        var slot = 0;
        slot < matchesPerDate && fixtureIndex < fixtures.length;
        slot++
      ) {
        final fixture = fixtures[fixtureIndex++];
        final matchRef = _db.collection('matches').doc();

        batch.set(matchRef, {
          'tournamentId': tournamentRef.id,
          'homeTeamId': fixture.homeTeamId,
          'awayTeamId': fixture.awayTeamId,
          'matchweek': matchweek,
          'status': 'Pending',
          'date': playDate.toIso8601String(),
          'postponedCount': 0,
          'autoResolved': false,
          'resolutionReason': null,
        });
      }
    }

    await batch.commit();
    return tournamentRef.id;
  }

  Future<void> joinTournament(String tournamentId, Team team) async {
    final batch = _db.batch();

    // 1. Create Team Document
    final teamRef = _db.collection('teams').doc();
    final teamData = team.toMap();
    teamData['tournamentId'] = tournamentId;
    batch.set(teamRef, teamData);

    // 2. Create initial standings entry for this team in this tournament
    final standingsRef = _db.collection('standings').doc(teamRef.id);
    batch.set(standingsRef, {
      'teamId': teamRef.id,
      'tournamentId': tournamentId,
      'position': 0,
      'played': 0,
      'won': 0,
      'drawn': 0,
      'lost': 0,
      'goalsFor': 0,
      'goalsAgainst': 0,
      'goalDifference': 0,
      'points': 0,
      'form': [],
    });

    await batch.commit();
  }

  Future<List<String>> getUsedLogos(String tournamentId) async {
    final snapshot = await _db
        .collection('teams')
        .where('tournamentId', isEqualTo: tournamentId)
        .get();

    return snapshot.docs.map((doc) => doc.data()['logoUrl'] as String).toList();
  }

  Future<void> submitMatchResult({
    String? matchId,
    required String tournamentId,
    required String homeTeamId,
    required String awayTeamId,
    required int homeScore,
    required int awayScore,
    required bool isAdmin,
  }) async {
    // 1. If matchId exists, fetch it to check status and old scores
    Match? existingMatch;
    if (matchId != null) {
      final doc = await _db.collection('matches').doc(matchId).get();
      if (doc.exists) {
        existingMatch = Match.fromMap(doc.data()!, doc.id);
      }
    }

    // 2. Update or Create Match. Rules and UI restrict normal users to their own team.
    final targetMatchId = matchId ?? _db.collection('matches').doc().id;
    await _db.collection('matches').doc(targetMatchId).set({
      'tournamentId': tournamentId,
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'status': 'FT',
      'date':
          existingMatch?.date.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'matchweek': existingMatch?.matchweek ?? 'Manual',
      'autoResolved': false,
      'resolutionReason': null,
    }, SetOptions(merge: true));

    // 3. Update Standings
    final oldHomeScore = existingMatch?.homeScore;
    final oldAwayScore = existingMatch?.awayScore;
    try {
      await updateStandings(
        tournamentId,
        homeTeamId,
        awayTeamId,
        homeScore,
        awayScore,
        oldHomeScore: oldHomeScore,
        oldAwayScore: oldAwayScore,
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'Standings update failed after saving result: ${e.code} ${e.message}',
      );
      if (e.code != 'permission-denied') rethrow;
    }
  }

  Future<void> updateMatchStatus(
    String matchId,
    String status, [
    int? homeScore,
    int? awayScore,
  ]) async {
    final data = <String, dynamic>{'status': status};
    if (homeScore != null) data['homeScore'] = homeScore;
    if (awayScore != null) data['awayScore'] = awayScore;

    await _db.collection('matches').doc(matchId).update(data);
  }

  Future<void> deleteTournament(String tournamentId) async {
    final batch = _db.batch();

    // 1. Delete Tournament Document
    batch.delete(_db.collection('tournaments').doc(tournamentId));

    // 2. Delete all matches for this tournament
    final matches = await _db
        .collection('matches')
        .where('tournamentId', isEqualTo: tournamentId)
        .get();
    for (var doc in matches.docs) {
      batch.delete(doc.reference);
    }

    // 3. Delete all standings for this tournament
    final standings = await _db
        .collection('standings')
        .where('tournamentId', isEqualTo: tournamentId)
        .get();
    for (var doc in standings.docs) {
      batch.delete(doc.reference);
    }

    // 4. Delete all teams for this tournament
    final teams = await _db
        .collection('teams')
        .where('tournamentId', isEqualTo: tournamentId)
        .get();
    for (var doc in teams.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<void> wipeAllData() async {
    final collections = ['teams', 'standings', 'matches', 'tournaments'];
    for (final name in collections) {
      final snapshots = await _db.collection(name).get();
      for (final doc in snapshots.docs) {
        await doc.reference.delete();
      }
    }
    debugPrint("DATABASE WIPE: All league data cleared.");
  }

  Future<void> deleteUserAccount(String uid) async {
    try {
      final userRef = _db.collection('users').doc(uid);
      final userDoc = await userRef.get();

      if (userDoc.exists) {
        final teamId = userDoc.data()?['teamId'];

        // 2. If user had a team, release it
        if (teamId != null && teamId.toString().trim().isNotEmpty) {
          try {
            final teamRef = _db.collection('teams').doc(teamId.toString());
            final teamSnap = await teamRef.get();
            if (teamSnap.exists) {
              await teamRef.update({'playerId': null, 'playerEmail': null});
            }
          } catch (e) {
            debugPrint("Non-critical error releasing team: $e");
          }
        }

        // 3. Delete user profile
        await userRef.delete();
      }
    } catch (e) {
      debugPrint("Critical error in deleteUserAccount: $e");
      rethrow;
    }
  }
}

class _StandingsAccumulator {
  _StandingsAccumulator({required this.teamId});

  final String teamId;
  int played = 0;
  int won = 0;
  int drawn = 0;
  int lost = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;
  int points = 0;
  final List<String> _formHistory = [];

  void applyMatch(int scored, int conceded) {
    played += 1;
    goalsFor += scored;
    goalsAgainst += conceded;

    if (scored > conceded) {
      won += 1;
      points += 3;
      _formHistory.add('W');
    } else if (scored == conceded) {
      drawn += 1;
      points += 1;
      _formHistory.add('D');
    } else {
      lost += 1;
      _formHistory.add('L');
    }
  }

  int get goalDifference => goalsFor - goalsAgainst;

  List<String> get form => _formHistory.length <= 5
      ? List<String>.from(_formHistory)
      : _formHistory.sublist(_formHistory.length - 5);
}

class _FixtureDraft {
  const _FixtureDraft({required this.homeTeamId, required this.awayTeamId});

  final String homeTeamId;
  final String awayTeamId;
}

List<_FixtureDraft> _generateDoubleRoundRobin(List<String> teamIds) {
  final schedule = List<String>.from(teamIds)..shuffle();
  if (schedule.length.isOdd) schedule.add('BYE');

  final halfSize = schedule.length ~/ 2;
  final rounds = schedule.length - 1;
  final firstLeg = <_FixtureDraft>[];

  for (var round = 0; round < rounds; round++) {
    for (var i = 0; i < halfSize; i++) {
      final first = schedule[i];
      final second = schedule[schedule.length - 1 - i];

      if (first != 'BYE' && second != 'BYE') {
        final flipHome = round.isOdd;
        firstLeg.add(
          _FixtureDraft(
            homeTeamId: flipHome ? second : first,
            awayTeamId: flipHome ? first : second,
          ),
        );
      }
    }
    schedule.insert(1, schedule.removeLast());
  }

  final secondLeg = firstLeg
      .map(
        (fixture) => _FixtureDraft(
          homeTeamId: fixture.awayTeamId,
          awayTeamId: fixture.homeTeamId,
        ),
      )
      .toList();

  return [...firstLeg, ...secondLeg];
}

List<DateTime> _generateFourMonthPlayDates(DateTime createdAt) {
  final start = _nextPlayDateAfter(createdAt.subtract(const Duration(days: 1)));
  final end = DateTime(start.year, start.month + 4, start.day);
  final dates = <DateTime>[];
  var cursor = DateTime(start.year, start.month, start.day, 20);

  while (cursor.isBefore(end)) {
    if (_isLeaguePlayDay(cursor)) {
      dates.add(cursor);
    }
    cursor = cursor.add(const Duration(days: 1));
  }

  return dates;
}

DateTime _nextPlayDateAfter(DateTime from) {
  var cursor = DateTime(
    from.year,
    from.month,
    from.day,
    20,
  ).add(const Duration(days: 1));
  while (!_isLeaguePlayDay(cursor)) {
    cursor = cursor.add(const Duration(days: 1));
  }
  return cursor;
}

bool _isLeaguePlayDay(DateTime date) {
  return date.weekday == DateTime.monday ||
      date.weekday == DateTime.wednesday ||
      date.weekday == DateTime.friday ||
      date.weekday == DateTime.saturday;
}
