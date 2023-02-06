import 'home.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:untitled_project/strings.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main()async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseMessaging.instance.getToken();
  runApp(
      GetMaterialApp(
        navigatorKey: navigatorKey,
          home: const Home()
  ));
}
