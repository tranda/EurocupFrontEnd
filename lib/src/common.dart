import 'package:eurocup_frontend/src/model/event/event.dart';
export 'package:eurocup_frontend/src/model/event/event.dart' show Competition;
import 'package:eurocup_frontend/src/model/race/discipline.dart';
export 'package:eurocup_frontend/src/model/race/discipline.dart' show Discipline;
import 'package:eurocup_frontend/src/model/club/club.dart';
export 'package:eurocup_frontend/src/model/club/club.dart' show Club;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'model/user.dart';

String imagesPath = 'assets/images/';

String DATEFORMAT = "yyyy-mm-dd";

int EVENTID = 8;

var TEST = _getBoolFromEnv('TEST_MODE');
var ADMINTEST = _getBoolFromEnv('ADMIN_TEST_MODE');
var testUser = _getStringFromEnv('TEST_USERNAME', '');
var testPassword = _getStringFromEnv('TEST_PASSWORD', '');
var adminUser = _getStringFromEnv('ADMIN_USERNAME', '');
var adminPassword = _getStringFromEnv('ADMIN_PASSWORD', '');

// Helper functions to safely access dotenv with fallbacks
bool _getBoolFromEnv(String key) {
  try {
    final value = dotenv.env[key] == 'true';
    // Debug: Environment $key: $value
    return value;
  } catch (e) {
    // Debug: Failed to read environment $key: $e
    return false;
  }
}

String _getStringFromEnv(String key, String defaultValue) {
  try {
    final value = dotenv.env[key] ?? defaultValue;
    // Debug: Environment $key: ${value.isNotEmpty ? "***set***" : "empty"}
    return value;
  } catch (e) {
    // Debug: Failed to read environment $key: $e
    return defaultValue;
  }
}
String? lastUser;
String? lastPassword;

User currentUser = User();
String? token = '';
List<Competition> competitions = [];
List<Discipline> disciplines = [];
List<Club> clubs = [];

const String imagePrefix = 'events.motion.rs/photos';
const String certificatePrefix = 'events.motion.rs/certificates';
const String registrationFormURL = 'https://forms.gle/24meGmPLJvVE1zRG9';

const double horizontalPadding = 24.0;
const double verticalPadding = 8.0;
const double verticalPadding2 = 12.0;
const double smallSpace = 10;
const double bigSpace = 50;
const double cornerRadius = 4;
const double iconSize = 24;

// Discipline field options
const List<String> disciplineAgeGroups = ['Junior', 'Junior A', 'Junior B', 'U24', 'Premier', 'Senior A', 'Senior B', 'Senior C', 'Senior D', 'BCP', 'ACP'];
const List<String> disciplineGenderGroups = ['Mixed', 'Women', 'Open'];
const List<String> disciplineBoatGroups = ['Standard', 'Small'];
const List<String> disciplineStatusOptions = ['active', 'inactive'];
const List<int> disciplineDistanceOptions = [200, 500, 1000, 2000];

const List<Color> competitionColor = [
  Color.fromARGB(255, 15, 91, 169),
  Color.fromARGB(255, 32, 188, 237),
  Color.fromARGB(128, 128, 128, 128),
  Color.fromARGB(128, 128, 128, 128),
  Color.fromARGB(255, 15, 91, 200),
  Color.fromARGB(255, 18, 110, 203),
  Color.fromARGB(255, 32, 188, 237),
  Color.fromARGB(255, 15, 91, 169),
  Color.fromARGB(255, 32, 188, 237),
  Color.fromARGB(128, 128, 128, 128),
  Color.fromARGB(128, 128, 128, 128),
  Color.fromARGB(255, 15, 91, 200),
  Color.fromARGB(255, 18, 110, 203),
  Color.fromARGB(255, 32, 188, 237),
  Color.fromARGB(255, 15, 91, 169),
  Color.fromARGB(255, 32, 188, 237),
  Color.fromARGB(128, 128, 128, 128),
  Color.fromARGB(128, 128, 128, 128),
  Color.fromARGB(255, 15, 91, 200),
  Color.fromARGB(255, 18, 110, 203),
  Color.fromARGB(255, 32, 188, 237),
  Color.fromARGB(255, 15, 91, 169),
  Color.fromARGB(255, 32, 188, 237),
  Color.fromARGB(128, 128, 128, 128),
  Color.fromARGB(128, 128, 128, 128),
  Color.fromARGB(255, 15, 91, 200),
  Color.fromARGB(255, 18, 110, 203),
  Color.fromARGB(255, 32, 188, 237),
  ];
const Color inactiveColor = Color.fromARGB(255, 176, 176, 176);

/// Helper function for web-friendly navigation that updates URL with query parameters
/// This ensures that browser refresh works properly on the target page
Future<T?> navigateWithParams<T extends Object?>(
  BuildContext context,
  String routeName, {
  Map<String, dynamic>? arguments,
}) {
  return Navigator.pushNamed<T>(
    context,
    routeName,
    arguments: arguments,
  );
}

// Token storage functions for web
void saveToken(String? newToken) {
  token = newToken;
  if (kIsWeb && newToken != null) {
    html.window.localStorage['auth_token'] = newToken;
  }
}

void loadToken() {
  if (kIsWeb) {
    token = html.window.localStorage['auth_token'];
  }
}

void clearToken() {
  token = null;
  if (kIsWeb) {
    html.window.localStorage.remove('auth_token');
  }
}
