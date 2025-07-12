// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:dart_sip_ua_example/src/branch_storage_helper.dart';
import 'package:dart_sip_ua_example/src/user_state/sip_user.dart';
import 'package:dart_sip_ua_example/src/user_state/sip_user_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sip_ua/sip_ua.dart';
import 'models/branch_model.dart';
import '../callscreen.dart';
import 'package:dart_sip_ua_example/main.dart';

import 'package:android_intent_plus/android_intent.dart';

class CallPage extends StatefulWidget {
  final Branch selectedBranch;
  final SIPUAHelper? _helper;

  const CallPage(
    this._helper, {
    Key? key,
    required this.selectedBranch,
  }) : super(key: key);

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage>
    with WidgetsBindingObserver
    implements SipUaHelperListener {
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  RegistrationState _registerState = RegistrationState();
  bool _isRegistered = false;
  bool _hasNavigatedToCallScreen = false;
  bool _navigatedToCallScreen = false;
  SIPUAHelper? get helper => widget._helper;
  late SipUserCubit currentUser;
  Call? _activeCall;
  @override
  Future<void> launchAppFromCallKit() async {
    const packageName =
        'com.github.cloudwebrtc.dart_sip_ua_example'; // Ganti dengan applicationId kamu jika berbeda
    const activityName =
        'com.github.cloudwebrtc.dart_sip_ua_example.MainActivity';

    final intent = AndroidIntent(
      action: 'android.intent.action.MAIN',
      category: 'android.intent.category.LAUNCHER',
      package: packageName,
      componentName: '$activityName',
    );

    await intent.launch();
  }

  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 👈
    helper?.addSipUaHelperListener(this);

    currentUser = Provider.of<SipUserCubit>(context, listen: false);

    _registerWithBranch(widget.selectedBranch);
    saveLastBranch(widget.selectedBranch);

    // ✅ Tambahkan listener FlutterCallkitIncoming
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
      final evt = event?.event;
      if (evt == null) return;

      switch (evt) {
        case Event.actionCallAccept:
          debugPrint('Call accepted via CallKit');

          // 👇 Buka app jika di background
          await launchAppFromCallKit();
          _checkInitialIncomingCall();

          break;

        case Event.actionCallDecline:
          debugPrint('Call declined via CallKit');
          _activeCall?.hangup();
          break;

        default:
          break;
      }
    });
  }

  Future<void> _checkInitialIncomingCall() async {
    final calls = await FlutterCallkitIncoming.activeCalls();

    if (calls.isNotEmpty && !_navigatedToCallScreen) {
      final callData = calls.first;
      final isIncoming = callData['extra']?['direction'] ==
          'incoming'; // pastikan kamu set ini saat showIncomingCall

      if (_activeCall != null && isIncoming) {
        _navigatedToCallScreen = true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState
              ?.pushNamed('/callscreen', arguments: _activeCall);
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 👈
    helper?.removeSipUaHelperListener(this);
    super.dispose();
  }

  Future<void> saveLastBranch(Branch branch) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('last_branch', jsonEncode(branch.toJson()));
  }

  Future<Branch?> getLastBranch() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('last_branch');
    if (json != null) {
      return Branch.fromJson(jsonDecode(json));
    }
    return null;
  }

  Future<void> _checkCallAndShowCallKit() async {
    if (_activeCall != null &&
        _activeCall!.direction == Direction.incoming &&
        !_navigatedToCallScreen) {
      debugPrint('📞 App minimized while ringing — trigger CallKit again');

      showIncomingCall(
        id: _activeCall!.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _activeCall!.remote_display_name ?? 'Panggilan Masuk',
      );
    }
  }

  Future<void> _checkActiveCallOnResume() async {
    if (_activeCall != null &&
        !_navigatedToCallScreen &&
        (_activeCall!.direction == Direction.incoming ||
            _activeCall!.direction == Direction.outgoing)) {
      debugPrint('↩️ App resumed — navigate to call screen');
      _navigatedToCallScreen = true;
      navigatorKey.currentState
          ?.pushNamed('/callscreen', arguments: _activeCall);
      return;
    }

    final callkitCalls = await FlutterCallkitIncoming.activeCalls();
    if (callkitCalls.isNotEmpty && !_navigatedToCallScreen) {
      debugPrint('📲 Found CallKit call on resume');

      if (_activeCall != null) {
        _navigatedToCallScreen = true;
        navigatorKey.currentState
            ?.pushNamed('/callscreen', arguments: _activeCall);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
    debugPrint('📱 AppLifecycleState: $state');

    if (state == AppLifecycleState.resumed) {
      _checkActiveCallOnResume();
      _registerWithBranch(widget.selectedBranch);
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _checkCallAndShowCallKit(); // saat swipe ke minimize
    }
  }

  void _registerWithBranch(Branch user) {
    currentUser.register(SipUser(
      selectedTransport: TransportType.WS,
      wsExtraHeaders: {},
      sipUri: 'sip:${user.extension}@${_hostFromUrl(user.server)}',
      wsUrl: 'wss://${_hostFromUrl(user.server)}:4398/ws',
      port: user.port,
      displayName: 'Flutter SIP UA',
      password: user.password,
      authUser: user.extension,
    ));
  }

  void showIncomingCall({required String id, required String name}) async {
    final params = CallKitParams(
      id: id,
      nameCaller: name,
      appName: 'Loket CTI',
      avatar: '',
      handle: '082112345678',
      type: 0,
      duration: 30000,
      textAccept: 'Answer',
      textDecline: 'Decline',
      extra: {
        'userId': 'loket-xyz',
        'direction': 'incoming', // ⬅ tambahkan ini
      },
      android: AndroidParams(
        isCustomNotification: false,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        backgroundUrl: '',
        actionColor: '#4CAF50',
      ),
      ios: IOSParams(
        iconName: 'CallKitLogo',
        handleType: '',
        supportsVideo: false,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  String _hostFromUrl(String url) {
    final uri = Uri.parse(url);
    return uri.host;
  }

  Future<void> _makeCall() async {
    if (_registerState.state != RegistrationStateEnum.REGISTERED) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SIP belum terdaftar. Tunggu hingga Registered.'),
        ),
      );
      return;
    }

    final destination = widget.selectedBranch.destinationCall;
    final host = _hostFromUrl(widget.selectedBranch.server);
    final uri = 'sip:$destination@$host';

    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      await Permission.microphone.request();
    }

    var mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': {
        'mandatory': <String, dynamic>{
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
      }
    };

    MediaStream mediaStream;
    bool voiceOnly = true;
    if (kIsWeb && !voiceOnly) {
      mediaStream =
          await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      mediaConstraints['video'] = false;
      MediaStream userStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      final audioTracks = userStream.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        mediaStream.addTrack(audioTracks.first, addToNative: true);
      }
    } else {
      if (voiceOnly) {
        mediaConstraints['video'] = !voiceOnly;
      }
      mediaStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    }

    helper!.call(uri, voiceOnly: voiceOnly, mediaStream: mediaStream);
  }

  @override
  Widget build(BuildContext context) {
    final branch = widget.selectedBranch;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Call to ${branch.displayName}'),
        actions: [
          IconButton(
            icon: Icon(
                Icons.account_tree), // atau Icons.business, sesuai preferensi
            tooltip: 'Back to Branch',
            onPressed: () async {
              await BranchStorageHelper.clearBranch(); // Hapus data branch
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/', // Ganti sesuai route halaman pemilihan branch-mu
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2196F3),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${widget.selectedBranch.extension}",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14)),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                                "${_registerState.state?.name ?? 'Loading...'}",
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 160,
                    left: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 32, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ElevatedButton(
                          //   onPressed: () {
                          //     FlutterRingtonePlayer().play(
                          //       android: AndroidSounds.notification,
                          //       ios: IosSounds.glass,
                          //       looping: true,
                          //       volume: 1.0,
                          //     );
                          //   },
                          //   child: Text('Test Play'),
                          // ),
                          // ElevatedButton(
                          //   onPressed: () {
                          //     FlutterRingtonePlayer().stop();
                          //   },
                          //   child: Text('Test Stop'),
                          // ),
                          Image.asset('assets/logo_175.png', height: 80),
                          const SizedBox(height: 16),
                          const Text('Selamat Datang',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Anda terhubung pada cabang',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(branch.name.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: _makeCall,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.greenAccent.withOpacity(0.5),
                                    Colors.green.withOpacity(0.8),
                                  ],
                                  center: Alignment.center,
                                  radius: 0.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.greenAccent.withOpacity(0.6),
                                    blurRadius: 30,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.phone,
                                    size: 36, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Text(
                          //     "Status: ${_registerState.state?.name ?? 'Loading...'}",
                          //     style: const TextStyle(
                          //         fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    setState(() {
      _registerState = state;
      _isRegistered = state.state == RegistrationStateEnum.REGISTERED;
    });
  }

  @override
  void callStateChanged(Call call, CallState callState) {
    _activeCall = call; // simpan referensi call
    debugPrint("callStateChanged: ${call.direction}");
    // ✅ 1. Tangani panggilan MASUK (hanya showIncomingCall saja, tanpa navigate)
    if (callState.state == CallStateEnum.CALL_INITIATION &&
        !_navigatedToCallScreen &&
        call.direction == Direction.incoming) {
      debugPrint('📞 INCOMING callStateChanged');

      if (_appLifecycleState == AppLifecycleState.resumed) {
        // App sedang foreground, langsung navigate
        _navigatedToCallScreen = true;
        Navigator.pushNamed(context, '/callscreen', arguments: call);
      } else {
        // App sedang background — tampilkan CallKit saja
        showIncomingCall(
          id: call.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: call.remote_display_name ?? 'Panggilan Masuk',
        );
      }
      // ❌ Jangan navigasi langsung di sini — tunggu user tekan Answer
    }

    // ✅ 2. Tangani panggilan KELUAR (langsung masuk call screen)
    if (callState.state == CallStateEnum.CALL_INITIATION &&
        !_navigatedToCallScreen &&
        call.direction == Direction.outgoing) {
      _navigatedToCallScreen = true;
      Navigator.pushNamed(context, '/callscreen', arguments: call);
    }

    // // ✅ 3. Jika call langsung masuk STREAM (fallback untuk web/non-CallKit)
    if (callState.state == CallStateEnum.STREAM &&
        !_navigatedToCallScreen &&
        _appLifecycleState == AppLifecycleState.resumed) {
      _navigatedToCallScreen = true;
      Navigator.pushNamed(context, '/callscreen', arguments: call);
    }

    // ✅ 4. Reset jika call selesai
    if (callState.state == CallStateEnum.FAILED ||
        callState.state == CallStateEnum.ENDED) {
      _navigatedToCallScreen = false;
      _activeCall = null;

      // ✅ Tutup CallKit UI jika masih terbuka
      FlutterCallkitIncoming.endAllCalls();
    }
  }

  void reRegisterWithCurrentUser() async {
    if (helper!.registered) {
      await helper!.unregister();
    }
  }

  @override
  void transportStateChanged(TransportState state) {}
  @override
  void onNewMessage(SIPMessageRequest msg) {}
  @override
  void onNewNotify(Notify ntf) {}
  @override
  void onNewReinvite(ReInvite event) {}
}
