import 'dart:async';
import 'package:dart_sip_ua_example/src/notification_helper.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import './incoming_call_native.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sip_ua/sip_ua.dart';

import 'widgets/action_button.dart';

class CallScreenWidget extends StatefulWidget {
  final SIPUAHelper? _helper;
  final Call? _call;

  CallScreenWidget(this._helper, this._call, {Key? key}) : super(key: key);

  @override
  State<CallScreenWidget> createState() => _CallScreenWidgetState();
}

class _CallScreenWidgetState extends State<CallScreenWidget>
    implements SipUaHelperListener {
  MediaStream? _localStream;
  final ValueNotifier<String> _timeLabel = ValueNotifier<String>('00:00');
  bool _audioMuted = false;
  bool _speakerOn = false;
  bool _hold = false;
  bool _showNumPad = false;
  bool _callConfirmed = false;
  CallStateEnum _state = CallStateEnum.NONE;
  Originator? _holdOriginator;
  late String _transferTarget;
  late Timer _timer;
  bool _disposed = false;

  SIPUAHelper? get helper => widget._helper;
  Call? get call => widget._call;
  String? get remoteIdentity => call?.remote_identity;
  Direction? get direction => call?.direction;

  @override
  void initState() {
    super.initState();
    helper?.addSipUaHelperListener(this);
    _startTimer();
    NotificationHelper.init(); // init notification
    if (direction == Direction.incoming) {
      _playRingtone();
      // Start ringtone
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer.cancel();
    _stopRingtone();
    helper?.removeSipUaHelperListener(this);
    _cleanUp();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      final duration = Duration(seconds: timer.tick);
      if (mounted && !_disposed) {
        _timeLabel.value = [duration.inMinutes, duration.inSeconds]
            .map((seg) => seg.remainder(60).toString().padLeft(2, '0'))
            .join(':');
      } else {
        _timer.cancel();
      }
    });
  }

  void _cleanUp() {
    if (_localStream == null) return;
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;
  }

  Future<void> _playRingtone() async {
    IncomingCallNative.play();
  }

  Future<void> _stopRingtone() async {
    IncomingCallNative.stop();
  }

  void _handleAccept() async {
    final mediaConstraints = {'audio': true, 'video': false};
    final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    call?.answer(helper!.buildCallOptions(true), mediaStream: stream);
    _localStream = stream;

    if (!kIsWeb && _localStream != null) {
      // ✅ Pastikan speaker dimatikan saat call dimulai
      _localStream!.getAudioTracks()[0].enableSpeakerphone(false);
    }
  }

  void _handleHangup() {
    call?.hangup({'status_code': 603});
    _timer.cancel();
  }

  void _handleHold() {
    _hold ? call?.unhold() : call?.hold();
  }

  void _muteAudio() {
    _audioMuted ? call?.unmute(true, false) : call?.mute(true, false);
  }

  void _toggleSpeaker() {
    _speakerOn = !_speakerOn;
    if (!kIsWeb && _localStream != null) {
      _localStream!.getAudioTracks()[0].enableSpeakerphone(_speakerOn);
    }
    setState(() {});
  }

  void _handleTransfer() {
    String input = '';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transfer panggilan'),
        content: TextField(
          onChanged: (value) => input = value.trim(),
          decoration: InputDecoration(hintText: 'URI or Username'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Batal')),
          TextButton(
              onPressed: () {
                if (input.isNotEmpty) {
                  _transferTarget = input;
                  call?.refer(_transferTarget);
                  Navigator.pop(context);
                }
              },
              child: Text('OK')),
        ],
      ),
    );
  }

  void _handleKeyPad() {
    setState(() => _showNumPad = !_showNumPad);
  }

  void _handleDtmf(String tone) {
    call?.sendDTMF(tone);
  }

  @override
  void callStateChanged(Call call, CallState state) {
    if (_disposed) return;
    debugPrint("callStateChanged: ${call.direction}");
    if (state.state == CallStateEnum.PROGRESS &&
        call.direction == Direction.incoming) {
      // ✅ Tampilkan notifikasi callkit
      // Tambahkan delay atau handler untuk lanjut ke call screen jika jawab
      // Bisa juga dipindah ke FlutterCallkitIncoming.onEvent listener
      _playRingtone(); // Start ringtone
    }

    if (state.state == CallStateEnum.HOLD ||
        state.state == CallStateEnum.UNHOLD) {
      _hold = state.state == CallStateEnum.HOLD;
      _holdOriginator = state.originator;
      if (mounted) setState(() {});
      return;
    }

    if (state.state == CallStateEnum.MUTED ||
        state.state == CallStateEnum.UNMUTED) {
      if (state.audio != null) _audioMuted = state.audio!;
      if (mounted) setState(() {});
      return;
    }

    if (state.state != CallStateEnum.STREAM) {
      _state = state.state;
    }

    switch (state.state) {
      case CallStateEnum.STREAM:
        _stopRingtone();
        _handleStreams(state);
        break;
      case CallStateEnum.ENDED:
      case CallStateEnum.FAILED:
        _stopRingtone();
        _backToDialPad();
        break;
      case CallStateEnum.ACCEPTED:
      case CallStateEnum.CONFIRMED:
        _stopRingtone(); // Stop ringtone when answered or ended
        setState(() => _callConfirmed = true);
        break;
      default:
        break;
    }
  }

  void _handleStreams(CallState state) {
    if (state.originator == Originator.local) {
      _localStream = state.stream;
    }
  }

  void _backToDialPad() {
    _timer.cancel();
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
    _cleanUp();
  }

  List<Widget> _buildNumPad() {
    final labels = [
      [
        {'1': ''},
        {'2': 'abc'},
        {'3': 'def'}
      ],
      [
        {'4': 'ghi'},
        {'5': 'jkl'},
        {'6': 'mno'}
      ],
      [
        {'7': 'pqrs'},
        {'8': 'tuv'},
        {'9': 'wxyz'}
      ],
      [
        {'*': ''},
        {'0': '+'},
        {'#': ''}
      ],
    ];
    return labels
        .map((row) => Padding(
              padding: const EdgeInsets.all(3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row
                    .map((label) => ActionButton(
                          title: label.keys.first,
                          subTitle: label.values.first,
                          number: true,
                          onPressed: () => _handleDtmf(label.keys.first),
                        ))
                    .toList(),
              ),
            ))
        .toList();
  }

  Widget _buildActionButtons() {
    final basic = <Widget>[];
    final advanced = <Widget>[];

    final hangupBtn = ActionButton(
      title: "hangup",
      onPressed: _handleHangup,
      icon: Icons.call_end,
      fillColor: Colors.red,
    );

    switch (_state) {
      case CallStateEnum.CONNECTING:
      case CallStateEnum.NONE:
        if (direction == Direction.incoming) {
          basic.add(ActionButton(
            title: "Accept",
            icon: Icons.phone,
            fillColor: Colors.green,
            onPressed: _handleAccept,
          ));
        }
        basic.add(hangupBtn);
        break;

      case CallStateEnum.ACCEPTED:
      case CallStateEnum.CONFIRMED:
        advanced.add(ActionButton(
          title: _audioMuted ? 'unmute' : 'mute',
          icon: _audioMuted ? Icons.mic_off : Icons.mic,
          checked: _audioMuted,
          onPressed: _muteAudio,
        ));
        advanced.add(ActionButton(
          title: "keypad",
          icon: Icons.dialpad,
          onPressed: _handleKeyPad,
        ));
        advanced.add(ActionButton(
          title: _speakerOn ? 'speaker off' : 'speaker on',
          icon: _speakerOn ? Icons.volume_off : Icons.volume_up,
          checked: _speakerOn,
          onPressed: _toggleSpeaker,
        ));

        basic.add(ActionButton(
          title: _hold ? 'unhold' : 'hold',
          icon: _hold ? Icons.play_arrow : Icons.pause,
          checked: _hold,
          onPressed: _handleHold,
        ));
        basic.add(hangupBtn);
        basic.add(ActionButton(
          title: _showNumPad ? "back" : "transfer",
          icon: _showNumPad ? Icons.keyboard_arrow_down : Icons.phone_forwarded,
          onPressed: _showNumPad ? _handleKeyPad : _handleTransfer,
        ));
        break;

      case CallStateEnum.FAILED:
      case CallStateEnum.ENDED:
        basic.add(ActionButton(
          title: "hangup",
          onPressed: () {},
          icon: Icons.call_end,
          fillColor: Colors.grey,
        ));
        break;

      case CallStateEnum.PROGRESS:
        basic.add(hangupBtn);
        break;

      default:
        break;
    }

    final widgets = <Widget>[];

    if (_showNumPad) {
      widgets.addAll(_buildNumPad());
    } else if (advanced.isNotEmpty) {
      widgets.add(Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: advanced,
        ),
      ));
    }

    widgets.add(Padding(
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: basic,
      ),
    ));

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: widgets,
    );
  }

  Widget _buildContent() {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).size.height * 0.12,
          left: 0,
          right: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'VOICE CALL' +
                    (_hold && _holdOriginator != null
                        ? ' PAUSED BY ${_holdOriginator!.name}'
                        : ''),
                style: TextStyle(fontSize: 24, color: textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                remoteIdentity ?? '',
                style: TextStyle(fontSize: 18, color: textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<String>(
                valueListenable: _timeLabel,
                builder: (_, value, __) => Text(
                  value,
                  style: TextStyle(fontSize: 14, color: textColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool confirm = await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Akhiri Panggilan?'),
                content: Text(
                    'Keluar dari halaman akan mengakhiri panggilan. Lanjutkan?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () {
                      _handleHangup();
                      Navigator.pop(context, true);
                    },
                    child: Text('Ya'),
                  ),
                ],
              ),
            ) ??
            false;
        return confirm;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('[${direction?.name}] ${_state.name}'),
        ),
        body: _buildContent(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Container(
          width: 320,
          padding: EdgeInsets.only(bottom: 24.0),
          child: _buildActionButtons(),
        ),
      ),
    );
  }

  @override
  void onNewReinvite(ReInvite event) {}

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void onNewNotify(Notify ntf) {}

  @override
  void transportStateChanged(TransportState state) {}

  @override
  void registrationStateChanged(RegistrationState state) {}
}
