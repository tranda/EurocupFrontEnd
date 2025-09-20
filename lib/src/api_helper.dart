import 'dart:convert';
import 'dart:math';

import 'package:eurocup_frontend/src/model/athlete/athlete.dart';
import 'package:eurocup_frontend/src/model/race/discipline_crew.dart';
import 'package:eurocup_frontend/src/model/race/race.dart';
import 'package:eurocup_frontend/src/model/race/race_result.dart';
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
    // print(currentUser);
    return (true);
  } else {
    print(response.reasonPhrase);
    return (false);
  }
}

Future<bool> sendLogoutRequest() async {
  try {
    print('Attempting logout...');

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

      print('Server logout response: ${response.statusCode}');
      print('Server logout body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 401) {
        // 200 = success, 401 = token already invalid (which is fine)
        print('Server logout successful');
      } else {
        print('Server logout failed with status ${response.statusCode}');
      }
    }

    // Clear local token regardless of server response
    clearToken();
    print('User logged out locally.');
    return true;

  } catch (e) {
    print('Logout error: $e');
    // Even if server logout fails, clear the local token
    clearToken();
    print('User logged out locally (server unreachable).');
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
    // print(athletes);
  } else {
    print(response.reasonPhrase);
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
    print(await response.stream.bytesToString());
  } else {
    print(response.reasonPhrase);
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
    print(await response.stream.bytesToString());
  } else {
    print(response.reasonPhrase);
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
    print(await response.stream.bytesToString());
    return (true);
  } else {
    print(response.reasonPhrase);
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
    print(await response.stream.bytesToString());
  } else {
    print(response.reasonPhrase);
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
    print(response.reasonPhrase);
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
    print(response.reasonPhrase);
  }
  return (teams);
}

Future createTeam(String name) async {
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': 'Bearer $token'
  };
  var request = http.Request('POST', Uri.parse('$apiURL/team'));
  request.bodyFields = {
    'name': name,
  };
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  print('response.statusCode: ${response.statusCode}');
  var responseString = await response.stream.bytesToString();
  print(responseString);
  if (response.statusCode == 200) {
    print(responseString);
  } else {
    print('error response: ${response.reasonPhrase}');
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
    print(response.reasonPhrase);
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
    print(response.reasonPhrase);
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
    print(response.reasonPhrase);
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
    print(response.reasonPhrase);
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
    print(response.reasonPhrase);
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
    print(response.reasonPhrase);
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
    print(response.reasonPhrase);
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
    print(await response.stream.bytesToString());
  } else {
    print(response.reasonPhrase);
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
    print(await response.stream.bytesToString());
  } else {
    print(response.reasonPhrase);
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
    print(await response.stream.bytesToString());
  } else {
    print(response.reasonPhrase);
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
    print(await response.stream.bytesToString());
  } else {
    print(response.reasonPhrase);
  }
}

Future deleteCrewAthlete(int id) async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request('DELETE', Uri.parse('$apiURL/crewathletes/$id'));
  request.bodyFields = {};
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    print(await response.stream.bytesToString());
  } else {
    print(response.reasonPhrase);
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
    // print(athletes);
  } else {
    print(response.reasonPhrase);
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
    // print(athletes);
  } else {
    print(response.reasonPhrase);
  }
  return (athletes);
}

Future<List<Competition>> getCompetitions() async {
  var headers = {
    'Authorization': 'Bearer $token',
  };
  var request = http.Request('GET', Uri.parse('$apiURL/events'));
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
    print(response.reasonPhrase);
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
    print(response.reasonPhrase);
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
    print(response.reasonPhrase);
  }
  return (clubs);
}

Future<List<User>> getUsers() async {
  var headers = {
    'Authorization': 'Bearer $token',
  };
  var request = http.Request('GET', Uri.parse('$apiURL/users'));
  request.bodyFields = {};
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();
  List<User> users = [];
  if (response.statusCode == 200) {
    var responseString = await response.stream.bytesToString();
    List<dynamic> result = jsonDecode(responseString);
    for (var user in result) {
      users.add(User.fromMap(user));
    }
    // print(result);
  } else {
    print(response.reasonPhrase);
  }
  return (users);
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
    print('Failed to get current user: ${response.reasonPhrase}');
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

  print('response.statusCode: ${response.statusCode}');
  var responseString = await response.stream.bytesToString();
  print(responseString);
  if (response.statusCode == 200) {
    var responseString = await response.stream.bytesToString();
    print(responseString);
  } else {
    print('error response: ${response.reasonPhrase}');
  }
}

Future deleteUser(User user) async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request('DELETE', Uri.parse('$apiURL/users/${user.id}'));
  request.bodyFields = {};
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    print(await response.stream.bytesToString());
  } else {
    print(response.reasonPhrase);
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
    print(responseString);
  } else {
    print('error response: ${response.reasonPhrase}');
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
    print(responseString);
  } else {
    print('error response: ${response.reasonPhrase}');
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
    print(response.reasonPhrase);
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
    print(responseString);
  } else {
    print('error response: ${response.reasonPhrase}');
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
    print(response.reasonPhrase);
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
    print(await response.stream.bytesToString());
  } else {
    print('Error creating event: ${response.reasonPhrase}');
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
    print(await response.stream.bytesToString());
  } else {
    print('Error updating event: ${response.reasonPhrase}');
    throw Exception('Failed to update event: ${response.reasonPhrase}');
  }
}

Future deleteEvent(Competition event) async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request('DELETE', Uri.parse('$apiURL/event/${event.id}'));
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    print(await response.stream.bytesToString());
  } else {
    print('Error deleting event: ${response.reasonPhrase}');
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
    print(response.reasonPhrase);
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
    'status': discipline.status ?? 'active',
  };
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200 || response.statusCode == 201) {
    print(await response.stream.bytesToString());
  } else {
    print('Error creating discipline: ${response.reasonPhrase}');
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
    'status': discipline.status ?? 'active',
  };
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    print(await response.stream.bytesToString());
  } else {
    print('Error updating discipline: ${response.reasonPhrase}');
    throw Exception('Failed to update discipline: ${response.reasonPhrase}');
  }
}

Future deleteDiscipline(Discipline discipline) async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request('DELETE', Uri.parse('$apiURL/discipline/${discipline.id}'));
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    print(await response.stream.bytesToString());
  } else {
    print('Error deleting discipline: ${response.reasonPhrase}');
    throw Exception('Failed to delete discipline: ${response.reasonPhrase}');
  }
}

// Race Results API methods
Future<List<RaceResult>> getRaceResults({int? eventId}) async {
  var headers = {'Authorization': 'Bearer $token'};
  var url = '$apiURL/race-results';
  if (eventId != null) {
    url += '?event_id=$eventId';
  }
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
    print('Error fetching race results: ${response.reasonPhrase}');
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
    print('Error fetching race result: ${response.reasonPhrase}');
    return null;
  }
}

// Public Race Results API methods (no authentication required)
Future<List<RaceResult>> getPublicRaceResults({int? eventId}) async {
  var url = '$apiURL/public/race-results';
  if (eventId != null) {
    url += '?event_id=$eventId';
  }
  var request = http.Request('GET', Uri.parse(url));

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
    print('Error fetching public race results: ${response.reasonPhrase}');
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
    print('Error fetching public race result: ${response.reasonPhrase}');
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
  print('Forgot password response: ${response.statusCode}');
  print('Response body: $responseString');

  Map<String, dynamic> responseJson;
  try {
    responseJson = jsonDecode(responseString);
  } catch (e) {
    print('JSON decode error: $e');
    responseJson = {'error': 'Invalid JSON response', 'raw': responseString};
  }

  return {
    'success': response.statusCode == 200,
    'statusCode': response.statusCode,
    'data': responseJson,
  };
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
