import 'package:eurocup_frontend/src/model/athlete/athlete.dart';
import 'package:eurocup_frontend/src/model/event/event.dart';
import 'package:eurocup_frontend/src/model/race/discipline.dart';
import 'package:flutter/material.dart';

import 'model/user.dart';

String imagesPath = 'assets/images/';

String DATEFORMAT = "yyyy-mm-dd";

int EVENTID = 6;

var TEST = true;
var ADMINTEST = false;
var testUser = "Nena";
var testPassword = "Roki1234";
var adminUser = "tranda";
var adminPassword = "12345678";
String? lastUser;
String? lastPassword;

User currentUser = User();
String? token = '';
List<Competition> competitions = [];
List<Discipline> disciplines = [];

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

const List<Color> competitionColor = [
  Color.fromARGB(255, 15, 91, 169),
  Color.fromARGB(255, 32, 188, 237),
  Color.fromARGB(128, 128, 128, 128),
  Color.fromARGB(128, 128, 128, 128),
  Color.fromARGB(255, 15, 91, 200),
  Color.fromARGB(255, 15, 91, 169),
  Color.fromARGB(255, 32, 188, 237),
];
const Color inactiveColor = Color.fromARGB(255, 176, 176, 176);
