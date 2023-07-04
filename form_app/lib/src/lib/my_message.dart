
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

class myMessage{
  String? targetDeviceId;
  String? targetDevice;
  String? sourceDeviceId;
  String? sourceDevice;
  String? action;
  Map<String, dynamic>? parameters;
  myMessage({
    required this.targetDeviceId,
    required this.targetDevice,
    required this.sourceDeviceId,
    required this.sourceDevice,
    required this.action,
  });

  myMessage.fromString(String jsonString){
    final datas = jsonDecode(jsonString)[0];
    targetDeviceId = datas['targetDeviceId'] as String;
    targetDevice = datas['targetDevice'] as String;
    sourceDeviceId = datas['sourceDeviceId'] as String;
    sourceDevice = datas['sourceDevice'] as String;
    action = datas['action'] as String;
    // log(datas['parameters']);
    parameters = datas['parameters'] as Map<String, dynamic>;
  }

  myMessage setParameters(Map<String, dynamic> pm){
    parameters = pm;
    return this;
  }

  Map<String, dynamic> toJson() => {
        'targetDeviceId': targetDeviceId,
        'targetDevice': targetDevice,
        'sourceDeviceId': sourceDeviceId,
        'sourceDevice': sourceDevice,
        'action': action,
        'parameters': parameters,
      };

  String encode() {
    return '[${jsonEncode(toJson()) }]';
  }
}


Future<String> readResponse(Socket socket) async {
  // var received_data = b''
  //   while True:
  //       data = socket.recv(1024)
  //       if not data:
  //           break
  //       received_data += data
  //       if len(data) < 1024:
  //           break
  //   response = received_data.decode(encoding='utf_8', errors='strict')
  //   return response
  final response = await utf8.decoder.bind(socket).join();
  return response;

}



class ActionType{
    static String online = 'online';
    static String checkOnline = 'checkOnline';
    static String resultOnline = 'resultOnline';
    static String changeBackground = 'changeBackground';
    static String hello = 'hello';
    static String exit = 'exit';
    static String bind = 'bind';

}

class DeviceType{
    static String client = 'client';
    static String device = 'device';
    static String server = 'server';
    static String none = '';

}