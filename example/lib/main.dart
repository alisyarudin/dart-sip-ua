import 'dart:async';
import 'dart:io';

import 'package:dart_sip_ua_example/src/loket_cti/branch_selection_page.dart';
import 'package:dart_sip_ua_example/src/loket_cti/call_page.dart';
import 'package:dart_sip_ua_example/src/notification_helper.dart';
import 'package:dart_sip_ua_example/src/notification_window_helper.dart';
import 'package:dart_sip_ua_example/src/theme_provider.dart';
import 'package:dart_sip_ua_example/src/user_state/sip_user_cubit.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:logger/logger.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:window_manager/window_manager.dart';

import 'src/about.dart';
import 'src/callscreen.dart';
import 'src/dialpad.dart';
import 'src/register.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _requestPermissions() async {
  await [
    Permission.systemAlertWindow,
    Permission.notification,
  ].request();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // WAJIB

  final logFile = File('log.txt');
  final sink = logFile.openWrite(mode: FileMode.append);
  runZonedGuarded(() {
    runApp(MyApp());
  }, (error, stack) {
    sink.writeln('ERROR: $error\n$stack');
  });

  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) {
      sink.writeln(message);
    }
  };

  if (!kIsWeb) {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.ensureInitialized();

      await NotificationWinHelper.init();

      WindowOptions windowOptions = const WindowOptions(
        size: Size(400, 720),
        center: true,
        maximumSize: Size(400, 700),
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        windowButtonVisibility: false,
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }
  }
  Logger.level = Level.warning;
  if (WebRTC.platformIsDesktop) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }

  await _requestPermissions(); // 👈 Tambahkan ini

  if (await FlutterSingleInstance().isFirstInstance()) {
    runApp(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
        child: MyApp(),
      ),
    );
  } else {
    print("App is already running");

    final err = await FlutterSingleInstance().focus();

    if (err != null) {
      print("Error focusing running instance: $err");
    }

    exit(0);
  }
}

typedef PageContentBuilder = Widget Function(
    [SIPUAHelper? helper, Object? arguments]);

// ignore: must_be_immutable
class MyApp extends StatelessWidget {
  final SIPUAHelper _helper = SIPUAHelper();
  Map<String, PageContentBuilder> routes = {
    '/': ([SIPUAHelper? helper, Object? arguments]) =>
        BranchSelectionPage(helper),
    '/call-page': ([SIPUAHelper? helper, Object? arguments]) {
      final args = arguments as Map?;
      final branch = args?['branch'];
      return CallPage(helper, selectedBranch: branch);
    },
    '/callscreen': ([SIPUAHelper? helper, Object? arguments]) =>
        CallScreenWidget(helper, arguments as Call?),
    '/call': ([SIPUAHelper? helper, Object? arguments]) =>
        DialPadWidget(helper),
    '/register': ([SIPUAHelper? helper, Object? arguments]) =>
        RegisterWidget(helper),
    '/about': ([SIPUAHelper? helper, Object? arguments]) => AboutWidget(),
  };

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final String? name = settings.name;
    final PageContentBuilder? pageContentBuilder = routes[name!];
    if (pageContentBuilder != null) {
      if (settings.arguments != null) {
        final Route route = MaterialPageRoute<Widget>(
            builder: (context) =>
                pageContentBuilder(_helper, settings.arguments));
        return route;
      } else {
        final Route route = MaterialPageRoute<Widget>(
            builder: (context) => pageContentBuilder(_helper));
        return route;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SIPUAHelper>.value(value: _helper),
        Provider<SipUserCubit>(
            create: (context) => SipUserCubit(sipHelper: _helper)),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'CALL VOIP',
        theme: Theme.of(context),
        initialRoute: '/',
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }
}
