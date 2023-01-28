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
