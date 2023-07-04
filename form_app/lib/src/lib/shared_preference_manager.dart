import 'package:shared_preferences/shared_preferences.dart';
 
/// SharedPreferences封装
class SPrefsValue<T> {
  /// 缓存map
  static final _cacheMap = <String, Object?>{};
 
  /// 清除所有缓存
  static void cleanAllCache() {
    _cacheMap.clear();
  }
 
  /// 清除缓存
  static void removeCache(String key) {
    _cacheMap.remove(key);
  }
 
  /// key
  final String key;
 
  /// 默认值
  final T defaultValue;
 
  /// 是否缓存
  final bool hasCache;
 
  /// 初始化
  SPrefsValue(
    this.key,
    this.defaultValue, {
    this.hasCache = false,
  });
 
  /// 清除
  Future<bool> remove() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final state = await prefs.remove(key);
    _cacheMap.remove(key);
    return state;
  }
 
  /// 取值
  ///
  /// 如果设置使用缓存值,将优先使用缓存
  Future<T> getValue() async {
    try {
      // 缓存中取值
      if (hasCache && _cacheMap[key] != null && _cacheMap[key] is T) {
        return _cacheMap[key] as T;
      }
      final value = await _readValue() ?? defaultValue;
 
      // 更新缓存值
      if (hasCache && _cacheMap[key] != value) {
        _cacheMap[key] = value;
      }
      return value;
    } catch (e) {
      return defaultValue;
    }
  }
 
  /// 获取缓存中的值
  ///
  /// 为确保缓存有值，调用之前确认调用过set/getValue，
  T getCacheValue() {
    final cacheValue = _cacheMap[key];
    if (cacheValue != null && cacheValue is T) {
      return cacheValue as T;
    }
    return defaultValue;
  }
 
  /// 设置值
  Future<bool> setValue(T newValue) async {
    var state = false;
    try {
      if (hasCache) {
        _cacheMap[key] = newValue;
      }
      state = await _writeValue(value: newValue);
    } catch (e) {
      state = false;
    }
    return state;
  }
 
  /// 读取SharedPreferences存储值
  Future<T?> _readValue() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    T? value;
    if (T is int) {
      value = prefs.getInt(key) as T?;
    } else if (T is double) {
      value = prefs.getDouble(key) as T?;
    } else if (T is String) {
      value = prefs.getString(key) as T?;
    } else if (T is bool) {
      value = prefs.getBool(key) as T?;
    } else if (T is List<String>) {
      value = prefs.getStringList(key) as T?;
    } else {
      final listValue = prefs.get(key);
      if (listValue is List) {
        value = listValue.map((e) => e.toString()).toList() as T?;
      } else {
        value = prefs.get(key) as T?;
      }
    }
 
    return value;
  }
 
  /// 写入SharedPreferences存储值
  Future<bool> _writeValue({required T value}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var state = false;
    if (value is int) {
      state = await prefs.setInt(key, value);
    } else if (value is double) {
      state = await prefs.setDouble(key, value);
    } else if (value is String) {
      state = await prefs.setString(key, value);
    } else if (value is bool) {
      state = await prefs.setBool(key, value);
    } else if (value is List<String>) {
      state = await prefs.setStringList(key, value);
    }
    return state;
  }
}
 
/// 类型扩展
extension SPrefsData<T> on T {
  /// SharedPreferences扩展函数
  SPrefsValue<T> spValue(
    String valueKey, {
    T? defValue,
    bool hasCache = false,
  }) {
    return SPrefsValue(valueKey, defValue ?? this, hasCache: hasCache);
  }
}
