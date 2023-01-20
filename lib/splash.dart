import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled_project/home.dart';

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {

  @override
  void initState() {
    ok();
    super.initState();
  }

  ok()async{
    await Future.delayed(const Duration(seconds: 1));
    Get.offAll(()=> const Home());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white60,
      body: Center(child: CircularProgressIndicator(),),
    );
  }
}
