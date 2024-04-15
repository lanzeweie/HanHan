import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ProviderHANHANALL with ChangeNotifier {
  bool _isHuaDong = false;
  bool _isDarkModeForce = false;
  
  bool get isHuaDong => _isHuaDong;
  bool get isDarkModeForce => _isDarkModeForce;
  
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
    notifyListeners();
  }


}
