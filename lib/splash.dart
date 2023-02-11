import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:untitled_project/home.dart';
import 'package:untitled_project/strings.dart';

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {

  bool error = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {init();});
    super.initState();
  }

  init()async{
    setState(()=> error = false);
    var response = await Dio().get("http://103.175.163.97:8000/getToken");
    if(response.data["status"] == 1){
      agoraToken = response.data["data"].toString();
      await Future.delayed(const Duration(seconds: 2));
      Get.offAll(()=> const Home());
    } else {
      setState(()=> error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white60,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error? "Error Occurred" : "Fetching Latest Agora Token", style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),),
            const SizedBox(height: 3,),
            Text(error? "Please try again..." : "Please wait...", style: const TextStyle(fontSize: 20,),),
            const SizedBox(height: 10,),
            error? IconButton(onPressed: ()=> init(), iconSize: 50, icon: const Icon(Icons.refresh, color: Colors.red,)):
            const CircularProgressIndicator(color: Colors.black,),
          ],
        ),
      ),
    );
  }
}
