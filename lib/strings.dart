import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final double height = MediaQuery.of(navigatorKey.currentContext!).size.height;
final double width = MediaQuery.of(navigatorKey.currentContext!).size.width;

const String agoraAppId = "e28faca86c6c4ee39c74742583682906";
String agoraToken = "";