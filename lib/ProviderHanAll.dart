import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProviderHANHANALL with ChangeNotifier {
  bool _isHuaDong = false;
  bool _isDarkModeForce = false;
  // 统一子元素颜色配置
  Color? _subElementColor;
  
  // 历史记录上限，默认为5条
  int historyLimit = 5;

  bool get isHuaDong => _isHuaDong;
  bool get isDarkModeForce => _isDarkModeForce;
  bool get isDarkMode => !_isDarkModeForce && 
      (WidgetsBinding.instance.window.platformBrightness == Brightness.dark);
  Color get subElementColor => _subElementColor ?? Colors.blue;

  void updateSubElementColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('subElementColor', color.value);
    
    _subElementColor = color;
    notifyListeners();
  }
  
  set isHuaDong(bool value) {
    _isHuaDong = value;
    notifyListeners();
  }

  set isDarkModeForce(bool value) {
    _isDarkModeForce = value;
    notifyListeners();
  }

  Future<void> loadProviderHANHANAL() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkModeForce = prefs.getBool('暗黑模式') ?? false;
    _isHuaDong = prefs.getBool('滑动控制') ?? false;
    
    // 加载统一颜色配置
    if (prefs.containsKey('subElementColor')) {
      _subElementColor = Color(prefs.getInt('subElementColor')!);
    }
    notifyListeners();
  }


}
