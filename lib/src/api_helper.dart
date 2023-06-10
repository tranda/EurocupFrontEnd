import 'dart:convert';
import 'dart:math';

import 'package:eurocup_frontend/src/model/athlete/athlete.dart';
import 'package:eurocup_frontend/src/model/race/race.dart';
import 'package:eurocup_frontend/src/model/user.dart';
import 'package:http/http.dart' as http;
import 'common.dart';
import 'model/event/event.dart';
import 'model/race/crew.dart';
import 'model/race/discipline.dart';
import 'model/race/team.dart';

Future<bool> sendLoginRequest(String username, String password) async {
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
  };
  var request =
      http.Request('POST', Uri.parse('https://events.motion.rs/api/login'));
  request.bodyFields = {'email': username, 'password': password};
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
  var headers = {
    'Authorization': 'Bearer $token'
  };
  var request =
      http.Request('POST', Uri.parse('https://events.motion.rs/api/logout'));
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
  var request = http.Request('GET',
      Uri.parse('https://events.motion.rs/api/athletes?club_id=$clubId'));
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
  var request = http.Request(
      'PUT', Uri.parse('https://events.motion.rs/api/athletes/${athlete.id}'));
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
  var request =
      http.Request('POST', Uri.parse('https://events.motion.rs/api/athletes'));
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

Future deleteAthlete(Athlete athlete) async {
  var headers = {'Authorization': 'Bearer $token'};
  var request = http.Request('DELETE',
      Uri.parse('https://events.motion.rs/api/athletes/${athlete.id}'));
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
  var request = http.Request(
      'GET', Uri.parse('https://events.motion.rs/api/teamsAll'));

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
  var request = http.Request(
      'GET', Uri.parse('https://events.motion.rs/api/disciplinesAll'));

  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  // List<Discipline> disciplines = [];
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
  var request = http.Request(
      'GET', Uri.parse('https://events.motion.rs/api/crewsAll'));

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
  var request = http.Request(
      'GET', Uri.parse('https://events.motion.rs/api/disciplines'));

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
  var request = http.Request(
      'GET', Uri.parse('https://events.motion.rs/api/teamDisciplines?team_id=$teamId'));

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

Future<Map<int, Map<String, dynamic>>> getCrewAthletesForCrew(
    int crewId) async {
  var dummy = Random().nextInt(10000000);
  var headers = {'Authorization': 'Bearer $token', 'Cache-Control': 'no-cache'};
  var request = http.Request('GET',
      Uri.parse('https://events.motion.rs/api/crewathletes?crew_id=$crewId&dummy=$dummy'));

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
  var request = http.Request(
      'POST', Uri.parse('https://events.motion.rs/api/crewathletes'));
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
  var request = http.Request(
      'POST', Uri.parse('https://events.motion.rs/api/registercrew'));
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
  var request = http.Request(
      'POST', Uri.parse('https://events.motion.rs/api/unregistercrew'));
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
  var request = http.Request(
      'DELETE', Uri.parse('https://events.motion.rs/api/crewathletes/$id'));
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
      'GET',
      Uri.parse(
          'https://events.motion.rs/api/eligibleAthletes?crew_id=$crewId&no=$no'));

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
  var request =
      http.Request('GET', Uri.parse('https://events.motion.rs/api/events'));
  request.bodyFields = {};
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();
  // List<Competition> competitions = [];
  if (response.statusCode == 200) {
    List<dynamic> result = jsonDecode(await response.stream.bytesToString());
    result.forEach((competition) {
      competitions.add(Competition.fromMap(competition));
    });
    print(result);
  } else {
    print(response.reasonPhrase);
  }
  return (competitions);
}
