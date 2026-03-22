import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/team_model.dart';
import '../models/match_model.dart';
import '../models/standings_model.dart';
import '../models/tournament_model.dart';
import '../models/app_user_model.dart';
import 'mock_data.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -- Streams -- //

  Stream<List<StandingsEntry>> getStandings() {
    return _db.collection('standings').orderBy('position').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => StandingsEntry.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<List<Match>> getMatches() {
    return _db.collection('matches').orderBy('date').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Match.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<List<Team>> getTeams() {
    return _db.collection('teams').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Team.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<List<Tournament>> getTournaments() {
    return _db.collection('tournaments').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Tournament.fromMap(doc.data(), doc.id)).toList();
    });
  }
  // For background tasks (Free alternative to Cloud Functions)
  Future<List<Match>> getTeamMatchesTodaySync(String uid) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) return [];
      final teamId = userDoc.data()?['teamId'];
      if (teamId == null) return [];

      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      
      // Query matches where team plays and date starts with today
      final homeQuery = await _db.collection('matches')
          .where('homeTeamId', isEqualTo: teamId)
          .where('status', isEqualTo: 'Pending')
          .get();
          
      final awayQuery = await _db.collection('matches')
          .where('awayTeamId', isEqualTo: teamId)
          .where('status', isEqualTo: 'Pending')
          .get();

      List<Match> all = [
        ...homeQuery.docs.map((d) => Match.fromMap(d.data(), d.id)),
        ...awayQuery.docs.map((d) => Match.fromMap(d.data(), d.id)),
      ];

      return all.where((m) => m.date.toIso8601String().startsWith(todayStr)).toList();
    } catch (e) {
      debugPrint("Sync Error: $e");
      return [];
    }
  }
  Stream<List<Match>> getTeamMatchesToday(String teamId) {
    final now = DateTime.now();
    final todayStr = DateTime(now.year, now.month, now.day).toIso8601String().split('T')[0];
    
    return _db.collection('matches')
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Match.fromMap(doc.data(), doc.id)).where((m) {
            final mDateStr = m.date.toIso8601String().split('T')[0];
            return mDateStr == todayStr && (m.homeTeamId == teamId || m.awayTeamId == teamId);
          }).toList();
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
  
  // -- Updating Standings Engine -- //
  
  Future<void> updateStandings(String tournamentId, String homeTeamId, String awayTeamId, int homeScore, int awayScore, {int? oldHomeScore, int? oldAwayScore}) async {
    await _db.runTransaction((transaction) async {
      final homeRef = _db.collection('standings').doc('${tournamentId}_$homeTeamId');
      final awayRef = _db.collection('standings').doc('${tournamentId}_$awayTeamId');

      final homeDoc = await transaction.get(homeRef);
      final awayDoc = await transaction.get(awayRef);

      if (!homeDoc.exists || !awayDoc.exists) return;

      Map<String, dynamic> calculateNewStats(Map<String, dynamic> data, int goalsFor, int goalsAgainst, {int? prevGoalsFor, int? prevGoalsAgainst}) {
        int played = data['played'] ?? 0;
        int won = data['won'] ?? 0;
        int drawn = data['drawn'] ?? 0;
        int lost = data['lost'] ?? 0;
        int gf = data['goalsFor'] ?? 0;
        int ga = data['goalsAgainst'] ?? 0;
        int points = data['points'] ?? 0;
        List<String> form = List<String>.from(data['form'] ?? []);

        // 1. REVERT old match stats if they existed
        if (prevGoalsFor != null && prevGoalsAgainst != null) {
          played -= 1;
          gf -= prevGoalsFor;
          ga -= prevGoalsAgainst;
          
          if (prevGoalsFor > prevGoalsAgainst) {
            won -= 1;
            points -= 3;
          } else if (prevGoalsFor == prevGoalsAgainst) {
            drawn -= 1;
            points -= 1;
          } else {
            lost -= 1;
          }
          // Remove last form entry if merging back
          if (form.isNotEmpty) form.removeLast();
        }

        // 2. APPLY new match stats
        played += 1;
        gf += goalsFor;
        ga += goalsAgainst;

        if (goalsFor > goalsAgainst) {
          won += 1;
          points += 3;
          form.add('W');
        } else if (goalsFor == goalsAgainst) {
          drawn += 1;
          points += 1;
          form.add('D');
        } else {
          lost += 1;
          form.add('L');
        }

        if (form.length > 5) form = form.sublist(form.length - 5);

        return {
          'played': played,
          'won': won,
          'drawn': drawn,
          'lost': lost,
          'goalsFor': gf,
          'goalsAgainst': ga,
          'goalDifference': gf - ga,
          'points': points,
          'form': form,
        };
      }

      transaction.update(homeRef, calculateNewStats(homeDoc.data()!, homeScore, awayScore, prevGoalsFor: oldHomeScore, prevGoalsAgainst: oldAwayScore));
      transaction.update(awayRef, calculateNewStats(awayDoc.data()!, awayScore, homeScore, prevGoalsFor: oldAwayScore, prevGoalsAgainst: oldHomeScore));
    });

    // After stats are updated, re-rank everyone to update 'position' and 'previousPosition'
    await _reRankTeams(tournamentId);
  }

  Future<void> _reRankTeams(String tournamentId) async {
    final snapshots = await _db.collection('standings').where('tournamentId', isEqualTo: tournamentId).get();
    List<StandingsEntry> entries = snapshots.docs.map((doc) => StandingsEntry.fromMap(doc.data(), doc.id)).toList();

    // Sort by Points, GD, GF
    entries.sort((a, b) {
      if (b.points != a.points) return b.points.compareTo(a.points);
      if (b.goalDifference != a.goalDifference) return b.goalDifference.compareTo(a.goalDifference);
      return b.goalsFor.compareTo(a.goalsFor);
    });

    final batch = _db.batch();
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final newPos = i + 1;
      
      batch.update(_db.collection('standings').doc('${tournamentId}_${entry.teamId}'), {
        'previousPosition': entry.position, // The current 'position' becomes 'previous'
        'position': newPos,
      });
    }
    await batch.commit();
  }

  // -- User Roles & Access Control -- //

  Future<void> createOrUpdateUser(String uid, String email, [String? displayName, bool? isAdmin]) async {
    final docRefs = _db.collection('users').doc(uid);
    final docSnap = await docRefs.get();
    
    if (!docSnap.exists) {
      await docRefs.set({
        'email': email,
        'displayName': displayName ?? email.split('@')[0],
        'isAdmin': isAdmin ?? false,
        'teamId': null,
      });
    } else if (isAdmin != null) {
      // If user exists but we want to force admin status (like the admin login button)
      await docRefs.update({'isAdmin': isAdmin});
    }
  }

  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<bool> isAdmin(String uid) async {
    final user = await getUserProfile(uid);
    return user?.isAdmin ?? false;
  }

  Future<void> claimTeam(String uid, String teamId, String email) async {
    final batch = _db.batch();

    // 1. Update user profile with claimed team
    final userRef = _db.collection('users').doc(uid);
    batch.update(userRef, {'teamId': teamId});

    // 2. Update team profile with player owner
    final teamRef = _db.collection('teams').doc(teamId);
    batch.update(teamRef, {
      'playerId': uid,
      'playerEmail': email,
    });

    await batch.commit();
  }

  Future<void> handleDelayedMatches() async {
    final now = DateTime.now();
    // 24-hour grace period (1 full day) after the match date before it's "delayed"
    final graceTime = now.subtract(const Duration(hours: 24));

    try {
      final snapshot = await _db.collection('matches')
          .where('status', isEqualTo: 'Pending')
          .get();

      for (var doc in snapshot.docs) {
        final match = Match.fromMap(doc.data(), doc.id);
        
        if (match.date.isBefore(graceTime)) {
          if (match.postponedCount == 0) {
            // -- POSTPONE (1st time) --
            // Reschedule to next standard day (Sat or Wed)
            DateTime newDate;
            if (match.date.weekday == DateTime.saturday) {
              newDate = match.date.add(const Duration(days: 4)); // Next Wednesday
            } else if (match.date.weekday == DateTime.wednesday) {
              newDate = match.date.add(const Duration(days: 3)); // Next Saturday
            } else {
              newDate = match.date.add(const Duration(days: 3)); // Default
            }

            await doc.reference.update({
              'date': newDate.toIso8601String(),
              'postponedCount': 1,
              // Keep status as Pending so it shows up in future checks
            });
            debugPrint("AUTOMATION: Match ${match.id} postponed to ${newDate.toIso8601String()}");
          } else {
            // -- AUTO-RESOLVE (2nd delay) --
            // Set to 0-0 Draw
            await _autoResolveDelayedMatch(match);
            debugPrint("AUTOMATION: Match ${match.id} auto-resolved to 0-0 (Forfeit/Draw)");
          }
        }
      }
    } catch (e) {
      debugPrint("Error in handleDelayedMatches: $e");
    }
  }

  Future<void> _autoResolveDelayedMatch(Match match) async {
    // We use the existing submitMatchResult logic but forced to 0-0
    await submitMatchResult(
      matchId: match.id,
      tournamentId: match.tournamentId,
      homeTeamId: match.homeTeamId,
      awayTeamId: match.awayTeamId,
      homeScore: 0,
      awayScore: 0,
      isAdmin: true,
    );
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
          'awayTeamId': 'team_${i+1}',
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

  Future<String> createNewTournament(Tournament tournament, List<Team> teams) async {
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

      final standingsRef = _db.collection('standings').doc('${tournamentRef.id}_${teamRef.id}');
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

    // 3. Generate Fixtures (2 games per week for 6 weeks = 12 matchweeks)
    final List<String> schedule = List.from(teamIds);
    schedule.shuffle(); // Randomize teams
    if (schedule.length % 2 != 0) schedule.add('BYE');
    int halfSize = schedule.length ~/ 2;

    for (int round = 0; round < 12; round++) {
      for (int i = 0; i < halfSize; i++) {
        String home = schedule[i];
        String away = schedule[schedule.length - 1 - i];

        if (home != 'BYE' && away != 'BYE') {
          final matchRef = _db.collection('matches').doc();
          
          // weekIndex 0..5 (6 weeks)
          int weekIndex = round ~/ 2; 
          // 2 matches per week: Day 0 (Sat) and Day 4 (Wed)
          int dayOffset = (round % 2 == 0) ? 0 : 4; 
          
          int totalDays = (weekIndex * 7) + dayOffset + 7; // Starts in 1 week

          batch.set(matchRef, {
            'tournamentId': tournamentRef.id,
            'homeTeamId': home,
            'awayTeamId': away,
            'matchweek': (weekIndex + 1).toString(), // Changed from round + 1 to group 2 games per week
            'status': 'Pending',
            'date': DateTime.now().add(Duration(days: totalDays)).toIso8601String(),
          });
        }
      }
      // Round Robin rotation
      schedule.insert(1, schedule.removeLast());
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
    final snapshot = await _db.collection('teams')
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

    // 2. Permission Check: If already FT and not admin, block edit
    if (existingMatch?.status == 'FT' && !isAdmin) {
      throw Exception("This result is locked. Only admins can edit finalized results.");
    }

    // 3. Update or Create Match
    final targetMatchId = matchId ?? _db.collection('matches').doc().id;
    await _db.collection('matches').doc(targetMatchId).set({
      'tournamentId': tournamentId,
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'status': 'FT',
      'date': existingMatch?.date.toIso8601String() ?? DateTime.now().toIso8601String(),
      'matchweek': existingMatch?.matchweek ?? 'Manual',
    }, SetOptions(merge: true));

    // 4. Update Standings
    final isFinalized = existingMatch?.status == 'FT' || existingMatch?.status == 'Finished';
    await updateStandings(
      tournamentId,
      homeTeamId,
      awayTeamId,
      homeScore,
      awayScore,
      oldHomeScore: isFinalized ? existingMatch?.homeScore : null,
      oldAwayScore: isFinalized ? existingMatch?.awayScore : null,
    );
  }

  Future<void> updateMatchStatus(String matchId, String status, [int? homeScore, int? awayScore]) async {
    final data = <String, dynamic>{
      'status': status,
    };
    if (homeScore != null) data['homeScore'] = homeScore;
    if (awayScore != null) data['awayScore'] = awayScore;
    
    await _db.collection('matches').doc(matchId).update(data);
  }

  Future<void> deleteTournament(String tournamentId) async {
    final batch = _db.batch();

    // 1. Delete Tournament Document
    batch.delete(_db.collection('tournaments').doc(tournamentId));

    // 2. Delete all matches for this tournament
    final matches = await _db.collection('matches').where('tournamentId', isEqualTo: tournamentId).get();
    for (var doc in matches.docs) {
      batch.delete(doc.reference);
    }

    // 3. Delete all standings for this tournament
    final standings = await _db.collection('standings').where('tournamentId', isEqualTo: tournamentId).get();
    for (var doc in standings.docs) {
      batch.delete(doc.reference);
    }

    // 4. Delete all teams for this tournament
    final teams = await _db.collection('teams').where('tournamentId', isEqualTo: tournamentId).get();
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
}
