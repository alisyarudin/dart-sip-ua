// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:dart_sip_ua_example/src/user_state/sip_user.dart';
import 'package:dart_sip_ua_example/src/user_state/sip_user_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sip_ua/sip_ua.dart';
import 'models/branch_model.dart';
import '../callscreen.dart';

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

class _CallPageState extends State<CallPage> implements SipUaHelperListener {
  RegistrationState _registerState = RegistrationState();
  bool _isRegistered = false;
  bool _hasNavigatedToCallScreen = false;
  SIPUAHelper? get helper => widget._helper;
  late SipUserCubit currentUser;

  @override
  void initState() {
    super.initState();
    helper?.addSipUaHelperListener(this);

    currentUser = Provider.of<SipUserCubit>(context, listen: false);

    _registerWithBranch(widget.selectedBranch);
  }

  @override
  void dispose() {
    helper?.removeSipUaHelperListener(this);
    super.dispose();
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
      'video': false, // voice only
    };

    MediaStream mediaStream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);

    helper!.call(uri, voiceOnly: true, mediaStream: mediaStream);
  }

  @override
  Widget build(BuildContext context) {
    final branch = widget.selectedBranch;
    return Scaffold(
      appBar: AppBar(
        title: Text('Call to ${branch.displayName}'),
      ),
      backgroundColor: const Color(0xFFF5F6FA),
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
                      children: const [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Anita',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16)),
                            Text('511611',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14)),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.circle, color: Colors.green, size: 12),
                            SizedBox(width: 4),
                            Text('Registered',
                                style: TextStyle(
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
                          Text(
                              "Status: ${_registerState.state?.name ?? 'Loading...'}",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54)),
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

  bool _navigatedToCallScreen = false;

  @override
  void callStateChanged(Call call, CallState callState) {
    debugPrint("callStateChanged: ${callState.state}");

    if (callState.state == CallStateEnum.STREAM && !_navigatedToCallScreen) {
      _navigatedToCallScreen = true;
      Navigator.pushNamed(context, '/callscreen', arguments: call);
    }

    if (callState.state == CallStateEnum.FAILED ||
        callState.state == CallStateEnum.ENDED) {
      _navigatedToCallScreen = false; // reset agar bisa panggil ulang nanti
      // reRegisterWithCurrentUser();
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
