import 'dart:io';
import 'dart:math';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:audio_session/audio_session.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
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

  bool isRegistered = false;
  bool isLoading = true;
  List<UserModel> users = List<UserModel>.empty(growable: true);
  TextEditingController nameController = TextEditingController();
  late UserModel userModel;
  late final RtcEngine engine;
  int selectedUserId = 0;
  RxList<Log> logs = [Log("**********Logs Started**********", Colors.blue.shade900)].obs;
  RxList<int> joinedUsersIds = List<int>.empty(growable: true).obs;
  RxBool speakerOn = false.obs;
  var usersScrollController = ScrollController();
  var logsScrollController = ScrollController();
  var recorder = Record();
  FlutterSoundRecorder recorderr = FlutterSoundRecorder();
  Codec _codec = Codec.aacMP4;
  String _mPath = 'tau_file.mp4';

  @override
  void initState() {
    openTheRecorder();
    initializeAgora();
    getAgoraToken();
    super.initState();
  }

  Future<void> openTheRecorder() async {
    // if (!kIsWeb) {
    //   var status = await Permission.microphone.request();
    //   if (status != PermissionStatus.granted) {
    //     throw RecordingPermissionException('Microphone permission not granted');
    //   }
    // }
    await recorderr.openRecorder();
    if (!await recorderr.isEncoderSupported(_codec)) {
      _codec = Codec.opusWebM;
      _mPath = 'tau_file.webm';
      if (!await recorderr.isEncoderSupported(_codec)) {
        return;
      }
    }
    final session = await AudioSession.instance;
    // await session.configure(const AudioSessionConfiguration.speech());
    // await session.configure(AudioSessionConfiguration(
    //   avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
    //   avAudioSessionCategoryOptions:
    //   AVAudioSessionCategoryOptions.allowBluetooth |
    //   AVAudioSessionCategoryOptions.defaultToSpeaker,
    //   avAudioSessionMode: AVAudioSessionMode.spokenAudio,
    //   avAudioSessionRouteSharingPolicy:
    //   AVAudioSessionRouteSharingPolicy.defaultPolicy,
    //   avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
    //   androidAudioAttributes: const AndroidAudioAttributes(
    //     contentType: AndroidAudioContentType.speech,
    //     flags: AndroidAudioFlags.none,
    //     usage: AndroidAudioUsage.voiceCommunication,
    //   ),
    //   androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    //   androidWillPauseWhenDucked: true,
    // ));

    // _mRecorderIsInited = true;
  }

  @override
  void dispose() {
    engine.leaveChannel();
    engine.destroy();
    for(var user in users){
      if(userModel.id == user.id){
        FirebaseDatabase.instance.ref().child('demo').child('users').child(user.key).remove();
        break;
      }
    }
    try{
      if(userModel.name=="admin"){
        recorder.isRecording().then((value) {
          if(value){
            recorder.stop();
          }
        });
      }
    } catch(_){}
    recorder.isRecording().then((value) {
      if(value){
        stopAudioRecording();
      }
    });
    if (recorderr.isRecording) recorderr.stopRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async=>false,
      child: Scaffold(
        backgroundColor: Colors.white60,
        body: isRegistered? streamBuilder() : registerLayout()
      ),
    );
  }


  initializeAgora()async{
    engine = await RtcEngine.createWithContext(RtcEngineContext(agoraAppId));
    await engine.enableAudio();
    await Permission.microphone.request();
    await Permission.phone.request();
    await Permission.storage.request();

    engine.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (String channel, int uid, int elapsed) {
        logs.add(Log("channel joined!", Colors.green.shade900));
        logs.add(Log("channel: $channel", Colors.black));
        logs.add(Log("userId: $uid", Colors.black));
        startAudioRecording();
        if(userModel.name!="admin"){
          engine.muteLocalAudioStream(true);
        }
      },
      userJoined: (int uid, int elapsed) {
        logs.add(Log("user joined!", Colors.green.shade900));
        logs.add(Log("userId: $uid", Colors.black));
        if(userModel.name != "admin"){
          for(var user in users){
            if(user.id == uid){
              if(user.name == "admin"){
                logs.add(Log("ADMIN: $uid", Colors.blue.shade900));
              } else {
                engine.muteRemoteAudioStream(uid, true);
              }
              break;
            }
          }
        }
        joinedUsersIds.add(uid);
        engine.setEnableSpeakerphone(true);
        scrollToEnd();
      },
      userOffline: (int uid, UserOfflineReason reason) {
        logs.add(Log("user offline!", Colors.green.shade900));
        logs.add(Log("userId: $uid", Colors.black));
        logs.add(Log("reason: ${reason.name}", Colors.black));
        joinedUsersIds.remove(uid);
        scrollToEnd();
      },
      leaveChannel: (RtcStats states){
        stopAudioRecording();
        logs.add(Log("channel left!", Colors.green.shade900));
        logs.add(Log("users count: ${states.userCount}", Colors.black));
      },
      // localAudioStateChanged: (AudioLocalState state, AudioLocalError error){
      //   logs.add(Log("audio state changed!", Colors.green.shade900));
      //   logs.add(Log("state: $state", Colors.black));
      //   logs.add(Log("error: $error", Colors.black));
      //   scrollToEnd();
      // },
      userMuteAudio: (int uid, bool muted){
        logs.add(Log("user muted state changed!", Colors.green.shade900));
        logs.add(Log("userId: $uid", Colors.black));
        logs.add(Log("muted: $muted", Colors.black));
        scrollToEnd();
      },
      error: (ErrorCode code){
        logs.add(Log("Error!", Colors.green.shade900));
        logs.add(Log("Error: ${code.name}", Colors.black));
        scrollToEnd();
      },
    ));
  }

  joinChannel() async{
    // await engine.joinChannel(
    //   token: agoraToken,
    //   channelId: 'test',
    //   uid: Random().nextInt(10),
    //   options: const ChannelMediaOptions(
    //     channelProfile: ChannelProfileType.channelProfileCommunication,
    //     clientRoleType: ClientRoleType.clientRoleAudience
    //   ),
    // );
    await engine.joinChannel(agoraToken,'test', null, userModel.id, ChannelMediaOptions());
  }

  Widget streamBuilder() {
    return SafeArea(
      child: StreamBuilder(
        stream: getUsers(),
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting){
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            if(snapshot.hasData){
              users = snapshot.data as List<UserModel>;
              if(users.isEmpty){
                return errorWidget();
              } else {
                return Obx(()=>Column(
                  children: [
                    TextButton(
                        onPressed: ()async{
                          await engine.leaveChannel();
                          Get.offAll(()=>const Splash());
                        },
                        style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                                side: BorderSide(
                                    color: Colors.red.shade900,
                                    width: 1
                                )
                            )
                        ),
                        child: Text("Leave", style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),)
                    ),
                    const SizedBox(height: 15,),
                    const Text("All Users:"),
                    SizedBox(
                      width: width,
                      height: 85,
                      child: ListView.builder(
                        itemCount: users.length,
                        scrollDirection: Axis.horizontal,
                        controller: usersScrollController,
                        itemBuilder: (
                            BuildContext context, int index) {
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
                                                      color: selectedUserId==users[index].id? Colors.blue.shade900: joinedUsersIds.contains(users[index].id)?Colors.green.shade900:Colors.black,
                                                      width: 2
                                                  )
                                              ),
                                              child: Icon(Icons.person, color: selectedUserId==users[index].id? Colors.blue.shade900: joinedUsersIds.contains(users[index].id)?Colors.green.shade900:Colors.black),
                                            ),),
                                            TextSpan(text: "\n${users[index].name}", style: TextStyle(color: selectedUserId==users[index].id? Colors.blue.shade900: joinedUsersIds.contains(users[index].id)?Colors.green.shade900:Colors.black))
                                          ]))
                              ),
                            ),
                          );
                        },),
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
                                return Text(logs[index].value, textAlign: TextAlign.center, style: TextStyle(color: logs[index].color),);
                              },
                            ),
                          ),
                          TextButton(
                              onPressed: ()async{
                                speakerOn.value = !speakerOn.value;
                                await engine.setEnableSpeakerphone(speakerOn.value);
                                if(speakerOn.value){
                                  await engine.adjustPlaybackSignalVolume(400);
                                  await engine.adjustRecordingSignalVolume(400);
                                  await engine.setInEarMonitoringVolume(400);
                                }
                              },
                              style: TextButton.styleFrom(
                                  shape: CircleBorder(
                                      side: BorderSide(
                                          color: speakerOn.value? Colors.green.shade900:Colors.red.shade900,
                                          width: 1
                                      )
                                  )
                              ),
                              child: Icon(Icons.volume_down_outlined,color: speakerOn.value? Colors.green.shade900:Colors.red.shade900,)
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15,),
                    Visibility(
                      visible: userModel.name=="admin"?false:true,
                      child: GestureDetector(
                        // onTap: ()=>rec(),
                        onLongPressStart: (d)async{
                          engine.muteLocalAudioStream(false);
                        },
                        onLongPressEnd: (d) async {
                          engine.muteLocalAudioStream(true);
                        },
                        child: micWidget(),
                      ),
                    ),
                    const SizedBox(height: 25,)
                  ],
                ));
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          const Text(
              "Please register yourself before using this demo!",
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 25,),
          TextFormField(
            controller: nameController,
            onChanged: (txt)=>setState(() {}),
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
              constraints: BoxConstraints(
                maxWidth: width*.90
              ),
              border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(5)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 25,),
          ElevatedButton(
              onPressed: nameController.text.isEmpty?
              null : () async {
                String? token = await FirebaseMessaging.instance.getToken();
                UserModel user = UserModel(name: nameController.text, token: "$token", id: Random().nextInt(999), key: "");
                await FirebaseDatabase.instance.ref().child('demo').child('users').push().set(user.toJson());
                setState(() {
                  selectedUserId = user.id;
                  userModel = user;
                  isRegistered = true;
                });
                joinChannel();
                },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 15),
                  shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(35))),
              child: const Text(
                "Submit",
                style: TextStyle(fontSize: 16),
              )
          ),
          const Spacer(),
        ],
      ),
    );
  }

  scrollToEnd()async{
    if(mounted){
      await Future.delayed(const Duration(milliseconds: 500));
      if (usersScrollController.positions.isNotEmpty) usersScrollController.animateTo(usersScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
      if (logsScrollController.positions.isNotEmpty) logsScrollController.animateTo(logsScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
    }
  }

  startAudioRecording() async {
    var dateTime = DateTime.now();
    String random = "${dateTime.month}_${dateTime.day}-${dateTime.hour}_${dateTime.minute}_${dateTime.second}";
    try{
      var dir = Directory("/storage/emulated/0/Download/Test");
      if(!dir.existsSync()){
        await dir.create();
      }
    } catch(_){}
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

  stopAudioRecording()async{
    // if(await recorder.isRecording()){
    //   await recorder.stop();
    // }
    await recorderr.stopRecorder();
  }
}
