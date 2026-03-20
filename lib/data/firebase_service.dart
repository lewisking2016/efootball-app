import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_model.dart';
import '../models/match_model.dart';
import '../models/standings_model.dart';
import '../models/tournament_model.dart';
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

  // Helper method to fetch a team directly (for UI joining)
  Future<Team?> getTeamById(String teamId) async {
    final doc = await _db.collection('teams').doc(teamId).get();
    if (doc.exists) {
      return Team.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // -- Updating Standings Engine -- //
  
  Future<void> updateStandings(String homeTeamId, String awayTeamId, int homeScore, int awayScore) async {
    await _db.runTransaction((transaction) async {
      final homeRef = _db.collection('standings').doc(homeTeamId);
      final awayRef = _db.collection('standings').doc(awayTeamId);

      final homeDoc = await transaction.get(homeRef);
      final awayDoc = await transaction.get(awayRef);

      if (!homeDoc.exists || !awayDoc.exists) return;

      Map<String, dynamic> updateStats(Map<String, dynamic> data, int goalsFor, int goalsAgainst) {
        int played = (data['played'] ?? 0) + 1;
        int gf = (data['goalsFor'] ?? 0) + goalsFor;
        int ga = (data['goalsAgainst'] ?? 0) + goalsAgainst;
        int gd = gf - ga;
        
        int won = data['won'] ?? 0;
        int drawn = data['drawn'] ?? 0;
        int lost = data['lost'] ?? 0;
        int points = data['points'] ?? 0;
        
        List<String> form = List<String>.from(data['form'] ?? []);

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

        // Keep form array to last 5 matches
        if (form.length > 5) form = form.sublist(form.length - 5);

        return {
          'played': played,
          'won': won,
          'drawn': drawn,
          'lost': lost,
          'goalsFor': gf,
          'goalsAgainst': ga,
          'goalDifference': gd,
          'points': points,
          'form': form,
        };
      }

      transaction.update(homeRef, updateStats(homeDoc.data()!, homeScore, awayScore));
      transaction.update(awayRef, updateStats(awayDoc.data()!, awayScore, homeScore));
    });
  }

  // -- Seeding Initial Data -- //

  Future<void> seedInitialDatabase() async {
    print("Synching high-fidelity data into Firestore...");

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

    print("Database wiped. Seeding fresh 2025/26 Season data...");

    // 1. Seed Teams & Standings from MockData - Now using Upsert to ensure latest logos
    for (var i = 0; i < MockData.standings.length; i++) {
      final teamData = MockData.standings[i];
      final teamId = 'team_$i';

      // Create/Update Team
      await _db.collection('teams').doc(teamId).set({
        'name': teamData['name'],
        'shortName': teamData['name'].toString().substring(0, 3).toUpperCase(),
        'logoUrl': teamData['logo'],
        'managerId': 'system', // Default system ID
        'managerName': teamData['manager'] ?? 'Unknown',
      });

      // Create/Update Standings
      await _db.collection('standings').doc(teamId).set({
        'teamId': teamId,
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

    print("Match history is clean. Ready for 2025/26 Season 1 kickoff.");
    print("Data sync complete!");
  }

  Future<void> createNewTournament(Tournament tournament, List<Team> teams) async {
    final batch = _db.batch();
    
    // 1. Create Tournament Document
    final tournamentRef = _db.collection('tournaments').doc();
    batch.set(tournamentRef, tournament.toMap());

    // 2. Create Teams and initial Standings
    for (var team in teams) {
      final teamRef = _db.collection('teams').doc();
      final teamData = team.toMap();
      teamData['tournamentId'] = tournamentRef.id;
      batch.set(teamRef, teamData);

      // Create initial standings entry for this team in this tournament
      final standingsRef = _db.collection('standings').doc(teamRef.id);
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

    await batch.commit();
  }
}
