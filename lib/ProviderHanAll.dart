import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ProviderHANHANALL with ChangeNotifier {
  bool _isDarkModeForce = false;
  bool _isHuaDong = false;

  bool get isDarkModeForce => _isDarkModeForce;
  bool get isHuaDong => _isHuaDong;

  set isDarkModeForce(bool value) {
    _isDarkModeForce = value;
    notifyListeners();
  }

  set isHuaDong(bool value) {
    _isHuaDong = value;
    notifyListeners();
  }

  Future<void> loadDarkModeForce() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkModeForce = prefs.getBool('暗黑模式') ?? false;
    notifyListeners();
  }

  Future<void> loadHuaDong() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isHuaDong = prefs.getBool('滑动控制') ?? false;
    notifyListeners();
  }
}
