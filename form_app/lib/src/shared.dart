import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
class SharedData {
  SharedPreferences? prefs;
  static String? _device_id;

  SharedData._();
  // SharedData({required this.prefs});
  static Future<SharedData> init() async {
    var instance = SharedData._(); // 创建实例
    instance.prefs = await SharedPreferences.getInstance(); // 异步初始化
    return instance;
  }

  static String get device_id => _device_id!;
  void getSaveData(){
    if (_device_id == null || _device_id!.isEmpty){
      _device_id = getDevicId();
    }
  }
  String getDevicId() {
    if (!prefs!.containsKey('device_id')){
      prefs!.setString('device_id', const Uuid().v4());
    }
    
    return prefs!.getString('device_id')!;
  }
  


}