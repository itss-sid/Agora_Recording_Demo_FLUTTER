import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled_project/strings.dart';
import 'package:untitled_project/user_model.dart';
import 'home.dart';

Stream<List<UserModel>> getUsers() {
  return FirebaseDatabase.instance.ref().child('demo').child('users').onValue.map((event) {
    List<UserModel> users = [];
    for (DataSnapshot user in event.snapshot.children) {
      UserModel temp = UserModel.fromJson(user.value);
      temp.key = user.key!;
      users.add(temp);
    }
    return users;
  });
}

Widget errorWidget(){
  return Center(
      child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
              children: [
                const TextSpan(text: "ERROR HAS OCCURRED\n", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),),
                WidgetSpan(child: IconButton(
                    onPressed: (){
                      Get.offAll(()=>const Home());
                    },
                    iconSize: 50,
                    icon: const Icon(Icons.refresh)
                ))
              ]
          ))
  );
}

Widget micWidget(){
  return Container(
    width: 100,
    height: 100,
    decoration: BoxDecoration(
      color: const Color(0xff333333),
      borderRadius: BorderRadius.circular(150),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xff111111),
          Color(0xff555555),
        ],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0xff555555),
          offset: Offset(-25.9, -25.9),
          blurRadius: 50,
          spreadRadius: 0.0,
        ),
        BoxShadow(
          color: Color(0xff111111),
          offset: Offset(25.9, 25.9),
          blurRadius: 50,
          spreadRadius: 0.0,
        ),
      ],
    ),
    child: const Icon(
      Icons.mic,
      size: 40,
      color: Colors.amber,
    ),
  );
}

Future<String> getAgoraToken() async {
  var snapshot = await FirebaseDatabase.instance.ref("agora").get();
  agoraToken = snapshot.value as String;
  return agoraToken;
}

connectChannel(){

}
