import 'package:eurocup_frontend/src/model/athlete/athlete.dart';
import 'package:eurocup_frontend/src/model/event/event.dart';
import 'package:flutter/material.dart';

import 'model/user.dart';

String imagesPath = 'assets/images/';

var TEST = true;
var testUser = "mymail@gmail.com";
var testPassword = "12345678";

User currentUser = User();
String token = '';
List<Competition> competitions = [];

Athlete currentAthlete = Athlete();
String imagePrefix = 'events.motion.rs/photos';

const double horizontalPadding = 24.0;
const double verticalPadding = 8.0;
const double verticalPadding2 = 12.0;
const double smallSpace = 10;
const double bigSpace = 50;
const double cornerRadius = 4;
const double iconSize = 24;

const List<Color> competitionColor = [Color.fromARGB(50, 200, 50, 0), Color.fromARGB(50, 50, 200, 0)];
