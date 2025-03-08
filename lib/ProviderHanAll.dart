import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProviderHANHANALL with ChangeNotifier {
  bool _isHuaDong = false;
  bool _isDarkModeForce = false;
  bool _isDarkMode = false; // 当前是否处于暗黑模式
  // 统一子元素颜色配置
  Color? _subElementColor;
  
  // 历史记录上限，默认为5条
  int _historyLimit = 5;

  // 添加跟随系统属性
  bool _isFollowSystem = true; // 默认跟随系统

  bool get isHuaDong => _isHuaDong;
  bool get isDarkModeForce => _isDarkModeForce;
  bool get isDarkMode {
    // 如果强制使用暗黑模式，直接返回true
    if (_isDarkModeForce) return true;
    // 否则基于是否跟随系统和当前系统模式
    return _isFollowSystem ? _isDarkMode : false;
  }
  Color get subElementColor => _subElementColor ?? Colors.blue;
  int get historyLimit => _historyLimit;
  bool get isFollowSystem => _isFollowSystem;

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
    if (_isDarkModeForce != value) {
      _isDarkModeForce = value;
      
      // 保存到持久化存储
      _saveDarkModeSettings();
      
      // 如果启用强制暗黑模式，确保关闭跟随系统
      if (value && _isFollowSystem) {
        _isFollowSystem = false;
        // 同样保存跟随系统设置
        _saveFollowSystemSetting();
      }
      
      notifyListeners();
    }
  }

  set historyLimit(int value) {
    _historyLimit = value;
    notifyListeners();
  }

  set isFollowSystem(bool value) {
    if (_isFollowSystem != value) {
      _isFollowSystem = value;
      
      // 保存到持久化存储
      _saveFollowSystemSetting();
      
      // 如果启用跟随系统，确保关闭强制暗黑模式
      if (value && _isDarkModeForce) {
        _isDarkModeForce = false;
        // 同样保存暗黑模式设置
        _saveDarkModeSettings();
      }
      
      // 如果开启跟随系统，立即根据当前系统亮度模式设置主题
      if (value) {
        try {
          // 获取当前系统亮度
          final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
          _isDarkMode = brightness == Brightness.dark;
        } catch (e) {
          print('获取系统亮度失败: $e');
        }
      }
      
      notifyListeners();
    }
  }

  Future<void> _saveDarkModeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('暗黑模式', _isDarkModeForce);
    } catch (e) {
      print('保存暗黑模式设置失败: $e');
    }
  }

  Future<void> _saveFollowSystemSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('跟随系统', _isFollowSystem);
    } catch (e) {
      print('保存跟随系统设置失败: $e');
    }
  }

  Future<void> loadProviderHANHANAL() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _isDarkModeForce = prefs.getBool('暗黑模式') ?? false;
      _isHuaDong = prefs.getBool('滑动控制') ?? false;
      _isFollowSystem = prefs.getBool('跟随系统') ?? true; // 加载跟随系统设置
      _historyLimit = prefs.getInt('historyLimit') ?? 5;
      
      // 确保强制暗黑模式和跟随系统的一致性
      if (_isDarkModeForce && _isFollowSystem) {
        _isFollowSystem = false;
        await _saveFollowSystemSetting();
      }
      
      // 如果跟随系统，获取当前系统亮度
      if (_isFollowSystem) {
        try {
          final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
          _isDarkMode = brightness == Brightness.dark;
        } catch (e) {
          print('获取系统亮度失败: $e');
        }
      }
      
      // 加载统一颜色配置
      if (prefs.containsKey('subElementColor')) {
        _subElementColor = Color(prefs.getInt('subElementColor')!);
      }
    } catch (e) {
      print('加载Provider设置失败: $e');
    }
    
    notifyListeners();
  }

  // 更新当前主题模式 (供系统亮度变化时使用)
  void updateThemeMode(bool isDark) {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      // 确保UI组件知道状态已经改变
      notifyListeners();
      
      // 可选：打印日志以便调试
      print('系统亮度模式已更改: isDarkMode = $_isDarkMode');
    }
  }
}
