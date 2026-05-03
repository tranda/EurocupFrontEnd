import 'dart:convert';
import 'dart:math';

import 'package:eurocup_frontend/src/model/athlete/athlete.dart';
import 'package:eurocup_frontend/src/model/race/discipline_crew.dart';
import 'package:eurocup_frontend/src/model/race/race.dart';
import 'package:eurocup_frontend/src/model/race/race_result.dart';
import 'package:eurocup_frontend/src/model/schedule/crew_seed.dart';
import 'package:eurocup_frontend/src/model/schedule/discipline_progression.dart';
import 'package:eurocup_frontend/src/model/schedule/generation_result.dart';
import 'package:eurocup_frontend/src/model/schedule/schedule_config.dart';
import 'package:eurocup_frontend/src/model/user.dart';
import 'package:http/http.dart' as http;
import 'common.dart';
import 'model/club/club.dart';
import 'model/club_details.dart';
import 'model/event/event.dart';
import 'model/race/crew.dart';
import 'model/race/discipline.dart';
import 'model/race/team.dart';

String apiURL = "https://events.motion.rs/api";

Future<bool> sendLoginRequest(String username, String password) async {
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
  };
  var request = http.Request('POST', Uri.parse('$apiURL/login'));
  request.bodyFields = {'username': username, 'password': password};
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    var res = jsonDecode(await response.stream.bytesToString());
    var data = res['data'];
    saveToken(data['token']);
    currentUser = User.fromMap(data['user']);
    // SaveToken(token);
    // Debug: user data
    return (true);
  } else {
    // Error: API request failed
    return (false);
  }
}

Future<bool> sendLogoutRequest() async {
  try {
    // Debug: attempting logout

    // Store current token before clearing
    String? currentToken = token;

    // Try to invalidate token on server
    if (currentToken != null && currentToken.isNotEmpty) {
      var headers = {
        'Authorization': 'Bearer $currentToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      var request = http.Request('POST', Uri.parse('$apiURL/logout'));
      request.headers.addAll(headers);

      // Add timeout to prevent hanging
      var response = await request.send().timeout(Duration(seconds: 10));
      String responseBody = await response.stream.bytesToString();

      // Debug: server logout response

      if (response.statusCode == 200 || response.statusCode == 401) {
        // 200 = success, 401 = token already invalid (which is fine)
        // Debug: server logout successful
      } else {
        // Debug: server logout failed
      }
    }

    // Clear local token regardless of server response
    clearToken();
    // Debug: user logged out locally
    return true;

  } catch (e) {
    // Debug: logout error
    // Even if server logout fails, clear the local token
    clearToken();
    // Debug: user logged out locally (server unreachable)
    return true;
  }
}

Future<List<Athlete>> getAthletesForClub(int? clubId) async {
  var headers = {
    'Authorization': 'Bearer $token',
  };
  var request =
      http.Request('GET', Uri.parse('$apiURL/athletes?club_id=$clubId'));
  request.bodyFields = {};
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();
  List<Athlete> athletes = [];
  if (response.statusCode == 200) {
    List<dynamic> result = jsonDecode(await response.stream.bytesToString());
    for (var athlete in result) {
      athletes.add(Athlete.fromMap(athlete));
    }
    // Debug: athletes data
  } else {
    // Error: API request failed
  }
  return (athletes);
}

Future updateAthlete(Athlete athlete) async {
  if (athlete.id == null) {
    await createAthlete(athlete);
    return;
  }
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': 'Bearer $token'
  };
  var request =
      http.Request('PUT', Uri.parse('$apiURL/athletes/${athlete.id}'));
  request.bodyFields = {
    'first_name': athlete.firstName as String,
    'last_name': athlete.lastName as String,
    'birth_date': athlete.birthDate as String,
    'gender': athlete.gender as String,
    'photo': athlete.photoBase64,
    'coach': athlete.coach == true ? '1' : '0',
    'media': athlete.media == true ? '1' : '0',
    'official': athlete.official == true ? '1' : '0',
    'supporter': athlete.supporter == true ? '1' : '0',
    'left_side': athlete.leftSide == true ? '1' : '0',
    'right_side': athlete.rightSide == true ? '1' : '0',
    'helm': athlete.helm == true ? '1' : '0',
    'drummer': athlete.drummer == true ? '1' : '0'
  };
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    // Debug: API response received
  } else {
    // Error: API request failed
  }
}

Future createAthlete(Athlete athlete) async {
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': 'Bearer $token'
  };
  var request = http.Request('POST', Uri.parse('$apiURL/athletes'));
  request.bodyFields = {
    'first_name': athlete.firstName as String,
    'last_name': athlete.lastName as String,
    'birth_date': athlete.birthDate as String,
    'gender': athlete.gender as String,
    'photo': athlete.photoBase64,
    'coach': athlete.coach == true ? '1' : '0',
    'media': athlete.media == true ? '1' : '0',
    'official': athlete.official == true ? '1' : '0',
    'supporter': athlete.supporter == true ? '1' : '0',
    'left_side': athlete.leftSide == true ? '1' : '0',
    'right_side': athlete.rightSide == true ? '1' : '0',
    'helm': athlete.helm == true ? '1' : '0',
    'drummer': athlete.drummer == true ? '1' : '0'
  };
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    // Debug: API response received
  } else {
    // Error: API request failed
  }
}

Future<bool> sendAthletes(List<Athlete> athletes) async {
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': 'Bearer $token'
  };
  var request = http.Request('POST', Uri.parse('$apiURL/athletesImport'));

  List<Map<String, dynamic>> jsonAthletes = athletes
      .map((athlete) => athlete.toMap())
      .cast<Map<String, dynamic>>()
      .toList();
  String jsonData = jsonEncode(jsonAthletes);

  request.body = jsonData;
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode >= 200 && response.statusCode < 300) {
    // Debug: API response received
    return (true);
  } else {
    // Error: API request failed
    return (false);
  }
}

Future deleteAthlete(Athlete athlete) async {
  var headers = {'Authorization': 'Bearer $token'};
  var request =
      http.Request('DELETE', Uri.parse('$apiURL/athletes/${athlete.id}'));
  request.bodyFields = {};
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    // Debug: API response received
  } else {
    // Error: API request failed
  }
}

Future<List<Team>> getTeamsAll({bool activeOnly = false}) async {
  var headers = {'Authorization': 'Bearer $token'};
  var q = "";
  if (activeOnly) q = "?active=1";
  var request = http.Request('GET', Uri.parse('$apiURL/teamsAll$q'));

  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  List<Team> teams = [];
  if (response.statusCode == 200) {
    List<dynamic> result = jsonDecode(await response.stream.bytesToString());
    // print(result);
    for (var race in result) {
      teams.add(Team.fromMap(race));
    }
  } else {
    // Error: API request failed
  }
  return (teams);
}

Future<List<Team>> getTeams(int accessLevel, {bool activeOnly = false}) async {
  var headers = {'Authorization': 'Bearer $token'};
  var q = "";
  if (activeOnly) q = "?active=1";
  http.Request request = http.Request('GET', Uri.parse('$apiURL/teams$q'));
  if (accessLevel > 0) {
    request = http.Request('GET', Uri.parse('$apiURL/teamsAll$q'));
  }

  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  List<Team> teams = [];
  if (response.statusCode == 200) {
    List<dynamic> result = jsonDecode(await response.stream.bytesToString());
    // print(result);
    for (var race in result) {
      teams.add(Team.fromMap(race));
    }
  } else {
    // Error: API request failed
  }
  return (teams);
}

Future createTeam(String name, {int? clubId}) async {
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': 'Bearer $token'
  };
  var request = http.Request('POST', Uri.parse('$apiURL/team'));
  request.bodyFields = {
    'name': name,
  };

  // Add club_id if provided (for referees, event managers, and admins)
  if (clubId != null) {
    request.bodyFields['club_id'] = clubId.toString();
  }

  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  // Debug: response status
  var responseString = await response.stream.bytesToString();
  // Debug: API response received
  if (response.statusCode == 200) {
    // Debug: API response received
  } else {
    // Error: API request failed
  }
}

Future<void> deleteTeam(int teamId) async {
  var headers = {
    'Authorization': 'Bearer $token',
  };

  var request = http.Request('DELETE', Uri.parse('$apiURL/teams/$teamId'));
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode != 200) {
    String errorMessage = await response.stream.bytesToString();
    throw Exception('Failed to delete team: $errorMessage');
  }
}

Future<List<Discipline>> getDisciplinesAll({int? eventId}) async {
  var headers = {'Authorization': 'Bearer $token'};
  String url = '$apiURL/disciplinesAll';
  if (eventId != null) {
    url += '?event_id=$eventId';
  }
  var request = http.Request('GET', Uri.parse(url));

  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  disciplines = [];
  if (response.statusCode == 200) {
    List<dynamic> result = jsonDecode(await response.stream.bytesToString());
    // print(result);
    for (var discipline in result) {
      disciplines.add(Discipline.fromMap(discipline));
    }
  } else {
    // Error: API request failed
  }
  return (disciplines);
}

Future<List<Crew>> getCrewsAll() async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request('GET', Uri.parse('$apiURL/crewsAll'));

  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  List<Crew> crews = [];
  if (response.statusCode == 200) {
    List<dynamic> result = jsonDecode(await response.stream.bytesToString());
    // print(result);
    for (var race in result) {
      crews.add(Crew.fromMap(race));
    }
  } else {
    // Error: API request failed
  }
  return (crews);
}

Future<List<Race>> getDisciplines() async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request('GET', Uri.parse('$apiURL/disciplines'));

  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  List<Race> races = [];
  if (response.statusCode == 200) {
    List<dynamic> result = jsonDecode(await response.stream.bytesToString());
    // print(result);
    for (var discipline in result) {
      races.add(Race.fromMap(discipline));
    }
  } else {
    // Error: API request failed
  }
  return (races);
}

Future<List<Race>> getDisciplinesCombined(int eventId) async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request(
      'GET', Uri.parse('$apiURL/disciplinesCombined?event_id=$eventId'));

  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  List<Race> races = [];
  if (response.statusCode == 200) {
    List<dynamic> result = jsonDecode(await response.stream.bytesToString());
    // print(result);
    for (var discipline in result) {
      races.add(Race.fromMap(discipline));
    }
  } else {
    // Error: API request failed
  }
  return (races);
}

Future<List<Race>> getTeamDisciplines(int teamId, int eventId) async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request('GET',
      Uri.parse('$apiURL/teamDisciplines?team_id=$teamId&event_id=$eventId'));

  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  List<Race> races = [];
  if (response.statusCode == 200) {
    List<dynamic> result = jsonDecode(await response.stream.bytesToString());
    // print(result);
    for (var discipline in result) {
      races.add(Race.fromMap(discipline));
    }
  } else {
    // Error: API request failed
  }
  return (races);
}

Future<List<DisciplineCrew>> getTeamsForDisciplines(int disciplineId) async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request('GET',
      Uri.parse('$apiURL/teamsForDiscipline?discipline_id=$disciplineId'));

  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  List<DisciplineCrew> races = [];
  if (response.statusCode == 200) {
    List<dynamic> result = jsonDecode(await response.stream.bytesToString());
    // print(result);
    for (var disciplineRace in result) {
      races.add(DisciplineCrew.fromMap(disciplineRace));
    }
  } else {
    // Error: API request failed
  }
  return (races);
}

Future<Map<int, Map<String, dynamic>>> getCrewAthletesForCrew(
    int crewId) async {
  var dummy = Random().nextInt(10000000);
  var headers = {'Authorization': 'Bearer $token', 'Cache-Control': 'no-cache'};
  var request = http.Request(
      'GET', Uri.parse('$apiURL/crewathletes?crew_id=$crewId&dummy=$dummy'));

  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  Map<int, Map<String, dynamic>> crewAthletes = {};

  if (response.statusCode == 200) {
    List<dynamic> result = jsonDecode(await response.stream.bytesToString());
    // print(result);
    for (var element in result) {
      crewAthletes[element['crew_athlete']['no']] = {
        'id': element['crew_athlete']['id'],
        'athlete': Athlete.fromMap(element['athlete'])
      };
    }
    // print(crewAthletes);
  } else {
    // Error: API request failed
  }
  // print("http response: $crewAthletes");
  return (crewAthletes);
}

Future insertCrewAthlete(int no, int crewId, int athleteId) async {
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': 'Bearer $token'
  };
  var request = http.Request('POST', Uri.parse('$apiURL/crewathletes'));
  request.bodyFields = {
    'no': no.toString(),
    'crew_id': crewId.toString(),
    'athlete_id': athleteId.toString()
  };
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    // Debug: API response received
  } else {
    // Error: API request failed
  }
}

Future registerCrew(int teamId, int disciplineId) async {
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': 'Bearer $token'
  };
  var request = http.Request('POST', Uri.parse('$apiURL/registercrew'));
  request.bodyFields = {
    'team_id': teamId.toString(),
    'discipline_id': disciplineId.toString()
  };
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    // Debug: API response received
  } else {
    // Error: API request failed
  }
}

Future registerCrews(int teamId, List<int> disciplineIds) async {
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': 'Bearer $token'
  };
  var request = http.Request('POST', Uri.parse('$apiURL/registercrews'));

  String body = 'team_id=$teamId&';
  List<String> repeatedParameters =
      disciplineIds.map((number) => 'discipline_ids[]=$number').toList();
  body += repeatedParameters.join('&');

  request.body = body;

  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    // Debug: API response received
  } else {
    // Error: API request failed
  }
}

Future unregisterCrew(int teamId, int disciplineId) async {
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': 'Bearer $token'
  };
  var request = http.Request('POST', Uri.parse('$apiURL/unregistercrew'));
  request.bodyFields = {
    'team_id': teamId.toString(),
    'discipline_id': disciplineId.toString()
  };
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    // Debug: API response received
  } else {
    // Error: API request failed
  }
}

Future deleteCrewAthlete(int id) async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request('DELETE', Uri.parse('$apiURL/crewathletes/$id'));
  request.bodyFields = {};
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    // Debug: API response received
  } else {
    // Error: API request failed
  }
}

Future<List<Athlete>> getEligibleAthletesForCrew(int crewId, int no) async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request(
      'GET', Uri.parse('$apiURL/eligibleAthletes?crew_id=$crewId&no=$no'));

  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();
  List<Athlete> athletes = [];
  if (response.statusCode == 200) {
    List<dynamic> result = jsonDecode(await response.stream.bytesToString());
    for (var athlete in result) {
      athletes.add(Athlete.fromMap(athlete));
    }
    // Debug: athletes data
  } else {
    // Error: API request failed
  }
  return (athletes);
}

Future<List<Athlete>> getEligibleAthletesForCombinedCrew(
    int crewId, int no) async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request('GET',
      Uri.parse('$apiURL/eligibleCombinedAthletes?crew_id=$crewId&no=$no'));

  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();
  List<Athlete> athletes = [];
  if (response.statusCode == 200) {
    List<dynamic> result = jsonDecode(await response.stream.bytesToString());
    for (var athlete in result) {
      athletes.add(Athlete.fromMap(athlete));
    }
    // Debug: athletes data
  } else {
    // Error: API request failed
  }
  return (athletes);
}

Future<List<Competition>> getCompetitions({bool allEvents = false}) async {
  var headers = {
    'Authorization': 'Bearer $token',
  };
  var url = '$apiURL/events';
  if (allEvents) {
    url += '?all=true';
  }
  var request = http.Request('GET', Uri.parse(url));
  request.bodyFields = {};
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();
  competitions = [];
  if (response.statusCode == 200) {
    var responseString = await response.stream.bytesToString();
    List<dynamic> result = jsonDecode(responseString);
    for (var competition in result) {
      competitions.add(Competition.fromMap(competition));
    }
    // print(result);
  } else {
    // Error: API request failed
  }
  return (competitions);
}

Future<List<Club>> getClubs({bool activeOnly = false}) async {
  var headers = {
    'Authorization': 'Bearer $token',
  };
  var q = "";
  if (activeOnly) q = "?active=1";
  var request = http.Request('GET', Uri.parse('$apiURL/clubs$q'));
  request.bodyFields = {};
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();
  List<Club> clubs = [];
  if (response.statusCode == 200) {
    List<dynamic> result = jsonDecode(await response.stream.bytesToString());
    for (var club in result) {
      clubs.add(Club.fromMap(club));
    }
    // print(result);
  } else {
    // Error: API request failed
  }
  return (clubs);
}

Future<List<Club>> getClubsForAdel({bool adelOnly = false}) async {
  var headers = {
    'Authorization': 'Bearer $token',
  };
  var q = "";
  if (adelOnly) q = "?req_adel=1";
  var request = http.Request('GET', Uri.parse('$apiURL/clubsAdel$q'));
  request.bodyFields = {};
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();
  List<Club> clubs = [];
  if (response.statusCode == 200) {
    List<dynamic> result = jsonDecode(await response.stream.bytesToString());
    for (var club in result) {
      clubs.add(Club.fromMap(club));
    }
    // print(result);
  } else {
    // Error: API request failed
  }
  return (clubs);
}

Future<Club> createClub(String name, String country, bool active) async {
  var headers = {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  var body = jsonEncode({
    'name': name,
    'country': country,
    'active': active ? 1 : 0,
  });

  var request = http.Request('POST', Uri.parse('$apiURL/clubs'));
  request.body = body;
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 201) {
    Map<String, dynamic> result = jsonDecode(await response.stream.bytesToString());
    return Club.fromMap(result);
  } else {
    throw Exception('Failed to create club');
  }
}

Future<Club> updateClub(int clubId, String name, String country, bool active) async {
  var headers = {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  var body = jsonEncode({
    'name': name,
    'country': country,
    'active': active ? 1 : 0,
  });

  var request = http.Request('PUT', Uri.parse('$apiURL/clubs/$clubId'));
  request.body = body;
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    Map<String, dynamic> result = jsonDecode(await response.stream.bytesToString());
    return Club.fromMap(result);
  } else {
    throw Exception('Failed to update club');
  }
}

Future<void> deleteClub(int clubId) async {
  var headers = {
    'Authorization': 'Bearer $token',
  };

  var request = http.Request('DELETE', Uri.parse('$apiURL/clubs/$clubId'));
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode != 200) {
    String errorMessage = await response.stream.bytesToString();
    throw Exception('Failed to delete club: $errorMessage');
  }
}

Future<List<User>> getUsers() async {
  try {
    print('getUsers: Starting API call');
    print('getUsers: Token = ${token?.substring(0, min(10, token?.length ?? 0))}...');
    print('getUsers: API URL = $apiURL/users');

    var headers = {
      'Authorization': 'Bearer $token',
    };
    var request = http.Request('GET', Uri.parse('$apiURL/users'));
    request.bodyFields = {};
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();
    print('getUsers: Response status code = ${response.statusCode}');

    List<User> users = [];
    if (response.statusCode == 200) {
      var responseString = await response.stream.bytesToString();
      print('getUsers: Response string length = ${responseString.length}');

      List<dynamic> result = jsonDecode(responseString);
      print('getUsers: Parsed ${result.length} users from JSON');

      for (var i = 0; i < result.length; i++) {
        try {
          var userData = result[i];
          print('getUsers: Parsing user $i: ${userData['name']}');
          User user = User.fromMap(userData);
          users.add(user);
        } catch (e) {
          print('getUsers: Error parsing user at index $i: $e');
          print('getUsers: User data was: ${result[i]}');
        }
      }
      print('getUsers: Successfully created ${users.length} User objects');
    } else {
      print('getUsers: API request failed with status ${response.statusCode}');
      var errorBody = await response.stream.bytesToString();
      print('getUsers: Error response: $errorBody');
    }
    return users;
  } catch (e, stackTrace) {
    print('getUsers: Exception caught: $e');
    print('getUsers: Stack trace: $stackTrace');
    return [];
  }
}

Future<User?> getCurrentUser() async {
  var headers = {
    'Authorization': 'Bearer $token',
  };
  var request = http.Request('GET', Uri.parse('$apiURL/user'));
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    var responseString = await response.stream.bytesToString();
    var responseData = jsonDecode(responseString);

    // Handle both direct user data and wrapped response formats
    var userData = responseData is Map<String, dynamic> && responseData.containsKey('data')
        ? responseData['data']
        : responseData;

    return User.fromMap(userData);
  } else {
    // Error: Failed to get current user
    return null;
  }
}

Future createUser(User user) async {
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': 'Bearer $token'
  };
  var request = http.Request('POST', Uri.parse('$apiURL/users'));
  request.bodyFields = {
    'name': user.name as String,
    'username': user.username as String,
    'email': user.email as String,
    'password': user.password as String,
    'password_confirmation': user.password_confirmation as String,
    'club_id': '${user.clubId}',
    'event_id': '${user.eventId}',
    'access_level': '${user.accessLevel}'
  };
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  // Debug: response status
  var responseString = await response.stream.bytesToString();
  // Debug: API response received
  if (response.statusCode == 200) {
    var responseString = await response.stream.bytesToString();
    // Debug: API response received
  } else {
    // Error: API request failed
  }
}

Future deleteUser(User user) async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request('DELETE', Uri.parse('$apiURL/users/${user.id}'));
  request.bodyFields = {};
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    // Debug: API response received
  } else {
    // Error: API request failed
  }
}

Future updateUser(User user) async {
  if (user.id == null) {
    await createUser(user);
    return;
  }
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': 'Bearer $token'
  };
  var request = http.Request('PUT', Uri.parse('$apiURL/users/${user.id}'));
  request.bodyFields = {
    'name': user.name as String,
    'username': user.username as String,
    // 'email': user.email as String,
    // 'password': 'user',//.password as String,
    // 'password_confirmation': 'user',//.password_confirmation as String,
    'club_id': '${user.clubId}',
    'event_id': '${user.eventId}',
    'access_level': '${user.accessLevel}'
  };
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    var responseString = await response.stream.bytesToString();
    // Debug: API response received
  } else {
    // Error: API request failed
  }
}

Future updatePassword(User user) async {
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': 'Bearer $token'
  };
  var request =
      http.Request('PUT', Uri.parse('$apiURL/userPassword/${user.id}'));
  request.bodyFields = {
    'password': user.password as String,
    'password_confirmation': user.password_confirmation as String,
  };
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    var responseString = await response.stream.bytesToString();
    // Debug: API response received
  } else {
    // Error: API request failed
  }
}

Future<ClubDetails> getClubDetails(int clubId) async {
  var dummy = Random().nextInt(10000000);
  var headers = {'Authorization': 'Bearer $token', 'Cache-Control': 'no-cache'};
  var request =
      http.Request('GET', Uri.parse('$apiURL/clubDetails?club_id=$clubId'));

  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  var clubDetails = const ClubDetails();

  if (response.statusCode == 200) {
    var responseString = await response.stream.bytesToString();
    var result = jsonDecode(responseString);
    // print(result);
    var data = result;
    clubDetails = ClubDetails.fromMap(data);
  } else {
    // Error: API request failed
  }
  // print("http response: $crewAthletes");
  return (clubDetails);
}

Future<void> uploadFile(int id, List<int> fileBytes) async {
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': 'Bearer $token'
  };
  var uri = Uri.parse('$apiURL/athleteCertificates/$id');
  var request = http.MultipartRequest('POST', uri);
  request.headers.addAll(headers);

  // var fileStream = http.ByteStream(file.openRead());
  // var length = await file.length();
  // var multipartFile = http.MultipartFile('pdf', fileStream, length,
  //     filename: file.path.split('/').last);
  // request.files.add(multipartFile);
  request.files.add(
    http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: 'certificate_$id',
    ),
  );

  var response = await request.send();

  if (response.statusCode == 200) {
    var responseString = await response.stream.bytesToString();
    // Debug: API response received
  } else {
    // Error: API request failed
  }
}

// Event Management API methods
Future<Competition?> getEvent(int eventId) async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request('GET', Uri.parse('$apiURL/events/$eventId'));
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    var responseString = await response.stream.bytesToString();
    Map<String, dynamic> result = jsonDecode(responseString);
    return Competition.fromMap(result);
  } else {
    // Error: API request failed
    return null;
  }
}

Future createEvent(Competition event) async {
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': 'Bearer $token'
  };
  var request = http.Request('POST', Uri.parse('$apiURL/event'));
  request.bodyFields = {
    'name': event.name as String,
    'location': event.location as String,
    'year': event.year.toString(),
    'status': event.status ?? 'active',
    'standard_reserves': event.standardReserves?.toString() ?? '',
    'standard_min_gender': event.standardMinGender?.toString() ?? '',
    'standard_max_gender': event.standardMaxGender?.toString() ?? '',
    'small_reserves': event.smallReserves?.toString() ?? '',
    'small_min_gender': event.smallMinGender?.toString() ?? '',
    'small_max_gender': event.smallMaxGender?.toString() ?? '',
    'name_entries_lock': event.nameEntriesLock?.toIso8601String() ?? '',
    'crew_entries_lock': event.crewEntriesLock?.toIso8601String() ?? '',
    'race_entries_lock': event.raceEntriesLock?.toIso8601String() ?? '',
  };
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200 || response.statusCode == 201) {
    // Debug: API response received
  } else {
    // Error: Failed to create event
    throw Exception('Failed to create event: ${response.reasonPhrase}');
  }
}

Future updateEvent(Competition event) async {
  if (event.id == null) {
    await createEvent(event);
    return;
  }
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': 'Bearer $token'
  };
  var request = http.Request('PUT', Uri.parse('$apiURL/event/${event.id}'));
  request.bodyFields = {
    'name': event.name as String,
    'location': event.location as String,
    'year': event.year.toString(),
    'status': event.status ?? 'active',
    'standard_reserves': event.standardReserves?.toString() ?? '',
    'standard_min_gender': event.standardMinGender?.toString() ?? '',
    'standard_max_gender': event.standardMaxGender?.toString() ?? '',
    'small_reserves': event.smallReserves?.toString() ?? '',
    'small_min_gender': event.smallMinGender?.toString() ?? '',
    'small_max_gender': event.smallMaxGender?.toString() ?? '',
    'name_entries_lock': event.nameEntriesLock?.toIso8601String() ?? '',
    'crew_entries_lock': event.crewEntriesLock?.toIso8601String() ?? '',
    'race_entries_lock': event.raceEntriesLock?.toIso8601String() ?? '',
  };
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    // Debug: API response received
  } else {
    // Error: Failed to update event
    throw Exception('Failed to update event: ${response.reasonPhrase}');
  }
}

Future deleteEvent(Competition event) async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request('DELETE', Uri.parse('$apiURL/event/${event.id}'));
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    // Debug: API response received
  } else {
    // Error: Failed to delete event
    throw Exception('Failed to delete event: ${response.reasonPhrase}');
  }
}

// Discipline Management API methods
Future<Discipline?> getDiscipline(int disciplineId) async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request('GET', Uri.parse('$apiURL/disciplines/$disciplineId'));
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    var responseString = await response.stream.bytesToString();
    Map<String, dynamic> result = jsonDecode(responseString);
    return Discipline.fromMap(result);
  } else {
    // Error: API request failed
    return null;
  }
}

Future createDiscipline(Discipline discipline) async {
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': 'Bearer $token'
  };
  var request = http.Request('POST', Uri.parse('$apiURL/discipline'));
  request.bodyFields = {
    'event_id': discipline.eventId.toString(),
    'distance': discipline.distance.toString(),
    'age_group': discipline.ageGroup as String,
    'gender_group': discipline.genderGroup as String,
    'boat_group': discipline.boatGroup as String,
    'competition': discipline.competition ?? '',
    'status': discipline.status ?? 'active',
  };
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200 || response.statusCode == 201) {
    // Debug: API response received
  } else {
    // Error: Failed to create discipline
    throw Exception('Failed to create discipline: ${response.reasonPhrase}');
  }
}

Future updateDiscipline(Discipline discipline) async {
  if (discipline.id == null) {
    await createDiscipline(discipline);
    return;
  }
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': 'Bearer $token'
  };
  var request = http.Request('PUT', Uri.parse('$apiURL/discipline/${discipline.id}'));
  request.bodyFields = {
    'event_id': discipline.eventId.toString(),
    'distance': discipline.distance.toString(),
    'age_group': discipline.ageGroup as String,
    'gender_group': discipline.genderGroup as String,
    'boat_group': discipline.boatGroup as String,
    'competition': discipline.competition ?? '',
    'status': discipline.status ?? 'active',
  };
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    // Debug: API response received
  } else {
    // Error: Failed to update discipline
    throw Exception('Failed to update discipline: ${response.reasonPhrase}');
  }
}

Future deleteDiscipline(Discipline discipline) async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request('DELETE', Uri.parse('$apiURL/discipline/${discipline.id}'));
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    // Debug: API response received
  } else {
    // Error: Failed to delete discipline
    throw Exception('Failed to delete discipline: ${response.reasonPhrase}');
  }
}

// Race Results API methods
Future<List<RaceResult>> getRaceResults({int? eventId, bool includeDrafts = false}) async {
  var headers = {'Authorization': 'Bearer $token'};
  var url = '$apiURL/race-results';
  final params = <String>[];
  if (eventId != null) params.add('event_id=$eventId');
  if (includeDrafts) params.add('include_drafts=1');
  if (params.isNotEmpty) url += '?${params.join("&")}';
  var request = http.Request('GET', Uri.parse(url));
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();
  List<RaceResult> raceResults = [];

  if (response.statusCode == 200) {
    var responseString = await response.stream.bytesToString();
    Map<String, dynamic> responseJson = jsonDecode(responseString);
    
    if (responseJson['success'] == true && responseJson['data'] != null) {
      List<dynamic> result = responseJson['data'] as List<dynamic>;
      for (var raceResult in result) {
        raceResults.add(RaceResult.fromMap(raceResult));
      }
    }
  } else {
    // Error: Failed to fetch race results
  }
  
  return raceResults;
}

Future<RaceResult?> getRaceResult(int raceResultId) async {
  var headers = {'Authorization': 'Bearer $token', 'Cache-Control': 'no-cache'};
  var timestamp = DateTime.now().millisecondsSinceEpoch;
  var request = http.Request('GET', Uri.parse('$apiURL/race-results/$raceResultId?t=$timestamp'));
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    var responseString = await response.stream.bytesToString();
    Map<String, dynamic> responseJson = jsonDecode(responseString);
    
    if (responseJson['success'] == true && responseJson['data'] != null) {
      return RaceResult.fromMap(responseJson['data']);
    }
    return null;
  } else {
    // Error: Failed to fetch race result
    return null;
  }
}

// Public Race Results API methods (no authentication required)
Future<List<RaceResult>> getPublicRaceResults({int? eventId}) async {
  var timestamp = DateTime.now().millisecondsSinceEpoch;
  var url = '$apiURL/public/race-results';
  if (eventId != null) {
    url += '?event_id=$eventId&t=$timestamp';
  } else {
    url += '?t=$timestamp';
  }
  var request = http.Request('GET', Uri.parse(url));
  request.headers.addAll({'Cache-Control': 'no-cache'});

  http.StreamedResponse response = await request.send();
  List<RaceResult> raceResults = [];

  if (response.statusCode == 200) {
    var responseString = await response.stream.bytesToString();
    Map<String, dynamic> responseJson = jsonDecode(responseString);
    
    if (responseJson['success'] == true && responseJson['data'] != null) {
      List<dynamic> result = responseJson['data'] as List<dynamic>;
      for (var raceResult in result) {
        raceResults.add(RaceResult.fromMap(raceResult));
      }
    }
  } else {
    // Error: Failed to fetch public race results
  }
  
  return raceResults;
}

Future<RaceResult?> getPublicRaceResult(int raceResultId) async {
  var timestamp = DateTime.now().millisecondsSinceEpoch;
  var request = http.Request('GET', Uri.parse('$apiURL/public/race-results/$raceResultId?t=$timestamp'));
  request.headers.addAll({'Cache-Control': 'no-cache'});

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    var responseString = await response.stream.bytesToString();
    Map<String, dynamic> responseJson = jsonDecode(responseString);

    if (responseJson['success'] == true && responseJson['data'] != null) {
      return RaceResult.fromMap(responseJson['data']);
    }
    return null;
  } else {
    // Error: Failed to fetch public race result
    return null;
  }
}

// Password Reset API methods
Future<Map<String, dynamic>> sendForgotPasswordRequest(String email) async {
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
  };
  var request = http.Request('POST', Uri.parse('$apiURL/forgot-password'));
  request.bodyFields = {'email': email};
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();
  var responseString = await response.stream.bytesToString();

  // Debug logging
  // Debug: forgot password response

  Map<String, dynamic> responseJson;
  try {
    responseJson = jsonDecode(responseString);
  } catch (e) {
    // Error: JSON decode failed
    responseJson = {'error': 'Invalid JSON response', 'raw': responseString};
  }

  return {
    'success': response.statusCode == 200,
    'statusCode': response.statusCode,
    'data': responseJson,
  };
}

// Database Backup API methods
Future<List<Map<String, dynamic>>> getBackups() async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request('GET', Uri.parse('$apiURL/backups'));
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();
  List<Map<String, dynamic>> backups = [];

  if (response.statusCode == 200) {
    var responseString = await response.stream.bytesToString();
    Map<String, dynamic> responseJson = jsonDecode(responseString);
    if (responseJson['success'] == true && responseJson['data'] != null) {
      backups = List<Map<String, dynamic>>.from(responseJson['data']);
    }
  }
  return backups;
}

Future<Map<String, dynamic>> createBackup() async {
  var headers = {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
  var request = http.Request('POST', Uri.parse('$apiURL/backups'));
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();
  var responseString = await response.stream.bytesToString();
  return jsonDecode(responseString);
}

Future<Map<String, dynamic>> restoreBackup(String filename) async {
  var headers = {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
  var request = http.Request('POST', Uri.parse('$apiURL/backups/restore'));
  request.body = jsonEncode({'filename': filename});
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();
  var responseString = await response.stream.bytesToString();
  return jsonDecode(responseString);
}

Future<List<int>?> downloadBackup(String filename) async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request('GET', Uri.parse('$apiURL/backups/download?filename=$filename'));
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    return await response.stream.toBytes();
  }
  return null;
}

Future<Map<String, dynamic>> deleteBackup(String filename) async {
  var headers = {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
  var request = http.Request('DELETE', Uri.parse('$apiURL/backups'));
  request.body = jsonEncode({'filename': filename});
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();
  var responseString = await response.stream.bytesToString();
  return jsonDecode(responseString);
}

Future<Map<String, dynamic>> sendResetPasswordRequest({
  required String email,
  required String token,
  required String password,
  required String passwordConfirmation,
}) async {
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
  };
  var request = http.Request('POST', Uri.parse('$apiURL/reset-password'));
  request.bodyFields = {
    'email': email,
    'token': token,
    'password': password,
    'password_confirmation': passwordConfirmation,
  };
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();
  var responseString = await response.stream.bytesToString();
  var responseJson = jsonDecode(responseString);

  return {
    'success': response.statusCode == 200,
    'statusCode': response.statusCode,
    'data': responseJson,
  };
}

// =============================================================================
// Schedule Builder API
// =============================================================================

Map<String, String> _jsonAuthHeaders() => {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

dynamic _unwrap(http.Response response, {String action = 'request'}) {
  if (response.statusCode < 200 || response.statusCode >= 300) {
    String message = '$action failed (${response.statusCode})';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['message'] is String) message = body['message'] as String;
    } catch (_) {}
    throw Exception(message);
  }
  if (response.body.isEmpty) return null;
  final body = jsonDecode(response.body);
  if (body is Map<String, dynamic> && body.containsKey('data')) return body['data'];
  return body;
}

Future<ScheduleConfig> getScheduleConfig(int eventId) async {
  final res = await http.get(
    Uri.parse('$apiURL/events/$eventId/schedule-config'),
    headers: _jsonAuthHeaders(),
  );
  return ScheduleConfig.fromMap(_unwrap(res, action: 'load schedule config') as Map<String, dynamic>);
}

Future<void> updateScheduleConfig(int eventId, {required int laneCount}) async {
  final res = await http.put(
    Uri.parse('$apiURL/events/$eventId/schedule-config'),
    headers: _jsonAuthHeaders(),
    body: jsonEncode({'lane_count': laneCount}),
  );
  _unwrap(res, action: 'update schedule config');
}

Future<int> createEventDay(int eventId, {required DateTime date, String? name, int? sortOrder}) async {
  final res = await http.post(
    Uri.parse('$apiURL/events/$eventId/event-days'),
    headers: _jsonAuthHeaders(),
    body: jsonEncode({
      'date': date.toIso8601String().substring(0, 10),
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
    }),
  );
  final data = _unwrap(res, action: 'create event day') as Map<String, dynamic>;
  return data['id'] as int;
}

Future<void> updateEventDay(int dayId, {DateTime? date, String? name, int? sortOrder}) async {
  final res = await http.put(
    Uri.parse('$apiURL/event-days/$dayId'),
    headers: _jsonAuthHeaders(),
    body: jsonEncode({
      if (date != null) 'date': date.toIso8601String().substring(0, 10),
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
    }),
  );
  _unwrap(res, action: 'update event day');
}

Future<void> deleteEventDay(int dayId) async {
  final res = await http.delete(
    Uri.parse('$apiURL/event-days/$dayId'),
    headers: _jsonAuthHeaders(),
  );
  _unwrap(res, action: 'delete event day');
}

Future<int> createScheduleBlock(
  int dayId, {
  required String name,
  required String startTime,
  required int gapSeconds,
  List<String>? genderFilter,
  List<String>? distanceFilter,
  List<String>? stageFilter,
  List<String>? competitionFilter,
  int? sortOrder,
}) async {
  final res = await http.post(
    Uri.parse('$apiURL/event-days/$dayId/blocks'),
    headers: _jsonAuthHeaders(),
    body: jsonEncode({
      'name': name,
      'start_time': startTime,
      'gap_seconds': gapSeconds,
      if (genderFilter != null) 'gender_filter': genderFilter,
      if (distanceFilter != null) 'distance_filter': distanceFilter,
      if (stageFilter != null) 'stage_filter': stageFilter,
      if (competitionFilter != null) 'competition_filter': competitionFilter,
      if (sortOrder != null) 'sort_order': sortOrder,
    }),
  );
  final data = _unwrap(res, action: 'create schedule block') as Map<String, dynamic>;
  return data['id'] as int;
}

Future<void> updateScheduleBlock(
  int blockId, {
  String? name,
  String? startTime,
  int? gapSeconds,
  List<String>? genderFilter,
  List<String>? distanceFilter,
  List<String>? stageFilter,
  List<String>? competitionFilter,
  int? sortOrder,
}) async {
  // For filter fields, always send the value (including empty list) so
  // clearing all chips actually clears the DB value. Backend treats empty
  // arrays the same as null in matching.
  final res = await http.put(
    Uri.parse('$apiURL/schedule-blocks/$blockId'),
    headers: _jsonAuthHeaders(),
    body: jsonEncode({
      if (name != null) 'name': name,
      if (startTime != null) 'start_time': startTime,
      if (gapSeconds != null) 'gap_seconds': gapSeconds,
      if (genderFilter != null) 'gender_filter': genderFilter,
      if (distanceFilter != null) 'distance_filter': distanceFilter,
      if (stageFilter != null) 'stage_filter': stageFilter,
      if (competitionFilter != null) 'competition_filter': competitionFilter,
      if (sortOrder != null) 'sort_order': sortOrder,
    }),
  );
  _unwrap(res, action: 'update schedule block');
}

Future<void> deleteScheduleBlock(int blockId) async {
  final res = await http.delete(
    Uri.parse('$apiURL/schedule-blocks/$blockId'),
    headers: _jsonAuthHeaders(),
  );
  _unwrap(res, action: 'delete schedule block');
}

Future<DisciplineProgressionInfo> getDisciplineProgression(int disciplineId) async {
  final res = await http.get(
    Uri.parse('$apiURL/disciplines/$disciplineId/progression'),
    headers: _jsonAuthHeaders(),
  );
  return DisciplineProgressionInfo.fromMap(
    _unwrap(res, action: 'load progression') as Map<String, dynamic>,
  );
}

Future<void> updateDisciplineProgression(int disciplineId, String? racePlanCode) async {
  final res = await http.put(
    Uri.parse('$apiURL/disciplines/$disciplineId/progression'),
    headers: _jsonAuthHeaders(),
    body: jsonEncode({'race_plan_code': racePlanCode}),
  );
  _unwrap(res, action: 'update progression');
}

Future<List<String>> getDisciplineRacePlanOptions(int disciplineId) async {
  final res = await http.get(
    Uri.parse('$apiURL/disciplines/$disciplineId/race-plan-options'),
    headers: _jsonAuthHeaders(),
  );
  final data = _unwrap(res, action: 'load plan options') as Map<String, dynamic>;
  return (data['options'] as List<dynamic>).map((e) => e.toString()).toList();
}

Future<List<CrewSeed>> getDisciplineCrewSeeds(int disciplineId) async {
  final res = await http.get(
    Uri.parse('$apiURL/disciplines/$disciplineId/crew-seeds'),
    headers: _jsonAuthHeaders(),
  );
  final list = _unwrap(res, action: 'load crew seeds') as List<dynamic>;
  return list.map((e) => CrewSeed.fromMap(e as Map<String, dynamic>)).toList();
}

Future<void> updateDisciplineCrewSeeds(int disciplineId, List<CrewSeed> seeds) async {
  final res = await http.put(
    Uri.parse('$apiURL/disciplines/$disciplineId/crew-seeds'),
    headers: _jsonAuthHeaders(),
    body: jsonEncode({'seeds': seeds.map((s) => s.toUpdatePayload()).toList()}),
  );
  _unwrap(res, action: 'update crew seeds');
}

Future<void> resetDisciplineCrewSeeds(int disciplineId) async {
  final res = await http.post(
    Uri.parse('$apiURL/disciplines/$disciplineId/crew-seeds/reset'),
    headers: _jsonAuthHeaders(),
  );
  _unwrap(res, action: 'reset crew seeds');
}

Future<GenerationResult> generateSchedule(int eventId) async {
  final res = await http.post(
    Uri.parse('$apiURL/events/$eventId/schedule/generate'),
    headers: _jsonAuthHeaders(),
  );
  return GenerationResult.fromMap(_unwrap(res, action: 'generate schedule') as Map<String, dynamic>);
}

Future<GenerationResult> regenerateDisciplineSchedule(int disciplineId) async {
  final res = await http.post(
    Uri.parse('$apiURL/disciplines/$disciplineId/schedule/regenerate'),
    headers: _jsonAuthHeaders(),
  );
  return GenerationResult.fromMap(_unwrap(res, action: 'regenerate discipline') as Map<String, dynamic>);
}

Future<void> publishSchedule(int eventId) async {
  final res = await http.post(
    Uri.parse('$apiURL/events/$eventId/schedule/publish'),
    headers: _jsonAuthHeaders(),
  );
  _unwrap(res, action: 'publish schedule');
}

Future<void> unpublishSchedule(int eventId) async {
  final res = await http.post(
    Uri.parse('$apiURL/events/$eventId/schedule/unpublish'),
    headers: _jsonAuthHeaders(),
  );
  _unwrap(res, action: 'unpublish schedule');
}

/// Update a single race row (race_time, stage, race_number, status).
Future<void> updateRaceResultFields(int raceId, {
  DateTime? raceTime,
  String? stage,
  int? raceNumber,
  String? status,
}) async {
  final body = <String, dynamic>{};
  if (raceTime != null) body['race_time'] = raceTime.toIso8601String();
  if (stage != null) body['stage'] = stage;
  if (raceNumber != null) body['race_number'] = raceNumber;
  if (status != null) body['status'] = status;
  final res = await http.put(
    Uri.parse('$apiURL/race-results/$raceId'),
    headers: _jsonAuthHeaders(),
    body: jsonEncode(body),
  );
  _unwrap(res, action: 'update race');
}

Future<void> deleteRaceResult(int raceId) async {
  final res = await http.delete(
    Uri.parse('$apiURL/race-results/$raceId'),
    headers: _jsonAuthHeaders(),
  );
  _unwrap(res, action: 'delete race');
}

/// Assign a single crew to a lane in a race (creates or updates the CrewResult).
/// Used by drag-to-lane edits in the Grid tab.
Future<void> assignCrewToLane(int raceId, int crewId, int? lane) async {
  final res = await http.post(
    Uri.parse('$apiURL/race-results/$raceId/crew-results'),
    headers: _jsonAuthHeaders(),
    body: jsonEncode({
      'crew_results': [
        {'crew_id': crewId, 'lane': lane},
      ],
    }),
  );
  _unwrap(res, action: 'assign lane');
}

/// Apply multiple lane assignments in one call. Used for atomic lane swaps.
/// Each entry: {'crew_id': int, 'lane': int?}.
Future<void> setCrewLanes(int raceId, List<Map<String, dynamic>> assignments) async {
  final res = await http.post(
    Uri.parse('$apiURL/race-results/$raceId/crew-results'),
    headers: _jsonAuthHeaders(),
    body: jsonEncode({'crew_results': assignments}),
  );
  _unwrap(res, action: 'set crew lanes');
}

/// Shift all SCHEDULED races at-or-after the pivot race by N minutes (signed).
/// Returns the number of races shifted.
Future<int> shiftScheduleFrom(
  int eventId, {
  required int fromRaceId,
  required int minutes,
  bool sameDayOnly = true,
}) async {
  final res = await http.post(
    Uri.parse('$apiURL/events/$eventId/schedule/shift'),
    headers: _jsonAuthHeaders(),
    body: jsonEncode({
      'from_race_id': fromRaceId,
      'minutes': minutes,
      'same_day_only': sameDayOnly,
    }),
  );
  final data = _unwrap(res, action: 'shift schedule') as Map<String, dynamic>;
  return (data['races_shifted'] ?? 0) as int;
}

Future<GenerationResult> seedNextRound(int disciplineId) async {
  final res = await http.post(
    Uri.parse('$apiURL/disciplines/$disciplineId/schedule/seed-next-round'),
    headers: _jsonAuthHeaders(),
  );
  return GenerationResult.fromMap(_unwrap(res, action: 'seed next round') as Map<String, dynamic>);
}
