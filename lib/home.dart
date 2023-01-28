import 'dart:io';
import 'dart:math';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:untitled_project/agora_functions.dart';
import 'package:untitled_project/splash.dart';
import 'functions.dart';
import 'package:flutter/material.dart';
import 'package:untitled_project/strings.dart';
import 'package:untitled_project/user_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  bool isRegistered = false, isLoading = true;
  List<UserModel> users = List<UserModel>.empty(growable: true);
  // TextEditingController nameController = TextEditingController();
  String name = "";
  late UserModel userModel;
  int selectedUserId = 0;
  RxList<Log> logs = [Log("**********Logs Started**********", Colors.blue.shade900)].obs;
  RxList<int> joinedUsersIds = List<int>.empty(growable: true).obs;
  RxBool speakerOn = false.obs, micOn = false.obs;
  var usersScrollController = ScrollController();
  var logsScrollController = ScrollController();
  var recorder = Record();
  FlutterSoundRecorder recorderr = FlutterSoundRecorder();

  @override
  void initState() {
    openTheRecorder();
    initializeAgora();
    getAgoraToken();
    super.initState();
  }

  Future<void> openTheRecorder() async {
    await recorderr.openRecorder();
  }

  @override
  void dispose() {
    AgoraFunctions.destroy();
    for (var user in users) {
      if (userModel.id == user.id) {
        FirebaseDatabase.instance.ref().child('demo').child('users').child(user.key).remove();
        break;
      }
    }
    try {
      if (userModel.name == "admin") {
        recorder.isRecording().then((value) {
          if (value) {
            recorder.stop();
          }
        });
      }
    } catch (_) {}
    recorder.isRecording().then((value) {
      if (value) {
        stopAudioRecording();
      }
    });
    if (recorderr.isRecording) recorderr.stopRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
          backgroundColor: Colors.white60,
          body: isRegistered ? streamBuilder() : registerLayout()),
    );
  }

  initializeAgora() async {
    await AgoraFunctions.initializeEngine();
    await AgoraFunctions.setEventHandler(
      joinChannelSuccess: (RtcConnection connection, int elapsed){
        logs.add(Log("channel joined!", Colors.green.shade900));
        startAudioRecording();
        if (userModel.name != "admin") {
          rtcEngine.muteLocalAudioStream(true);
        }
        rtcEngine.setEnableSpeakerphone(true);
        rtcEngine.adjustPlaybackSignalVolume(400);
        rtcEngine.adjustRecordingSignalVolume(400);
        rtcEngine.setInEarMonitoringVolume(400);
      },
      userJoined: (RtcConnection connection, int uid, int elapsed) {
        logs.add(Log("user joined!", Colors.green.shade900));
        logs.add(Log("userId: $uid", Colors.black));
        muteUser(uid);
        joinedUsersIds.add(uid);
        scrollToEnd();
      },
      userOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
        logs.add(Log("user offline!", Colors.green.shade900));
        logs.add(Log("userId: $uid", Colors.black));
        logs.add(Log("reason: ${reason.name}", Colors.black));
        joinedUsersIds.remove(uid);
        scrollToEnd();
      },
      userMuteAudio: (RtcConnection connection, int uid, bool muted) {
        logs.add(Log("user $uid ${muted?"muted":"unmuted"} audio", Colors.green.shade900));
        scrollToEnd();
      },
      error: (ErrorCodeType errorCode, String msg) {
        logs.add(Log("Error!", Colors.green.shade900));
        logs.add(Log("ErrorCode: ${errorCode.name}", Colors.black));
        logs.add(Log("Message: $msg", Colors.black));
        scrollToEnd();
      },
      leaveChannel: (RtcConnection connection, RtcStats stats) {
        stopAudioRecording();
        logs.add(Log("channel left!", Colors.green.shade900));
        logs.add(Log("users count: ${stats.userCount}", Colors.black));
      },
    );
  }

  Widget streamBuilder() {
    return SafeArea(
      child: StreamBuilder(
        stream: getUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            if (snapshot.hasData) {
              users = snapshot.data as List<UserModel>;
              if (users.isEmpty) {
                return errorWidget();
              } else {
                return Obx(() => Column(
                      children: [
                        TextButton(
                            onPressed: () async {
                              await rtcEngine.leaveChannel();
                              Get.offAll(() => const Splash());
                            },
                            style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                    side: BorderSide(
                                        color: Colors.red.shade900, width: 1,
                                    )
                                )
                            ),
                            child: Text(
                              "Leave",
                              style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontWeight: FontWeight.bold
                              ),
                            )
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        const Text("All Users:"),
                        SizedBox(
                          width: width,
                          height: 85,
                          child: ListView.builder(
                            itemCount: users.length,
                            scrollDirection: Axis.horizontal,
                            controller: usersScrollController,
                            itemBuilder: (BuildContext context, int index) {
                              removeUser(index);
                              return InkWell(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SizedBox(
                                      width: 50,
                                      child: RichText(
                                          maxLines: 2,
                                          textAlign: TextAlign.center,
                                          text: TextSpan(
                                              children: [
                                            WidgetSpan(
                                              child: Container(
                                                height: 50,
                                                width: 50,
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                        color: selectedUserId == users[index].id
                                                            ? Colors.blue.shade900
                                                            : joinedUsersIds.contains(users[index].id)
                                                                ? Colors.green.shade900
                                                                : Colors.black,
                                                        width: 2)
                                                ),
                                                child: Icon(Icons.person,
                                                    color: selectedUserId == users[index].id
                                                        ? Colors.blue.shade900
                                                        : joinedUsersIds.contains(users[index].id)
                                                            ? Colors.green.shade900
                                                            : Colors.black
                                                ),
                                              ),
                                            ),
                                            TextSpan(
                                                text: "\n${users[index].name}",
                                                style: TextStyle(
                                                    color: selectedUserId == users[index].id
                                                        ? Colors.blue.shade900
                                                        : joinedUsersIds.contains(users[index].id)
                                                            ? Colors.green.shade900
                                                            : Colors.black
                                                )
                                            )
                                          ])
                                      )
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  itemCount: logs.length,
                                  padding: const EdgeInsets.all(20),
                                  shrinkWrap: true,
                                  controller: logsScrollController,
                                  itemBuilder: (BuildContext context, int index) {
                                    return Text(
                                      logs[index].value,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: logs[index].color),
                                    );
                                  },
                                ),
                              ),
                              // TextButton(
                              //     onPressed: () async {
                              //       speakerOn.value = !speakerOn.value;
                              //       await rtcEngine.setEnableSpeakerphone(speakerOn.value);
                              //       if (speakerOn.value) {
                              //         await rtcEngine.adjustPlaybackSignalVolume(400);
                              //         await rtcEngine.adjustRecordingSignalVolume(400);
                              //         await rtcEngine.setInEarMonitoringVolume(400);
                              //       }
                              //     },
                              //     style: TextButton.styleFrom(
                              //         shape: CircleBorder(
                              //             side: BorderSide(
                              //                 color: speakerOn.value
                              //                     ? Colors.green.shade900
                              //                     : Colors.red.shade900,
                              //                 width: 1
                              //             )
                              //         )
                              //     ),
                              //     child: Icon(
                              //       Icons.volume_down_outlined,
                              //       color: speakerOn.value
                              //           ? Colors.green.shade900
                              //           : Colors.red.shade900,
                              //     )
                              // ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        Visibility(
                          visible: !(userModel.name == "admin"),
                          child: GestureDetector(
                            // onTap: ()=>rec(),
                            onLongPressStart: (d) async {
                              await rtcEngine.muteLocalAudioStream(false);
                              micOn.value = true;
                            },
                            onLongPressEnd: (d) async {
                              await rtcEngine.muteLocalAudioStream(true);
                              micOn.value = false;
                            },
                            child: micWidget(micOn.value),
                          ),
                        ),
                        const SizedBox(
                          height: 25,
                        )
                      ],
                    )
                );
              }
            } else {
              return errorWidget();
            }
          }
        },
      ),
    );
  }

  Widget registerLayout() {
    return registrationLayout(
        (text)=>setState(()=>name=text),
      name.isEmpty
        ? null
        : () async {
      String? token = await FirebaseMessaging.instance.getToken();
      UserModel user = UserModel(
          name: name,
          token: "$token",
          id: Random().nextInt(999),
          key: ""
      );
      await FirebaseDatabase.instance.ref().child('demo').child('users').push().set(user.toJson());
      setState(() {
        selectedUserId = user.id;
        userModel = user;
        isRegistered = true;
      });
      await AgoraFunctions.joinChannel(token: agoraToken, channelName: 'test', userId: Random().nextInt(999),);
    },
    );
  }

  scrollToEnd() async {
    scroll2End(mounted, usersScrollController, logsScrollController);
  }

  startAudioRecording() async {
    var dateTime = DateTime.now();
    String random =
        "${dateTime.month}_${dateTime.day}-${dateTime.hour}_${dateTime.minute}_${dateTime.second}";
    try {
      var dir = Directory("/storage/emulated/0/Download/Test");
      if (!dir.existsSync()) {
        await dir.create();
      }
    } catch (_) {}
    // await recorder.start(
    //   path: '/storage/emulated/0/Download/Test/recording-$random.m4a',
    //   encoder: AudioEncoder.aacLc, // by default
    //   bitRate: 128000, // by default
    //   samplingRate: 44100, // by default
    //   device: const InputDevice(id: "7", label: 'voice_communication')
    // );
    await recorderr.startRecorder(
      codec: Codec.aacMP4,
      toFile: '/storage/emulated/0/Download/Test/recording-$random.m4a',
      audioSource: AudioSource.unprocessed,
    );
  }

  stopAudioRecording() async {
    // if(await recorder.isRecording()){
    //   await recorder.stop();
    // }
    await recorderr.stopRecorder();
  }

  removeUser(int index) async {
    await Future.delayed(const Duration(seconds: 2));
    try{
      var shouldRemove = selectedUserId != users[index].id && !joinedUsersIds.contains(users[index].id);
      if(shouldRemove){
        FirebaseDatabase.instance.ref().child('demo').child('users').child(users[index].key).remove();
      }
    } catch(_){}
  }

  muteUser(int uid) async {
    await Future.delayed(const Duration(seconds: 1));
    if (userModel.name != "admin") {
      for (var user in users) {
        if (user.id == uid) {
          if (user.name == "admin") {
            logs.add(Log("ADMIN: $uid", Colors.blue.shade900));
          } else {
            rtcEngine.muteRemoteAudioStream(uid: uid, mute: true,);
            logs.add(Log("USER MUTED: $uid", Colors.blue.shade900));
          }
          break;
        }
      }
    }
  }
}