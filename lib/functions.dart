import 'home.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:untitled_project/strings.dart';
import 'package:untitled_project/user_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';

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

Widget micWidget(bool isOn){
  return Container(
    width: 100,
    height: 100,
    decoration: BoxDecoration(
      color: isOn?Colors.white:Colors.black,
      borderRadius: BorderRadius.circular(150),
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
    child: Icon(
      Icons.mic,
      size: 40,
      color: isOn?Colors.black:Colors.amber,
    ),
  );
}

Future<String> getAgoraToken() async {
  var snapshot = await FirebaseDatabase.instance.ref("agora").get();
  agoraToken = snapshot.value as String;
  return agoraToken;
}

Widget registrationLayout(Function(String text) onChanged, Function()? onPressed){
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),
        const Text(
          "Please register yourself before using this demo!",
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: 25,
        ),
        TextFormField(
          // controller: nameController,
          onChanged: onChanged,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            fillColor: Colors.grey.shade100,
            filled: true,
            hintText: "Any Name or Random String",
            isDense: true,
            counterText: '',
            hintStyle: const TextStyle(fontSize: 12),
            constraints: BoxConstraints(maxWidth: width * .90),
            border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(5)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(
          height: 25,
        ),
        ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 15),
                shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(35))),
            child: const Text(
              "Submit",
              style: TextStyle(fontSize: 16),
            )),
        const Spacer(),
      ],
    ),
  );
}

scroll2End(var mounted, var usersScrollController, var logsScrollController) async {
  if (mounted) {
    await Future.delayed(const Duration(milliseconds: 500));
    if (usersScrollController.positions.isNotEmpty) {
      usersScrollController.animateTo(
          usersScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.decelerate);
    }
    if (logsScrollController.positions.isNotEmpty) {
      logsScrollController.animateTo(
          logsScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.decelerate);
    }
  }
}

AudioSource getSource(UserModel userModel){
  var source = AudioSource.unprocessed;
  if(userModel.name == "one"){
    source = AudioSource.defaultSource;
  } else if(userModel.name == "two"){
    source = AudioSource.microphone;
  } else if(userModel.name == "three"){
    source = AudioSource.voiceDownlink;
  } else if(userModel.name == "four"){
    source = AudioSource.camCorder;
  } else if(userModel.name == "five"){
    source = AudioSource.remote_submix;
  } else if(userModel.name == "six"){
    source = AudioSource.unprocessed;
  } else if(userModel.name == "seven"){
    source = AudioSource.voice_call;
  } else if(userModel.name == "eight"){
    source = AudioSource.voice_communication;
  } else if(userModel.name == "nine"){
    source = AudioSource.voice_performance;
  } else if(userModel.name == "ten"){
    source = AudioSource.voice_recognition;
  } else if(userModel.name == "eleven"){
    source = AudioSource.voiceUpLink;
  } else if(userModel.name == "twelve"){
    source = AudioSource.bluetoothHFP;
  } else if(userModel.name == "thirteen"){
    source = AudioSource.headsetMic;
  } else if(userModel.name == "fourteen"){
    source = AudioSource.lineIn;
  }
  return source;
}

String getSourceName(UserModel userModel){
  var name = "unprocessed";
  if(userModel.name == "one"){
    name = "defaultSource";
  } else if(userModel.name == "two"){
    name = "microphone";
  } else if(userModel.name == "three"){
    name = "voiceDownlink";
  } else if(userModel.name == "four"){
    name = "camCorder";
  } else if(userModel.name == "five"){
    name = "remote_submix";
  } else if(userModel.name == "six"){
    name = "unprocessed";
  } else if(userModel.name == "seven"){
    name = "voice_call";
  } else if(userModel.name == "eight"){
    name = "voice_communication";
  } else if(userModel.name == "nine"){
    name = "voice_performance";
  } else if(userModel.name == "ten"){
    name = "voice_recognition";
  } else if(userModel.name == "eleven"){
    name = "voiceUpLink";
  } else if(userModel.name == "twelve"){
    name = "bluetoothHFP";
  } else if(userModel.name == "thirteen"){
    name = "headsetMic";
  } else if(userModel.name == "fourteen"){
    name = "lineIn";
  }
  return name;
}
