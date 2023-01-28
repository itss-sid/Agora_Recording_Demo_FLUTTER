import 'dart:math';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled_project/strings.dart';

late RtcEngine rtcEngine;
class AgoraFunctions{


  static checkPermission()async{
    await Permission.microphone.request();
    await Permission.phone.request();
    await Permission.storage.request();
  }

  static Future<void> initializeEngine() async {
    checkPermission();
    rtcEngine = createAgoraRtcEngine();
    await rtcEngine.initialize(const RtcEngineContext(appId: agoraAppId, channelProfile: ChannelProfileType.channelProfileLiveBroadcasting, audioScenario: AudioScenarioType.audioScenarioChatroom));
    await rtcEngine.enableAudio();
  }

  static setEventHandler({
    void Function(RtcConnection, int)? joinChannelSuccess,
    void Function(RtcConnection, int, int)? userJoined,
    void Function(RtcConnection, int, UserOfflineReasonType)? userOffline,
    void Function(ErrorCodeType, String)? error,
    void Function(RtcConnection, int, bool)? userMuteAudio,
    void Function(RtcConnection, LocalAudioStreamState, LocalAudioStreamError)? localAudioStateChanged,
    void Function(RtcConnection, RtcStats)? leaveChannel,
    void Function(RtcConnection, RtcStats)? rtcStats,
    void Function(RtcConnection, int, int, Uint8List, int, int)? messageReceived,
  })async{
    rtcEngine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: joinChannelSuccess,
      onUserJoined: userJoined,
      onUserOffline: userOffline,
      onUserMuteAudio: userMuteAudio,
      onError: error,
      onLocalAudioStateChanged: localAudioStateChanged,
      onLeaveChannel: leaveChannel,
      onRtcStats: rtcStats,
      onStreamMessage: messageReceived,
      onStreamMessageError: (RtcConnection, int f, int d, ErrorCodeType t, int ff, int fff){
        print("message error-----------------------");
        print(t.name);

      }
    ));
  }

  static joinChannel({
    required String token,
    required String channelName,
    required int userId
  }) async {
    await rtcEngine.joinChannel(
      token: token,
      channelId: channelName,
      uid: userId,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: ClientRoleType.clientRoleAudience
      ),
    );
  }

  static changeRole()async{
    await rtcEngine.setClientRole(role: ClientRoleType.clientRoleAudience);
  }

  static sendStreamMessage(int id)async{
    var data = Uint8List.fromList(id.toString().codeUnits);
    await rtcEngine.sendStreamMessage(streamId: id, data: data, length: data.length);
  }

  static destroy()async{
    await rtcEngine.leaveChannel();
    await rtcEngine.release();
  }
}