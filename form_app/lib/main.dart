// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// import 'dart:io' show Platform;
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_size/window_size.dart';

// import 'lib/m_socket.dart';
// import 'src/autofill.dart';
import 'src/form_widgets.dart';
// import 'src/http/mock_client.dart';
import 'src/input_server.dart';
import 'src/mqtt_control.dart';
import 'src/shared.dart';
// import 'src/validation.dart';

void main() {
  setupWindow();
  runApp(const FormApp());
}

const double windowWidth = 480;
const double windowHeight = 854;

void setupWindow() {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    WidgetsFlutterBinding.ensureInitialized();
    setWindowTitle('Form Samples');
    setWindowMinSize(const Size(windowWidth, windowHeight));
    setWindowMaxSize(const Size(windowWidth, windowHeight));
    getCurrentScreen().then((screen) {
      setWindowFrame(Rect.fromCenter(
        center: screen!.frame.center,
        width: windowWidth,
        height: windowHeight,
      ));
    });
  }
}

final demos = [
  // GoRoute(
  //   name: 'Sign in with HTTP',
  //   path: 'signin_http',
  //   builder: (context, state) => SignInHttpDemo(
  //     // This sample uses a mock HTTP client.
  //     httpClient: mockClient,
  //   ),
  // ),
  GoRoute(
    name: 'InputServerData',
    path: 'inputServerData',
    builder: (context, state) => const InputServerDemo(),
  ),
  GoRoute(
    name: 'Mqtt_control',
    path: 'mqtt_control',
    builder: (context, state)
    {
      SocketInfo si = state.extra as SocketInfo;
      return MqttControlDemo(
      socketInfo: si
    );
    },
  ),
];

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      // builder: (context, state) => const HomePage(),
      builder: (context, state) => const InputServerDemo(),
      routes: demos,
    ),
  ],
);

// List<RouteBase>? generateRouter(List<Demo> demos) {
//   return [
//         for (final demo in demos)
//           GoRoute(
//             path: demo.route,
//             builder: (context, state) => demo.builder(context),
//             routes: (demo.routes != null) ? [] : generateRouter(demo.routes);
//           ),
//       ];
// }




class FormApp extends StatelessWidget {
  const FormApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MqttsMap>(
      create: (context) => MqttsMap(),
      child: MaterialApp.router(
        title: 'Testing Sample',
        theme: ThemeData(
          colorSchemeSeed: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
    // return MaterialApp.router(
    //   title: 'Form Samples',
    //   theme: ThemeData(
    //     colorSchemeSeed: Colors.teal,
    //     useMaterial3: true,
    //   ),
    //   routerConfig: router,
    // );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Samples'),
      ),
      body: ListView(
        children: [...demos.map((d) => DemoTile(demo: d))],
      ),
    );
  }
}

class DemoTile extends StatelessWidget {
  final GoRoute? demo;

  const DemoTile({this.demo, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(demo!.name!),
      onTap: () {
        context.go('/${demo!.path}');
      },
    );
  }
}

// class Demo {
//   final String name;
//   final String route;
//   final WidgetBuilder builder;
//   final List<RouteBase>? routes;

//   const Demo({required this.name, required this.route, required this.builder, this.routes,
//   }) : assert(routes == null || routes is List<RouteBase>);
//   // Demo({required this.name, required this.route, required this.builder, this.routes = const <RouteBase>[]});
// }
