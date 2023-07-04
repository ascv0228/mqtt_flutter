// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
// import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'mqtt_control.dart';


@JsonSerializable()
class InputServerData {
  String? host;
  int? port;
  Socket? socket; 

  InputServerData({
    this.host,
    this.port,
  });

//   factory InputServerData.fromJson(Map<String, dynamic> json) =>
//       _$FormDataFromJson(json);

//   Map<String, dynamic> toJson() => _$FormDataToJson(this);
}

class InputServerDemo extends StatefulWidget {

  const InputServerDemo({
    super.key,
  });

  @override
  State<InputServerDemo> createState() => _InputServerDemoState();
}

class _InputServerDemoState extends State<InputServerDemo> {
  InputServerData inputServerData = InputServerData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect'),
      ),
      body: Form(
        child: Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...[
                  TextFormField(
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      filled: true,
                      hintText: 'Server Host',
                      labelText: 'Host',
                    ),
                    onChanged: (value) {
                      inputServerData.host = value;
                    },
                  ),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      filled: true,
                      hintText: 'Server Port',
                      labelText: 'Port',
                    ),
                    onChanged: (value) {
                      inputServerData.port = int.parse(value);
                    },
                    inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  ),
                  TextButton(
                    child: const Text('Connect'),
                    onPressed: () {
                      if(inputServerData.host == null || inputServerData.port == null){

                      }
                      else{
                        connectServer(context, inputServerData.host!, inputServerData.port!).then((value){
                        SocketInfo si = SocketInfo(host: inputServerData.host!, port: inputServerData.port!);
                        inputServerData.socket!.close();
                        context.go('/mqtt_control', extra : si);
                        } 
                      );
                      }
                    },
                  ),
                  TextButton(
                    child: const Text('Exit'),
                    onPressed: () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        await inputServerData.socket?.close();
                        scaffoldMessenger.showSnackBar(
                            const SnackBar(
                                content: Text('已成功離線到伺服器.'),
                                duration: Duration(seconds: 1),
                            ),
                        );

                        // 發送和接收資料的邏輯
                        // ...

                        // 關閉套接字連接
                    },
                  ),
                ].expand(
                  (widget) => [
                    widget,
                    const SizedBox(
                      height: 24,
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void navigateToSecondRoute(BuildContext context){
    
    //   Navigator.push(
    //   context,
    //   MaterialPageRoute<MqttControlDemo>(builder: (context) => const MqttControlDemo()),
    // );
  }

  void navigateToSecondRoute2(BuildContext context){

      context.go('/mqtt_control');
  }

  Future connectServer(BuildContext context, String host, int? port) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      inputServerData.socket = await Socket.connect(host, port!);
      inputServerData.socket?.timeout(const Duration(seconds: 3),onTimeout: (event){
      throw Exception('connect timeout for /*timeoutReconnect*/');
    });
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('已成功連接到伺服器.'),
          duration: Duration(seconds: 1),
        ),
      );
      // navigateToSecondRoute();
    } catch (error) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('無法連接到伺服器'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}
