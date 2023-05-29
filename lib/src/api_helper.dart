import 'dart:convert';

import 'package:eurocup_frontend/src/model/athlete/athlete.dart';
import 'package:eurocup_frontend/src/model/user.dart';
import 'package:http/http.dart' as http;
import 'common.dart';

Future<bool> sendLoginRequest(String username, String password) async {
  var headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'X-CSRF-TOKEN': '{{csrf_token}}'
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
    print(currentUser);
    return (true);
  } else {
    print(response.reasonPhrase);
    return (false);
  }
}

Future<List<Athlete>> getAthletesForClub(int? clubId) async {
  List<Athlete> athletes = [];
  var headers = {
    'Authorization': 'Bearer $token',
    'Cookie':
        'XSRF-TOKEN=eyJpdiI6ImhrTUFmdHdiTkNZVHVxOXRjbVl0SWc9PSIsInZhbHVlIjoiUDZGc2ZoTWYxcUlSbmlxaVlLSmxUWmUrQ3Mwdk4xQzJFM09xdDdTVTFXNXpma0wxQ2d2VU41OFB2UjBDWUdlMDBtWUk4aHFGSWs0WDE3WG9qVDVDUTNoSTdTTVNPUjdGUXZ6NWNHcm5Ta1VJbVc0NmlGZHNXNGM5QlJiOEltN2QiLCJtYWMiOiI0ZjE2ZTcyNTAyMDI5MzIzZGFkM2ZkNjVlODJkYTQzNDJkNDc2ZTkyYTY4M2EzZmE1NjA2MjJiNDcyMzMzZDYzIiwidGFnIjoiIn0%3D; laravel_session=eyJpdiI6IjVwTDhIYktROXlWdWE2bGxwMHVTVEE9PSIsInZhbHVlIjoidjdiM3BINDBrTHBLQ200ZmxLS1FhaUJGTlNaMFBIN3JjWno0U3V6UVJDR0xwVkF5K2RQdlNiM2QvbGcvWHZzZjkzVDEyYmU4NHV2eU5QWVZKUUFtRmpITmJ1Skh1enByV0dyZnpxQ05MUzFTcHdXczd5aUtjZHo1S0xIaUFLQzIiLCJtYWMiOiJlNDYyM2ZmNTI3YjkwNjk4YmIyYTY1MDAwM2Q5MjA3OTJhNDZkZDA1NTcwMTY0NGU4MDhlODRkMThlYTdmMmE0IiwidGFnIjoiIn0%3D'
  };
  var request = http.Request('GET',
      Uri.parse('https://events.motion.rs/api/athletes?club_id=$clubId'));
  request.bodyFields = {};
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    List<dynamic> res = jsonDecode(await response.stream.bytesToString());
    res.forEach((athlete) {
      athletes.add(Athlete.fromMap(athlete));
    });
    print(athletes);
  } else {
    print(response.reasonPhrase);
  }
  return (athletes);
}

void updateAthlete(Athlete athlete) async {
  if (athlete.id == null) {
    createAthlete(athlete);
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

void createAthlete(Athlete athlete) async {
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

void deleteAthlete(Athlete athlete) async {
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
