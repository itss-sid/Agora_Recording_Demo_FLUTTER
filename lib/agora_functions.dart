import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled_project/strings.dart';

late RtcEngine rtcEngine;
class AgoraFunctions{

  static checkPermission()async{
    await Permission.microphone.request();
  }

  static Future<void> initializeEngine() async {
    checkPermission();
    rtcEngine = await RtcEngine.createWithContext(RtcEngineContext(agoraAppId));
    await rtcEngine.enableAudio();
  }

  static setEventHandler({
    void Function(String, int, int)? joinChannelSuccess,
    void Function(int, int)? userJoined,
    void Function(int, UserOfflineReason)? userOffline,
    void Function(ErrorCode)? error,
    void Function(int, bool)? userMuteAudio,
    void Function(AudioLocalState, AudioLocalError)? localAudioStateChanged,
    void Function(RtcStats)? leaveChannel,
    void Function(RtcStats)? rtcStats,
  })async{
    rtcEngine.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: joinChannelSuccess,
      userJoined: userJoined,
      userOffline: userOffline,
      userMuteAudio: userMuteAudio,
      error: error,
      localAudioStateChanged: localAudioStateChanged,
      leaveChannel: leaveChannel,
      rtcStats: rtcStats,
    ));
  }

  static joinChannel({
    required String token,
    required String channelName,
    required int userId,
    String? optionalInfo,
    ChannelMediaOptions? options
  }) async {
    await rtcEngine.joinChannel(token,channelName, optionalInfo, userId, options);
  }

  static destroy()async{
    await rtcEngine.destroy();
  }
}