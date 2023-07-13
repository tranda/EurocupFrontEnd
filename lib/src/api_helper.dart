import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:eurocup_frontend/src/model/athlete/athlete.dart';
import 'package:eurocup_frontend/src/model/race/discipline_crew.dart';
import 'package:eurocup_frontend/src/model/race/race.dart';
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
    token = data['token'];
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
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request('POST', Uri.parse('$apiURL/logout'));
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    // ClearToken();
    print('User logged out.');
    return (true);
  } else {
    print(response.reasonPhrase);
    return (false);
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
    result.forEach((athlete) {
      athletes.add(Athlete.fromMap(athlete));
    });
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
    'photo': athlete.photoBase64
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
    'photo': athlete.photoBase64
  };
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    print(await response.stream.bytesToString());
  } else {
    print(response.reasonPhrase);
  }
}

Future sendAthletes(List<Athlete> athletes) async {
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

  if (response.statusCode == 200) {
    print(await response.stream.bytesToString());
  } else {
    print(response.reasonPhrase);
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

Future<List<Team>> getTeamsAll() async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request('GET', Uri.parse('$apiURL/teamsAll'));

  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  List<Team> teams = [];
  if (response.statusCode == 200) {
    List<dynamic> result = jsonDecode(await response.stream.bytesToString());
    // print(result);
    result.forEach((race) {
      teams.add(Team.fromMap(race));
    });
  } else {
    print(response.reasonPhrase);
  }
  return (teams);
}

Future<List<Discipline>> getDisciplinesAll() async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request('GET', Uri.parse('$apiURL/disciplinesAll'));

  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  disciplines = [];
  if (response.statusCode == 200) {
    List<dynamic> result = jsonDecode(await response.stream.bytesToString());
    // print(result);
    result.forEach((discipline) {
      disciplines.add(Discipline.fromMap(discipline));
    });
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
    result.forEach((race) {
      crews.add(Crew.fromMap(race));
    });
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
    result.forEach((discipline) {
      races.add(Race.fromMap(discipline));
    });
  } else {
    print(response.reasonPhrase);
  }
  return (races);
}

Future<List<Race>> getDisciplinesCombined() async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request('GET', Uri.parse('$apiURL/disciplinesCombined'));

  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  List<Race> races = [];
  if (response.statusCode == 200) {
    List<dynamic> result = jsonDecode(await response.stream.bytesToString());
    // print(result);
    result.forEach((discipline) {
      races.add(Race.fromMap(discipline));
    });
  } else {
    print(response.reasonPhrase);
  }
  return (races);
}

Future<List<Race>> getTeamDisciplines(int teamId) async {
  var headers = {'Authorization': 'Bearer $token'};
  var request =
      http.Request('GET', Uri.parse('$apiURL/teamDisciplines?team_id=$teamId'));

  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  List<Race> races = [];
  if (response.statusCode == 200) {
    List<dynamic> result = jsonDecode(await response.stream.bytesToString());
    // print(result);
    result.forEach((discipline) {
      races.add(Race.fromMap(discipline));
    });
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
    result.forEach((disciplineRace) {
      races.add(DisciplineCrew.fromMap(disciplineRace));
    });
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
    result.forEach((element) {
      crewAthletes[element['crew_athlete']['no']] = {
        'id': element['crew_athlete']['id'],
        'athlete': Athlete.fromMap(element['athlete'])
      };
    });
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
    result.forEach((athlete) {
      athletes.add(Athlete.fromMap(athlete));
    });
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
    result.forEach((athlete) {
      athletes.add(Athlete.fromMap(athlete));
    });
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
    result.forEach((competition) {
      competitions.add(Competition.fromMap(competition));
    });
    // print(result);
  } else {
    print(response.reasonPhrase);
  }
  return (competitions);
}

Future<List<Club>> getClubs() async {
  var headers = {
    'Authorization': 'Bearer $token',
  };
  var request = http.Request('GET', Uri.parse('$apiURL/clubs'));
  request.bodyFields = {};
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();
  List<Club> clubs = [];
  if (response.statusCode == 200) {
    List<dynamic> result = jsonDecode(await response.stream.bytesToString());
    result.forEach((club) {
      clubs.add(Club.fromMap(club));
    });
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
    result.forEach((user) {
      users.add(User.fromMap(user));
    });
    // print(result);
  } else {
    print(response.reasonPhrase);
  }
  return (users);
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

  var clubDetails = ClubDetails();

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
