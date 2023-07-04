import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:format/format.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lib/my_message.dart';
import 'lib/shared_preference_manager.dart';
import 'shared.dart';


class MqttsMap extends ChangeNotifier {
  final List<String> _mqttItems = [];
  Map<String, MqttsItem?> mqttMap = {};

  List<String> get items => _mqttItems;
  Map<String, MqttsItem?> get map => mqttMap;

  void add(String deviceId) {
    if(_mqttItems.contains(deviceId)){
      return;
    }
    _mqttItems.add(deviceId);
    mqttMap[deviceId] = MqttsItem(deviceId);
    notifyListeners();
  }

  void remove(String deviceId) {
    _mqttItems.remove(deviceId);
    mqttMap[deviceId] = null;
    mqttMap.remove(deviceId);
    notifyListeners();
  }

  void setConnected(String deviceId, bool value){ 
    mqttMap[deviceId]?.setConnected(! mqttMap[deviceId]!.getConnected());
    notifyListeners();
    return ;
  }

}

class MqttsItem extends ChangeNotifier {
  final String deviceId;
  bool connected = false;
  MqttsItem(this.deviceId);

  bool setConnected(bool c){
    connected = c;
    notifyListeners();
    return c;
  }

  bool getConnected(){
    return connected;
  }

  bool checkOnline(Socket socket){
    notifyListeners();
    return connected;
  }

}

class MqttControlDemo extends StatefulWidget {
  // final Socket socket;
  final SocketInfo socketInfo;
  

  MqttControlDemo({
    required this.socketInfo,
    super.key,
  });

  @override
  State<MqttControlDemo> createState() => _MqttControlDemoState();

}


class _MqttControlDemoState extends State<MqttControlDemo> {
  final TextEditingController _textFieldController = TextEditingController();
  Timer? timer;
  SharedData? sharedData;

  @override
  void initState() {
    super.initState();
    initializeSharedData();
  }
  void initializeSharedData() async {
    sharedData = await SharedData.init();
    sharedData!.getSaveData();
  }
  
  Future<void> sendMessage(Socket socket, myMessage msg) async {
    socket.write(msg.encode());
    await socket.flush();
  }

  Future<void> sendCheckMessages(Socket socket, MqttsMap m) async{
    var msg = myMessage(targetDeviceId: "", targetDevice: DeviceType.server,
    sourceDevice: DeviceType.client, sourceDeviceId: SharedData.device_id, action: ActionType.checkOnline);
    msg.setParameters({"device_ids": m.items});
    // msg.setParameters({"device_ids": ["112233"]});
    await sendMessage(socket, msg);
  }

  Future<void> sendBackgroundMessages(SocketInfo si, MqttsItem m, String url) async{
    var msg = myMessage(targetDeviceId: m.deviceId, targetDevice: DeviceType.device,
    sourceDevice: DeviceType.client, sourceDeviceId: SharedData.device_id, action: ActionType.changeBackground);
    msg.setParameters({"url": url});
    Socket socket = await Socket.connect(si.host, si.port);
    await sendMessage(socket, msg);
    socket.close;
  }

  StreamSubscription? subscription; 
  Future<String> listen(Socket socket) {
    Completer<String> completer = Completer<String>();
    if(subscription != null) {
      subscription?.cancel();
    }

    subscription = socket.listen((data) {
      String receivedData = String.fromCharCodes(data).trim();
      log(receivedData);
      completer.complete(receivedData);
    }, onDone: () {
      completer.completeError('Socket done without receiving data');
    }, onError: (dynamic error) {
      completer.completeError('Socket error: $error');
    },cancelOnError: false);
    return completer.future;
  }


  Future<void> handleCheckMessages(SocketInfo si, MqttsMap m) async{
    Socket socket = await Socket.connect(si.host, si.port);
    await sendCheckMessages(socket, m);
    var s = await listen(socket);
    // await socket.close();
    socket.close();
    var resMsg = myMessage.fromString(s);
    resetConnected(resMsg, m);
  }

  void resetConnected(myMessage msg, MqttsMap m){
    log("resetConnected");
    if (msg.action == ActionType.resultOnline){
      var p = msg.parameters;
      DateTime now = DateTime.now();
      int seconds = now.toUtc().millisecondsSinceEpoch ~/ 1000; 
      log('${p!['result']}');
      log('${p!['result'].runtimeType}');
      
      for (var d in p!['result'] as List<dynamic>){
        if (d is Map) {
          Map<String, String> tempObj = {};
          d.forEach((key, value) {
            if (key is String && value is String) {
              tempObj[key] = value;
            }
          });
          bool val = (seconds -15) < int.parse(tempObj['last_time']  as String);
          m.setConnected(tempObj['device_id'] as String, val);
        }
      }
      
      // for(Map<String, String> r in p!['result'] as List<Map<String, String>>){
      //   m.map[r['device_id'] as String]?.setConnected(seconds -15 < int.parse(r['last_time']  as String));
      // }
    }
  }

  void changeConnected(MqttsMap m){
     m.map.forEach((k,v) => 
      m.setConnected(k, true)
     ); 
  }


  @override
  Widget build(BuildContext context) {
    final mqttsList = context.watch<MqttsMap>();
    // log(widget.socket.remoteAddress.address);
    // log("${widget.socket.port}");
    // SocketInfo si = SocketInfo(host: widget.socket.remoteAddress.address, port: widget.socket.port);
    // final Socket mqtt_socket;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mqtt Control'),
        actions: [
          TextButton.icon(
            onPressed: () {
              _showAlertDialog(context, mqttsList);
              // context.go(FavoritesPage.fullPath);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
          TextButton.icon(
            onPressed: () {
              // sendCheckMessages(widget.socket, mqttsList);
              handleCheckMessages(widget.socketInfo, mqttsList);
            },
            icon: const Icon(Icons.update),
            label: const Text('update'),
          ),
        ],
      ),
      body: Consumer<MqttsMap>(
        builder: (context, value, child) => Center(
            child: value.items.isNotEmpty
            ? ListView.builder(
                itemCount: value.items.length,
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemBuilder: (context, index) =>
                    MqttItemTile(value.map[value.items[index]]!, _showDashBoard),
              )
            : const Text('No devices added.'),
          ),
      ),
    );
    
  }

  String? codeDialog;
  String? valueText;
  Future<void> _showAlertDialog(BuildContext context, MqttsMap mqttsMap) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Device'),
          content: TextField(
            onChanged: (value) {
              setState(() {
                valueText = value;
              });
            },
            controller: _textFieldController,
            decoration: const InputDecoration(hintText: "device id"),
          ),
          actions: <Widget>[
            MaterialButton(
              color: Colors.red,
              textColor: Colors.white,
              child: const Text('CANCEL'),
              onPressed: () {
                setState(() {
                  Navigator.pop(context);
                  _textFieldController.clear();
                });
              },
            ),
            MaterialButton(
              color: Colors.green,
              textColor: Colors.white,
              child: const Text('OK'),
              onPressed: () {
                setState(() {
                  if(valueText!.isEmpty){
                    _textFieldController.clear();
                    valueText = "";
                    Navigator.pop(context);
                    return;
                  }
                  if(!mqttsMap.items.contains(valueText)){
                    mqttsMap.add(valueText!);
                  }
                  // log('B');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(mqttsMap.items.contains(valueText)
                          ? 'Added devices.'
                          : 'Removed devices.'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                  // log('C');
                  valueText = "";
                  _textFieldController.clear();
                  Navigator.pop(context);
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDashBoard(BuildContext context, MqttsItem item) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Device Background',
          style: TextStyle(
          fontSize: 15, // 设置标题的字体大小
        ),),
          content: TextField(
            onChanged: (value) {
              setState(() {
                valueText = value;
              });
            },
            controller: _textFieldController,
            decoration: const InputDecoration(hintText: "image url"),
          ),
          actions: <Widget>[
            MaterialButton(
              color: Colors.green,
              textColor: Colors.white,
              child: const Text('OK'),
              onPressed: () {
                setState(() {
                  if(valueText?.isEmpty ?? true){
                    valueText = "";
                    Navigator.pop(context);
                    _textFieldController.clear();
                    return;
                  }
                  // log('B');
                  sendBackgroundMessages(widget.socketInfo, item, valueText!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Send Finish'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  // log('C');
                  valueText = "";
                  _textFieldController.clear();
                  Navigator.pop(context);
                });
              },
            ),
          ],
        );
      },
    );
  }

}


// void socketMessageSender(List<dynamic> args) async {
//     SocketInfo si = args[0] as SocketInfo;
//     MqttsMap mqttsList = args[1] as MqttsMap;
//     Function(Socket, MqttsMap) callback = args[2] as Function(Socket, MqttsMap);
//     // SendPort sendPort = args[1] as SendPort;
//     // var mqttsList = context.watch<MqttsMap>();
//   // 建立 Socket 连接
//   // 循环发送消息
//     Socket socket = await Socket.connect(si.host, si.port);
//     while (true) {
//       // 发送消息
//         callback(socket, mqttsList);
//       await Future.delayed(const Duration(seconds: 3));
//     }
//     socket.close();
// }

class MqttItemTile extends StatelessWidget {
  final MqttsItem item;
  bool? connected = false;
  final Function(BuildContext, MqttsItem) callback;

  MqttItemTile(this.item, this.callback, {super.key});

  Color getColors(){
    log("change Color");
    return item.connected ? Colors.blue : Colors.red;
  }


  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: getColors(),
        ),
        title: Text(
          'Item ${item.deviceId}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                callback(context, item);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                context.read<MqttsMap>().remove(item.deviceId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Removed device.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SocketInfo {
  final String host;
  final int port;

  SocketInfo({required this.host, required this.port});
}
//     Future<void> _showAlertDialog(BuildContext context, Mqtts mqttsList) {
//         return showDialog<void>(
//         context: context,
//         builder: (context) {
//             return AlertDialog(
//             title: const Text('Add Device'),
//             content: TextField(
//                 onChanged: (value) {
//                 setState(() {
//                     valueText = value;
//                 });
//                 },
//                 controller: _textFieldController,
//                 decoration: const InputDecoration(hintText: "device id"),
//             ),
//             actions: <Widget>[
//                 MaterialButton(
//                 color: Colors.red,
//                 textColor: Colors.white,
//                 child: const Text('CANCEL'),
//                 onPressed: () {
//                     setState(() {
//                     Navigator.pop(context);
//                     });
//                 },
//                 ),
//                 MaterialButton(
//                 color: Colors.green,
//                 textColor: Colors.white,
//                 child: const Text('OK'),
//                 onPressed: () {
//                     setState(() {
//                     !mqttsList.items.contains(valueText)
//                         ? mqttsList.add(valueText!)
//                         : mqttsList.remove(valueText!);
//                     ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                         content: Text(mqttsList.items.contains(valueText)
//                             ? 'Added devices.'
//                             : 'Removed devices.'),
//                         duration: const Duration(seconds: 1),
//                         ),
//                     );
//                     valueText = "";
//                     Navigator.pop(context);
//                     });
//                 },
//                 ),
//             ],
//             );
//         }
//         )
//         }
// }

// class MqttItemDashBoard(){
    
// }
