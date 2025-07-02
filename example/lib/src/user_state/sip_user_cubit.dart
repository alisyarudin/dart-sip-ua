import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:dart_sip_ua_example/src/user_state/sip_user.dart';
import 'package:sip_ua/sip_ua.dart';

class SipUserCubit extends Cubit<SipUser?> {
  final SIPUAHelper sipHelper;
  SipUserCubit({required this.sipHelper}) : super(null);

  void register(SipUser user) {
    UaSettings settings = UaSettings();
    settings.port = user.port;
    settings.webSocketSettings.extraHeaders = user.wsExtraHeaders ?? {};
    settings.webSocketSettings.allowBadCertificate = true;
    //settings.webSocketSettings.userAgent = 'Dart/2.8 (dart:io) for OpenSIPS.';
    settings.tcpSocketSettings.allowBadCertificate = true;
    settings.transportType = user.selectedTransport;
    settings.uri = user.sipUri;
    settings.webSocketUrl = user.wsUrl;
    settings.host = user.sipUri?.split('@')[1];
    settings.authorizationUser = user.authUser;
    settings.password = user.password;
    settings.displayName = user.displayName;
    settings.userAgent = 'Dart SIP Client v1.0.0';
    settings.dtmfMode = DtmfMode.RFC2833;
    settings.contact_uri = 'sip:${user.sipUri}';
    // Add ICE server settings
    settings.iceServers = [
      {
        'urls': 'stun:stun.l.google.com:19302', // Example STUN server
      },
      {
        'urls':
            'stun:relay1.expressturn.com:3478', // Replace with your TURN server
        'username': 'ef4NYNJDHYLH72ATOC', // Optional
        'credential': 'GCi0oIS2oB8BBUzm', // Optional
      },
      // Add more ICE servers as needed
    ];
    print(jsonEncode({
      'port': settings.port,
      'extraHeaders': settings.webSocketSettings.extraHeaders,
      'allowBadCertificateWs': settings.webSocketSettings.allowBadCertificate,
      'allowBadCertificateTcp': settings.tcpSocketSettings.allowBadCertificate,
      'uri': settings.uri,
      'webSocketUrl': settings.webSocketUrl,
      'host': settings.host,
      'authorizationUser': settings.authorizationUser,
      'password': settings.password,
      'displayName': settings.displayName,
      'userAgent': settings.userAgent,
      'dtmfMode': settings.dtmfMode.toString(),
      'contactUri': settings.contact_uri,
    }));

    emit(user);
    sipHelper.start(settings);
  }
}
