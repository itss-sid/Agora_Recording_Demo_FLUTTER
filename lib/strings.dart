import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final double height = MediaQuery.of(navigatorKey.currentContext!).size.height;
final double width = MediaQuery.of(navigatorKey.currentContext!).size.width;

const String agoraAppId = "2aba500053af421ebb693c5e116a8198";
String agoraToken = "";