import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Config/device_utils.dart';
import 'ProviderHanAll.dart';
import 'color.dart';

//我是主页面，很多函数都可以互相调用的

void main() {
  // 添加Flutter错误处理器来捕获PageController相关错误
  FlutterError.onError = (FlutterErrorDetails details) {
    // 检查是否为PageController.page相关错误
    if (details.exception.toString().contains('PageController.page cannot be accessed')) {
      print('捕获到PageController错误: ${details.exception}');
      // 不向上传播错误，防止应用崩溃
    } else {
      // 其他错误正常处理
      FlutterError.presentError(details);
    }
  };
  
  // 使用runZonedGuarded捕获异步错误
  runZonedGuarded(() {
    runApp(MyApp());
  }, (Object error, StackTrace stack) {
    print('未处理的异步错误: $error');
    print('堆栈跟踪: $stack');
    // 在这里可以添加日志记录或其他处理
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ZhuPage(),
    );
  }
}

// 命令执行历史记录类
class CommandHistory {
  final DateTime timestamp;
  final bool success;
  final String cmdBack;
  final String executionTime;

  CommandHistory({
    required this.timestamp,
    required this.success,
    required this.cmdBack,
    required this.executionTime,
  });

  // 从JSON转换为对象
  factory CommandHistory.fromJson(Map<String, dynamic> json) {
    return CommandHistory(
      timestamp: DateTime.parse(json['timestamp']),
      success: json['success'],
      cmdBack: json['cmd_back'] ?? 'No output',
      executionTime: json['execution_time'] ?? 'N/A',
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'success': success,
      'cmd_back': cmdBack,
      'execution_time': executionTime,
    };
  }
}

class CardOption {
  final String title;
  final String apiUrl;
  final String dataCommand;
  final String apiUrlCommand;
  double? _value; // 将类型更改为可为空
  List<CommandHistory> history = []; // 添加历史记录列表

  CardOption(this.title, this.apiUrl, {required this.dataCommand, required this.apiUrlCommand, double? value})
      : _value = value; // 在构造函数中进行初始化

  double? get value => _value;

  set value(double? newValue) {
    _value = newValue;
  }

  // 添加新的历史记录，根据配置的最大记录数保留
  void addHistory(CommandHistory newHistory, int maxHistoryCount) {
    if (history.length >= maxHistoryCount) {
      history.removeAt(0); // 移除最旧的记录
    }
    history.add(newHistory);
  }
}

// 新增：设备信息类
class DeviceInfo {
  final String ip;
  String mac;
  String name;
  bool isOnline;
  DateTime lastSeen;

  DeviceInfo({
    required this.ip,
    this.mac = '未知',
    this.name = '未知设备',
    this.isOnline = false,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  // 从JSON转换为对象
  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      ip: json['ip'],
      mac: json['mac'] ?? '未知',
      name: json['name'] ?? '未知设备',
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen'])
          : DateTime.now(),
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'ip': ip,
      'mac': mac,
      'name': name,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }

  // 更新设备信息
  void updateInfo({String? mac, String? name, bool? isOnline}) {
    if (mac != null && mac.isNotEmpty) this.mac = mac;
    if (name != null && name.isNotEmpty) this.name = name;
    if (isOnline != null) this.isOnline = isOnline;
    this.lastSeen = DateTime.now();
  }
}

class ZhuPage extends StatefulWidget {
  @override
  _ZhuPageState createState() => _ZhuPageState();
}

class _ZhuPageState extends State<ZhuPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Timer? _timer;
  Timer? _refreshTimer; // 添加命令列表刷新计时器
  //颜色默认值
  bool isDarkMode = false;
  bool isDarkMode_force = false;
  //持久化数据
  bool isHuaDong = false;
  // 历史记录设置
  int maxHistoryCount = 5; // 默认历史记录上限

  TextEditingController _textEditingController = TextEditingController();
  bool _searching = false;
  Color _frameColor = Colors.transparent;
  List<CardOption> cardOptions = [];
  // 搜索专用
  String? _selectedIp;
  int _lastSearchedIndex = 1; // 用于记录最后一次搜索的IP位置，默认从1开始
  
  // 修改：使用新的设备信息存储结构
  Map<String, DeviceInfo> _deviceMap = {}; // 替换原有的 _ipSet, _deviceNames, _deviceOnlineStatus
  
  //通知栏排队
  SnackBar? _currentSnackBar;
  // 输入栏
  bool _inputBoxColor = true; // 输入框的初始颜色
  bool _originalColor = true; // 输入框回归颜色
  Color _searchingColor = Colors.red;  // 替换为你的搜索颜色
  Duration _animationDuration = Duration(milliseconds: 100); // 动画的时间
  FocusNode _focusNode = FocusNode();
  //命令列表
  Map<int, bool> isSelectedMap = {};
  // 滑动条
  bool isSliderReleased = false;
  
  // 与Provider同步的设置
  bool _settingsChanged = false;
  
  // 动画控制器和动画值
  late AnimationController _colorAnimationController;
  late Animation<double> _colorAnimation;
  bool _animatingToSearch = false; // 标记是否正在向搜索状态动画
  bool _animatingFromSearch = false; // 标记是否正在从搜索状态恢复

  set timer(Timer? value) {
    _timer = value;
  }

  //应用程序启动时执行
  @override
  void initState() {
    super.initState();
    // 添加观察者以监听系统亮度变化
    WidgetsBinding.instance.addObserver(this);
    
    _init();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _saveData();
      }
    });
    getisDarkMode_force();
    _loadCommandHistory(); // 加载命令历史记录
    _loadHistorySettings(); // 加载历史记录设置
    
    // 初始化动画控制器
    _colorAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 550), // 动画持续时间
    );
    
    _colorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _colorAnimationController,
        curve: Curves.easeInOut, // 使用easeInOut曲线实现iOS风格的流畅感
      ),
    );
    
    // 添加动画状态监听器
    _colorAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // 动画完成
        if (_animatingToSearch) {
          _animatingToSearch = false;
          _searchDevices(); // 动画结束后开始搜索
        }
      } else if (status == AnimationStatus.dismissed) {
        // 动画反向完成
        if (_animatingFromSearch) {
          _animatingFromSearch = false;
          setState(() {
            _frameColor = Colors.transparent;
            _inputBoxColor = true;
          });
        }
      }
    });
    
    // 启动定时刷新命令列表的计时器
    _startRefreshTimer();
  }

  // 启动刷新命令列表的计时器
  void _startRefreshTimer() {
    // 如果已存在计时器，先取消
    _refreshTimer?.cancel();
    
    // 创建新计时器，每x秒刷新一次命令列表
    _refreshTimer = Timer.periodic(Duration(seconds: 200), (timer) {
      _refreshCommandList();
    });
  }

  // 刷新命令列表
  Future<void> _refreshCommandList() async {
    // 检查当前IP是否有效
    final currentIp = _textEditingController.text.trim();
    if (currentIp.isEmpty) return;
    
    // 检查设备是否在线
    final isOnline = await _checkDeviceOnline(currentIp);
    if (isOnline) {
      // 静默刷新命令列表（不显示通知）
      try {
        await loadConfig();
        print('命令列表已自动刷新 - IP: $currentIp');
      } catch (e) {
        print('自动刷新命令列表失败: $e');
      }
    }
  }

  // 监听系统亮度变化
  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    if (mounted) {
      // 获取当前系统亮度模式
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      final newIsDarkMode = brightness == Brightness.dark;
      
      // 如果系统亮度模式发生变化，则更新状态
      if (isDarkMode != newIsDarkMode) {
        setState(() {
          isDarkMode = newIsDarkMode;
        });
        
        // 通知Provider
        if (!isDarkMode_force) {  // 只有在非强制暗黑模式下才需要响应系统变化
          final provider = Provider.of<ProviderHANHANALL>(context, listen: false);
          provider.updateThemeMode(newIsDarkMode);
        }
        
        // 重新加载界面的所有元素
        setState(() {});
      }
    }
  }

  // 加载历史记录设置
  Future<void> _loadHistorySettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // 使用与设置页面相同的键名 'historyLimit'
      maxHistoryCount = prefs.getInt('historyLimit') ?? 5;
      
      // 如果设置发生变化，需要裁剪现有历史记录
      if (_settingsChanged) {
        _trimAllHistoryRecords();
        _settingsChanged = false;
      }
    });
  }

  // 处理所有卡片的历史记录，确保不超过最大限制
  void _trimAllHistoryRecords() {
    for (var card in cardOptions) {
      if (card.history.length > maxHistoryCount) {
        setState(() {
          // 保留最新的maxHistoryCount条记录
          card.history = card.history.sublist(
            card.history.length - maxHistoryCount
          );
        });
        // 保存裁剪后的历史记录
        _saveCommandHistory(card);
      }
    }
  }

  // 加载命令历史记录
  Future<void> _loadCommandHistory() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < cardOptions.length; i++) {
      final currentIp = _textEditingController.text;
      if (currentIp.isEmpty) continue;
      
      final historyKey = 'cmd_history_${currentIp}_${cardOptions[i].apiUrl}_${cardOptions[i].dataCommand}';
      final historyJson = prefs.getString(historyKey);
      if (historyJson != null) {
        try {
          final List<dynamic> historyList = json.decode(historyJson);
          cardOptions[i].history = historyList.map((item) => CommandHistory.fromJson(item)).toList();
        } catch (e) {
          print('Error loading command history: $e');
        }
      }
    }
  }

  // 保存命令历史记录
  Future<void> _saveCommandHistory(CardOption cardOption) async {
    final prefs = await SharedPreferences.getInstance();
    final currentIp = _textEditingController.text;
    if (currentIp.isEmpty) return;
    
    final historyKey = 'cmd_history_${currentIp}_${cardOption.apiUrl}_${cardOption.dataCommand}';
    final historyJson = json.encode(cardOption.history.map((h) => h.toJson()).toList());
    await prefs.setString(historyKey, historyJson);
  }

  // 删除设备的历史记录
  Future<void> _deleteDeviceHistory(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    final deviceHistoryKeys = keys.where((key) => key.startsWith('cmd_history_${ip}_')).toList();
    
    for (String key in deviceHistoryKeys) {
      await prefs.remove(key);
    }
    
    // 同时从设备列表中删除
    setState(() {
      _deviceMap.remove(ip);
    });
    
    await _saveDeviceList();
  }

  Future<void> _init() async {
    //加载永久信息
    await _loadSavedData();
    //加载命令列表，需要连接设备
    await loadConfig();
    
    // 启动时快速扫描所有保存的设备状态（静默）
    _quickScanSavedDevices();
  }

  // 快速扫描所有保存的IP
  Future<void> _quickScanSavedDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDevicesJson = prefs.getString('saved_devices') ?? '{}';
    
    try {
      final Map<String, dynamic> devicesData = json.decode(savedDevicesJson);
      _deviceMap = devicesData.map((key, value) => 
        MapEntry(key, DeviceInfo.fromJson(value))
      );
      
      // 并行UDP检查所有保存的设备状态
      await Future.wait(
        _deviceMap.keys.map((ip) => _checkDeviceOnline(ip))
      );
    } catch (e) {
      print('加载设备列表失败: $e');
      _deviceMap = {};
    }
  }

  // 就是个底部通知栏
  void showNotificationBar(BuildContext context, String message) {
    // 关闭当前的通知栏
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // 显示新的通知栏
    final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(color: AppColors.colorConfigTongzhikuangWenzi(isDarkMode_force,isDarkMode)),
      ),
      duration: Duration(seconds: 2),
      backgroundColor: AppColors.colorConfigTongzhikuang(isDarkMode_force,isDarkMode),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // 获取设备完整信息 - 通过HTTP接口
  Future<void> _getDeviceFullInfo(String ip) async {
    try {
      final response = await http.get(
        Uri.parse('http://$ip:5202/name'),
        headers: {
          'Authorization': 'i am Han Han',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final name = data['title'] as String? ?? '未知设备';
        final mac = data['mac'] as String? ?? '未知';
        
        setState(() {
          // 检查是否已存在相同MAC的设备
          String? existingIp = _findDeviceByMac(mac);
          
          if (existingIp != null && existingIp != ip && mac != '未知') {
            // 如果找到相同MAC但不同IP的设备，移除旧的IP记录
            _deviceMap.remove(existingIp);
            print('发现MAC重复设备，移除旧IP: $existingIp，更新为新IP: $ip');
          }
          
          if (_deviceMap.containsKey(ip)) {
            _deviceMap[ip]!.updateInfo(mac: mac, name: name, isOnline: true);
          } else {
            _deviceMap[ip] = DeviceInfo(
              ip: ip,
              mac: mac,
              name: name,
              isOnline: true,
            );
          }
        });
        
        // 保存更新后的设备信息
        await _saveDeviceList();
      }
    } catch (e) {
      print('获取设备完整信息错误: $e');
      // 如果获取失败，至少标记设备为在线（如果之前UDP检测成功）
      if (_deviceMap.containsKey(ip)) {
        setState(() {
          _deviceMap[ip]!.updateInfo(isOnline: true);
        });
      }
    }
  }

  // 新增：根据MAC地址查找设备IP
  String? _findDeviceByMac(String mac) {
    if (mac == '未知' || mac.isEmpty) return null;
    
    for (var entry in _deviceMap.entries) {
      if (entry.value.mac == mac) {
        return entry.key;
      }
    }
    return null;
  }

  // 检查设备在线状态 - 更新为UDP版本
  Future<bool> _checkDeviceOnline(String ip) async {
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final data = 'ping'.codeUnits;
      
      socket.send(data, InternetAddress(ip), 5201);
      
      final completer = Completer<bool>();
      Timer? timeout;
      
      timeout = Timer(Duration(milliseconds: 800), () {
        socket.close();
        if (!completer.isCompleted) completer.complete(false);
      });
      
      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            timeout?.cancel();
            socket.close();
            if (!completer.isCompleted) completer.complete(true);
          }
        }
      });
      
      final isOnline = await completer.future;
      
      if (mounted) {
        setState(() {
          if (_deviceMap.containsKey(ip)) {
            _deviceMap[ip]!.updateInfo(isOnline: isOnline);
          } else if (isOnline) {
            _deviceMap[ip] = DeviceInfo(ip: ip, isOnline: true);
          }
        });
      }
      return isOnline;
    } catch (e) {
      if (mounted && _deviceMap.containsKey(ip)) {
        setState(() {
          _deviceMap[ip]!.updateInfo(isOnline: false);
        });
      }
      return false;
    }
  }

  // 持久化保存数据
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('input_data') ?? '';
    
    // 加载设备列表
    final savedDevicesJson = prefs.getString('saved_devices') ?? '{}';
    try {
      final Map<String, dynamic> devicesData = json.decode(savedDevicesJson);
      _deviceMap = devicesData.map((key, value) => 
        MapEntry(key, DeviceInfo.fromJson(value))
      );
    } catch (e) {
      print('加载设备列表失败: $e');
      _deviceMap = {};
    }
    
    setState(() {
      _textEditingController.text = savedData;
    });
  }

  // 保存设备列表
  Future<void> _saveDeviceList() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceData = _deviceMap.map((key, value) => 
      MapEntry(key, value.toJson())
    );
    await prefs.setString('saved_devices', json.encode(deviceData));
  }

  // 输入框信息自动保存
  Future<void> _saveData() async {
    final ip = _textEditingController.text.trim();
    if (ip.isEmpty) {
      showNotificationBar(context, "设备地址不能为空");
      return;
    }
    
    // 自动保存输入内容
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('input_data', _textEditingController.text);
    
    // 使用UDP验证设备连接
    bool isValid = await _udpDiscovery(ip);
    
    if (isValid) {
      setState(() {
        if (!_deviceMap.containsKey(ip)) {
          _deviceMap[ip] = DeviceInfo(ip: ip, isOnline: true);
        } else {
          _deviceMap[ip]!.updateInfo(isOnline: true);
        }
      });
      
      // 获取设备完整信息（这里会自动处理MAC重复问题）
      await _getDeviceFullInfo(ip);
      
      // 保存设备列表
      await _saveDeviceList();
      
      showNotificationBar(context, "验证成功，设备信息已保存");
    } else {
      // 设备验证失败时，更新设备状态为下线
      setState(() {
        if (_deviceMap.containsKey(ip)) {
          _deviceMap[ip]!.updateInfo(isOnline: false);
        } else {
          // 如果设备不存在，创建一个下线状态的设备记录
          _deviceMap[ip] = DeviceInfo(ip: ip, isOnline: false);
        }
      });
      
      // 保存更新后的设备列表（包括下线状态）
      await _saveDeviceList();
      
      showNotificationBar(context, "设备连接验证失败");
    }
    
    if (!mounted) return;
    loadConfig();
  }

    
  //搜索函数 真jb长
  void _startSearching() async {
    if (_searching) {
      // 停止搜索 - 从左到右恢复颜色
      setState(() {
        _searching = false;
        _animatingFromSearch = true;
      });
      
      // 反向播放动画（从红色回到原色）
      _colorAnimationController.reverse().then((_) {
        if (_deviceMap.isNotEmpty) {
          showNotificationBar(context, '搜索停止，发现可用设备${_deviceMap.length}个');
        } else {
          showNotificationBar(context, '停止搜索');
        }
        setState(() {
          _inputBoxColor = true;
          _frameColor = Colors.transparent;
        });
      });
    } else {
      // 开始搜索 - 从右到左变色
      setState(() {
        _searching = true;
        _animatingToSearch = true;
        _frameColor = Colors.white;
      });
      
      // 正向播放动画（从原色到红色）
      _colorAnimationController.forward();
    }
  }

  //获得本机的内网网段
  Future<String> _getLocalIPv4Address() async {
    String fallbackAddress = ''; // 用于备用地址
    for (NetworkInterface interface in await NetworkInterface.list()) {
      for (InternetAddress address in interface.addresses) {
        if (address.type == InternetAddressType.IPv4) {
          if (address.address.startsWith('192')) {
            return address.address; // 返回以192开头的地址
          } else if (fallbackAddress.isEmpty) {
            fallbackAddress = address.address; // 更新备用地址
          }
        }
      }
    }
    return fallbackAddress; // 返回备用地址，如果没有以192开头的地址
  }

  // 2025年优化版UDP搜索函数 - 高并发版本
  void _searchDevices() async {
    int maxIP = 255;
    int foundCount = 0;
    Set<String> _countedInThisScan = Set();
    
    String currentDeviceIP = await _getLocalIPv4Address();
    List<String> parts = currentDeviceIP.split('.');
    String networkSegment = '${parts[0]}.${parts[1]}.${parts[2]}';
    showNotificationBar(context, '扫描中 | 网段 $networkSegment.0/24');

    // 阶段1: 快速验证所有历史设备（UDP并发）
    List<String> savedIPs = _deviceMap.keys.toList();
    if (savedIPs.isNotEmpty) {
      await Future.wait(
        savedIPs.map((ip) => _udpDiscovery(ip).then((isOnline) {
          if (isOnline) {
            _deviceMap[ip]!.updateInfo(isOnline: true);
            
            if (!_countedInThisScan.contains(ip)) {
              foundCount++;
              _countedInThisScan.add(ip);
            }
            
            // 获取完整设备信息（这里会自动处理MAC重复问题）
            _getDeviceFullInfo(ip);
          } else {
            _deviceMap[ip]!.updateInfo(isOnline: false);
          }
        }))
      );
    }
    
    // 阶段2: 全网段UDP扫描（高并发批次处理）
    List<Future<void>> allScans = [];
    
    for (int i = 1; i <= maxIP && _searching; i++) {
      final ip = '$networkSegment.$i';
      
      // 跳过已知IP
      if (_deviceMap.containsKey(ip)) continue;
      
      allScans.add(
        _udpDiscovery(ip).then((isOnline) {
          if (isOnline && _searching) {
            setState(() {
              _deviceMap[ip] = DeviceInfo(ip: ip, isOnline: true);
            });
            
            if (!_countedInThisScan.contains(ip)) {
              foundCount++;
              _countedInThisScan.add(ip);
            }
            
            // 获取完整设备信息（这里会自动处理MAC重复问题）
            _getDeviceFullInfo(ip);
          }
        })
      );
    }
    
    // 分批执行扫描，避免过度并发
    const batchSize = 50;
    for (int i = 0; i < allScans.length; i += batchSize) {
      if (!_searching) break;
      
      final batch = allScans.sublist(
        i, 
        (i + batchSize > allScans.length) ? allScans.length : i + batchSize
      );
      
      await Future.wait(batch);
      await Future.delayed(Duration(milliseconds: 50));
    }

    // 状态更新
    setState(() {
      _searching = false;
      _animatingFromSearch = true;
    });
    
    _colorAnimationController.reverse();
    
    if (foundCount == 0) {
      showNotificationBar(context, '搜索完毕，未发现可用设备');
    } else {
      showNotificationBar(context, '搜索完毕，发现可用设备$foundCount个');
    }
    
    _inputBoxColor = _originalColor;
    _lastSearchedIndex = 1;
    
    // 保存更新后的设备列表
    await _saveDeviceList();
    
    // 搜索完成后更新所有设备状态
    await Future.wait(_deviceMap.keys.map((ip) => _checkDeviceOnline(ip)));
  }

  // 新增：UDP发现设备的核心函数
  Future<bool> _udpDiscovery(String ip) async {
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final data = 'discovery'.codeUnits;
      
      socket.send(data, InternetAddress(ip), 5201);
      
      final completer = Completer<bool>();
      Timer? timeout;
      
      // 设置较短的超时时间以提高扫描速度
      timeout = Timer(Duration(milliseconds: 200), () {
        socket.close();
        if (!completer.isCompleted) completer.complete(false);
      });
      
      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            timeout?.cancel();
            socket.close();
            if (!completer.isCompleted) completer.complete(true);
          }
        }
      });
      
      return await completer.future;
    } catch (e) {
      return false;
    }
  }

  //下拉框
  void _updateInput(String? selectedIp) {
    setState(() {
      _selectedIp = selectedIp;
      _textEditingController.text = selectedIp ?? '';
    });
    _saveData();
  }

  //命令列表
  //从设备中获得命令列表。基于服务端
  Future<void> loadConfig() async {
      print(_textEditingController.text);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? modelID = prefs.getString('modelID');
      String? deviceID = prefs.getString('deviceID');
      bool hasRetried = false;

      while ((modelID == null || deviceID == null) && !hasRetried) {
          print("设备信息缺失，触发设备信息更新");
          await updateDeviceData();

          modelID = prefs.getString('modelID');
          deviceID = prefs.getString('deviceID');
          
          if (modelID != null && deviceID != null) {
              break;
          }

          hasRetried = true;
      }

      if (modelID == null || deviceID == null) {
          throw Exception("设备信息更新失败，设备型号或设备ID 仍然为 null");
      }

      var url = Uri.parse('http://${_textEditingController.text}:5202/orderlist');
      
      Map<String, dynamic> requestData = {
          'deviceID': deviceID,
          'modelID': modelID,
      };

      final Map<String, String> headers = {
          'Authorization': 'i am Han Han',
          'Content-Type': 'application/json',
      };

      try {
          var responseFuture = http.post(url, headers: headers, body: json.encode(requestData));
          
          var response = await responseFuture.timeout(Duration(seconds: 2), onTimeout: () {
              showNotificationBar(context, '尝试连接 ${_textEditingController.text} 服务端如果启动授权设备验证请完成设备授权');
              throw TimeoutException('请求超时');
          });

          if (response.statusCode == 200) {
              String configString = response.body;
              showNotificationBar(context, '已连接设备 ${_textEditingController.text}');
              
              // 尝试解析为 List<dynamic> 或 Map<String, dynamic>
              dynamic responseData = json.decode(configString);
              
              if (responseData is List) {
                  List<dynamic> configData = responseData;
                  setState(() {
                      cardOptions = configData.map((item) {
                          // 处理 apiUrl 的 hanhanip 替换
                          String processedApiUrl = (item['apiUrl'] as String).replaceAll(
                              '*hanhanip*', 
                              _textEditingController.text
                          );

                          // 处理 apiUrlCommand 的 hanhanip 替换（如果存在）
                          String processedApiUrlCommand = '';
                          if (item.containsKey('apiUrlCommand')) {
                              processedApiUrlCommand = (item['apiUrlCommand'] as String).replaceAll(
                                  '*hanhanip*',
                                  _textEditingController.text
                              );
                          }

                          if (item.containsKey('datacommand')) {
                              dynamic value = item['value'];
                              return CardOption(
                                  item['title'],
                                  processedApiUrl,  // 使用处理后的apiUrl
                                  dataCommand: item['datacommand'],
                                  apiUrlCommand: item.containsKey('apiUrlCommand')
                                      ? processedApiUrlCommand  // 使用处理后的apiUrlCommand
                                      : '',
                                  value: value != null
                                      ? double.tryParse(value.toString())
                                      : null,
                              );
                          }
                          if (item.containsKey('apiUrlCommand')) {
                              return CardOption(
                                  item['title'],
                                  processedApiUrl,  // 使用处理后的apiUrl
                                  dataCommand: '',
                                  apiUrlCommand: processedApiUrlCommand,  // 使用处理后的apiUrlCommand
                                  value: null,
                              );
                          }
                          return CardOption(
                              item['title'],
                              processedApiUrl,  // 使用处理后的apiUrl
                              dataCommand: '',
                              apiUrlCommand: '',
                              value: null,
                          );
                      }).toList();
                  });
                  
                  // 加载当前设备的历史记录
                  _loadCommandHistory();
              } else if (responseData is Map) {
                  // Cast to Map<String, dynamic>
                  Map<String, dynamic> responseJson = Map<String, dynamic>.from(responseData);
                  
                  if (responseJson['title'] == "命令返回状态") {
                      if (responseJson['success'] == false) {
                          if (responseJson['cmd_back'] == "设备在黑名单中，不允许执行命令") {
                              showNotificationBar(context, '设备在黑名单中 ${_textEditingController.text}');
                          } else if (responseJson['cmd_back'] == "系统正忙，请稍后再试") {
                              showNotificationBar(context, '请稍后访问 ${_textEditingController.text}');
                          } else if (responseJson['cmd_back'] == "设备未授权，不允许执行命令") {
                              showNotificationBar(context, '你被拒绝访问设备 ${_textEditingController.text}');
                          }
                      }
                  }
              } else {
                  throw Exception('返回的数据格式不正确');
              }
          } else {
              throw Exception('未能从读取配置数据');
          }
      } catch (e) {
          print('Error: $e');

          // 获取当前输入的IP地址
          String currentIp = _textEditingController.text.trim();
          DeviceInfo? deviceInfo = _deviceMap[currentIp];

          List<CardOption> errorCardOptions = [];

          if (currentIp.isEmpty) {
            // 没有输入IP
            errorCardOptions.add(
              CardOption('请先连接设备再进行操作', 'http://192.168.1.6:5202/hello', dataCommand: 'echo nb', apiUrlCommand: '', value: null),
            );
          } else if (deviceInfo != null && deviceInfo.mac != '未知' && deviceInfo.name != '未知设备') {
            // 有IP且有MAC和设备名 - 使用本地魔术包发送
            errorCardOptions.add(
              CardOption('未能连接到设备，可尝试请求远程开机（${deviceInfo.name}）', 'local://wol/${deviceInfo.mac}', dataCommand: 'wakeonlan ${deviceInfo.mac}', apiUrlCommand: '', value: null),
            );
          } else {
            // 有IP但没有MAC或设备名
            errorCardOptions.add(
              CardOption('连接一次设备可以尝试远程开机', 'http://192.168.1.6:5202/hello', dataCommand: 'echo "需要先连接设备获取MAC地址"', apiUrlCommand: '', value: null),
            );
          }

          setState(() {
            cardOptions = errorCardOptions;
          });
      }
  }

  // 本地魔术包发送函数
  static Future<bool> sendWakeOnLan(String macAddress, String targetIp) async {
    try {
      // 解析MAC地址
      String cleanMac = macAddress.replaceAll(RegExp(r'[:-]'), '');
      if (cleanMac.length != 12) {
        throw Exception('无效的MAC地址格式');
      }

      // 创建魔术包 - 修复固定长度列表问题
      List<int> magicPacket = [];
      
      // 添加6个0xFF
      for (int i = 0; i < 6; i++) {
        magicPacket.add(0xFF);
      }
      
      // 将MAC地址转换为字节
      List<int> macBytes = [];
      for (int i = 0; i < 12; i += 2) {
        String hex = cleanMac.substring(i, i + 2);
        macBytes.add(int.parse(hex, radix: 16));
      }
      
      // 添加16次MAC地址
      for (int i = 0; i < 16; i++) {
        magicPacket.addAll(macBytes);
      }

      // 发送UDP包
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      
      // 发送到广播地址
      List<String> ipParts = targetIp.split('.');
      String broadcastIp = '${ipParts[0]}.${ipParts[1]}.${ipParts[2]}.255';
      
      final result = socket.send(
        Uint8List.fromList(magicPacket),
        InternetAddress(broadcastIp),
        9, // WOL端口
      );
      
      socket.close();
      
      return result > 0;
    } catch (e) {
      print('发送魔术包失败: $e');
      return false;
    }
  }

  // 命令执行函数
  static Future<Map<String, dynamic>> fetchData(String apiUrl, String dataCommand, String value) async {
    print("apiUrl: $apiUrl, dataCommand: $dataCommand, value: $value");
    // 记录开始时间
    final DateTime startTime = DateTime.now();

    // 检查是否为本地魔术包命令
    if (dataCommand.startsWith('wakeonlan ') || apiUrl.startsWith('local://wol/')) {
      String macAddress;
      String targetIp;
      
      if (apiUrl.startsWith('local://wol/')) {
        // 从本地URL中提取MAC地址
        macAddress = apiUrl.substring('local://wol/'.length);
        targetIp = '192.168.1.255'; // 默认广播地址
      } else {
        // 从命令中提取MAC地址
        macAddress = dataCommand.substring('wakeonlan '.length);
        // 从apiUrl中提取IP地址作为网段参考
        RegExp ipRegex = RegExp(r'http://([^:]+):');
        Match? match = ipRegex.firstMatch(apiUrl);
        targetIp = match?.group(1) ?? '192.168.1.255';
      }
      
      // 使用本地魔术包发送
      try {
        bool success = await sendWakeOnLan(macAddress, targetIp);
        final executionTime = DateTime.now().difference(startTime).inMilliseconds;
        final formattedExecutionTime = "${(executionTime / 1000).toStringAsFixed(3)}秒";
        
        return {
          "success": success,
          "title": "远程开机",
          "cmd_back": success 
              ? "魔术包已本地发送 (MAC: $macAddress)\n广播到网段: ${targetIp.substring(0, targetIp.lastIndexOf('.'))}.255\n\n如果目标设备支持网络唤醒且网络连接正常，设备应该会在几秒钟内启动。"
              : "魔术包发送失败，请检查网络连接和MAC地址是否正确。",
          "execution_time": formattedExecutionTime
        };
      } catch (e) {
        final executionTime = DateTime.now().difference(startTime).inMilliseconds;
        final formattedExecutionTime = "${(executionTime / 1000).toStringAsFixed(3)}秒";
        
        return {
          "success": false,
          "title": "远程开机",
          "cmd_back": "魔术包发送失败: ${e.toString()}",
          "execution_time": formattedExecutionTime
        };
      }
    }

    // 其他命令的正常处理流程
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? modelID = prefs.getString('modelID');
    String? deviceID = prefs.getString('deviceID');
    bool hasRetried = false;

    // 如果设备信息为空，尝试更新并重试一次
    while ((modelID == null || deviceID == null) && !hasRetried) {
      print("设备信息缺失，触发设备信息更新");
      await updateDeviceData();

      // 重新从 SharedPreferences 获取更新后的设备信息
      modelID = prefs.getString('modelID');
      deviceID = prefs.getString('deviceID');
      
      if (modelID != null && deviceID != null) {
        break;
      }

      // 记录已重试过
      hasRetried = true;
    }

    // 如果设备信息仍然为 null，抛出异常
    if (modelID == null || deviceID == null) {
      throw Exception("设备信息更新失败，设备型号或设备ID 仍然为 null");
    }

    final Map<String, String> headers = {
      'Authorization': 'i am Han Han',
      'Content-Type': 'application/json',
    };

    // 构建请求数据
    Map<String, dynamic> requestData = {
      'deviceID': deviceID,
      'modelID': modelID,
    };

    String responseBody;
    
    try {
      if (dataCommand.isEmpty) {
        // GET请求（通常是自定义API）
        final response = await http.get(Uri.parse(apiUrl), headers: headers).timeout(Duration(seconds: 10));
        print("设备进行了 get 请求");
        if (response.statusCode == 200) {
          responseBody = response.body;
        } else {
          print("状态码: ${response.statusCode},\n响应数据: \n${response.body}");
          throw Exception("状态码: ${response.statusCode},\n响应数据: \n${response.body}");
        }
      } else if (dataCommand.isNotEmpty && value == "null") {
        requestData.addAll({
          'name': 'han han',
          'command': dataCommand,
        });
        print("设备进行了 post 请求");
        final response = await http.post(Uri.parse(apiUrl), headers: headers, body: json.encode(requestData)).timeout(Duration(seconds: 10));

        if (response.statusCode == 200) {
          responseBody = response.body;
        } else {
          print("状态码: ${response.statusCode},\n响应数据: \n${response.body}");
          throw Exception("状态码: ${response.statusCode},\n响应数据: \n${response.body}");
        }
      } else if (dataCommand.isNotEmpty && value != "null") {
        double valueDouble = double.parse(value);
        int valueInt = valueDouble.floor();
        print(valueInt);
        requestData.addAll({
          'name': 'han han',
          'command': dataCommand,
          'value': valueInt,
        });
        print("设备进行了 post 请求 | 带 value");
        final response = await http.post(Uri.parse(apiUrl), headers: headers, body: json.encode(requestData)).timeout(Duration(seconds: 10));

        if (response.statusCode == 200) {
          responseBody = response.body;
        } else {
          print("状态码: ${response.statusCode},\n响应数据: \n${response.body}");
          throw Exception("状态码: ${response.statusCode},\n响应数据: \n${response.body}");
        }
      } else {
        // 添加一个默认的返回语句
        throw Exception("无效的命令参数组合");
      }
    } catch (e) {
      // 计算命令执行时间（即使失败）
      final executionTime = DateTime.now().difference(startTime).inMilliseconds;
      final formattedExecutionTime = "${(executionTime / 1000).toStringAsFixed(3)}秒";
      
      // 返回错误信息和执行时间
      return {
        "success": false,
        "cmd_back": e.toString(),
        "execution_time": formattedExecutionTime
      };
    }
    
    // 计算命令执行时间（成功情况）
    final executionTime = DateTime.now().difference(startTime).inMilliseconds;
    final formattedExecutionTime = "${(executionTime / 1000).toStringAsFixed(3)}秒";
    
    // 尝试解析响应为JSON
    Map<String, dynamic> result;
    try {
      result = json.decode(responseBody);
      // 添加或覆盖执行时间
      result['execution_time'] = formattedExecutionTime;
    } catch (e) {
      // 如果解析失败，构造一个新的结果对象
      result = {
        "success": true,
        "cmd_back": responseBody,
        "execution_time": formattedExecutionTime
      };
    }
    
    return result;
  }

  // 显示历史记录对话框
  void _showHistoryDialog(CardOption cardOption) {
    showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('${cardOption.title} - 执行历史'),
        content: Container(
          width: double.maxFinite,
          child: cardOption.history.isEmpty
              ? SizedBox( // 使用 SizedBox 限制最小高度
                  height: 40, // 最小高度设置
                  child: Center(child: Text('暂无历史记录')),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: cardOption.history.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final history = cardOption.history[cardOption.history.length - 1 - index];
                    // 解码历史记录内容
                    String decodedCmdBack = decodeUrlContent(history.cmdBack);
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: history.success 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('执行时间: ${history.timestamp.toString().substring(0, 19)}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Icon(
                                history.success ? Icons.check_circle : Icons.error,
                                color: history.success ? Colors.green : Colors.red,
                                size: 16,
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text('耗时: ${history.executionTime}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                          SizedBox(height: 4),
                          Text('输出:', style: TextStyle(fontWeight: FontWeight.w500)),
                          Container(
                            margin: EdgeInsets.only(top: 4),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              decodedCmdBack, // 使用解码后的内容
                              style: TextStyle(fontFamily: 'Consolas, monospace', fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  //命令列表的点击动画
  Future<void> myAsyncMethod(index) async {
    await Future.delayed(Duration(milliseconds: 255)); //总消耗时间 毫秒
    
    setState(() {
      isSelectedMap[index] = false;
    });
  }

  //控制台提示窗
  Future<void> _showDialog(String apiUrl, String dataCommand, String apiUrlCommand, String value) async {
    bool isCancelled = false;
    bool isDialogOpen = true;
    int cardIndex = cardOptions.indexWhere((card) => card.apiUrl == apiUrl && card.dataCommand == dataCommand);
    bool isExecuting = false; // 跟踪执行状态
    
    // 获取对应的卡片对象
    CardOption? currentCard = cardIndex != -1 ? cardOptions[cardIndex] : null;
    
    // 在异步操作前保存当前上下文
    final BuildContext currentContext = context;
    
    try {
      // 标记卡片为正在执行状态
      if (cardIndex != -1) {
        setState(() => isSelectedMap[cardIndex] = true);
      }
      
      // 显示确认对话框
      showDialog(
        context: currentContext,
        barrierDismissible: true, // 修复：移除了错误的分号
        builder: (BuildContext dialogContext) {
          return WillPopScope(
            onWillPop: () async {
              // 当对话框被关闭时（包括点击返回键），标记对话框已关闭
              isDialogOpen = false;
              return true; // 允许对话框关闭
            },
            child: StatefulBuilder( // 使用StatefulBuilder以便在对话框内更新状态
              builder: (context, setState) {
                return AlertDialog(
                  titlePadding: EdgeInsets.only(left: 24, top: 16, right: 16),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('控制台'),
                      // 历史记录图标按钮，无论有没有历史记录都显示
                      IconButton(
                        icon: Icon(Icons.history),
                        onPressed: () {
                          if (currentCard != null) { // 有效卡片才响应点击
                            Navigator.of(dialogContext).pop();
                            _showHistoryDialog(currentCard);
                          }
                        },
                        color: Theme.of(context).colorScheme.primary,
                        iconSize: 24,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        splashRadius: 24,
                      ),
                    ],
                  ),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isExecuting)
                        Text('是否执行此命令?')
                      else
                        Text('正在执行命令，请稍候...'),
                      if (dataCommand.isNotEmpty)
                        Text(
                          '命令内容: ${dataCommand.substring(0, dataCommand.length < 150 ? dataCommand.length : 150)}${dataCommand.length > 150 ? "..." : ""}',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (apiUrlCommand.isNotEmpty)
                        Text(
                          'API URL命令: ${apiUrl}',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (value != "null")
                        Text(
                          '数值: $value',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () { 
                        // 无论执行状态如何，取消按钮始终可点击
                        isCancelled = true; // 标记用户已取消
                        isDialogOpen = false; // 标记对话框已关闭
                        
                        // 重置卡片状态
                        if (cardIndex != -1 && this.mounted) {
                          this.setState(() {
                            isSelectedMap[cardIndex] = false;
                          });
                        }
                        Navigator.of(dialogContext).pop();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('取消'),
                    ),
                    TextButton(
                      onPressed: isExecuting ? null : () async {
                        // 设置执行状态
                        setState(() {
                          isExecuting = true;
                        });
                        
                        // 执行API请求（在后台）
                        fetchData(apiUrl, dataCommand, value).then((responseData) {
                          // 如果用户已取消，则不显示结果
                          if (isCancelled || !mounted) return;
                          
                          // 关闭当前对话框（如果还开着）
                          if (isDialogOpen) {
                            Navigator.of(dialogContext).pop();
                            isDialogOpen = false;
                          }
                          
                          // 获取执行时间和命令输出
                          String executionTime = responseData['execution_time'] ?? '计时失败';
                          // 修改: 当没有cmd_back时，使用整个JSON请求内容作为输出，并确保解码
                          String cmdBack;
                          if (responseData.containsKey('cmd_back')) {
                            cmdBack = responseData['cmd_back'];
                          } else {
                            // 返回整个响应内容
                            cmdBack = json.encode(responseData);
                          }
                          
                          // 对可能的URL编码内容进行解码
                          cmdBack = decodeUrlContent(cmdBack);
                          
                          bool success = responseData['success'] ?? true;
                          
                          // 保存命令执行历史
                          if (cardIndex != -1) {
                            final newHistory = CommandHistory(
                              timestamp: DateTime.now(),
                              success: success,
                              cmdBack: cmdBack,
                              executionTime: executionTime,
                            );
                                
                            // 更新历史记录并保存 - 使用新的addHistory方法
                            if (this.mounted) {
                              this.setState(() {
                                addHistory(cardOptions[cardIndex], newHistory);
                              });
                            }
                          }
                          
                          // 显示结果对话框
                          if (mounted) {
                            showDialog(
                              context: currentContext,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  titlePadding: EdgeInsets.only(left: 24, top: 16, right: 16),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('控制台'),
                                      // 历史记录图标按钮
                                      IconButton(
                                        icon: Icon(Icons.history),
                                        onPressed: () {
                                          if (cardIndex != -1) {
                                            Navigator.pop(context);
                                            _showHistoryDialog(cardOptions[cardIndex]);
                                          }
                                        },
                                        color: Theme.of(context).colorScheme.primary,
                                        iconSize: 24,
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(),
                                        splashRadius: 24,
                                      ),
                                    ],
                                  ),
                                  content: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (responseData.containsKey('title'))
                                          Text('Title: ${responseData['title']}'),
                                        SizedBox(height: 8),
                                        if (responseData.containsKey('execution_time'))
                                          Text('Execution Time: ${responseData['execution_time']}'),
                                        SizedBox(height: 8),
                                        if (responseData.containsKey('success'))
                                          Text('Success: ${responseData['success']}'),
                                        if (responseData.containsKey('cmd_back') && responseData['cmd_back'] != null)
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(height: 8),
                                              Text('输出结果:'),
                                              SizedBox(height: 8),
                                              Text('${responseData['cmd_back']}'),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                      child: Text('关闭'),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        }).catchError((e) {
                          // 处理请求错误
                          if (isCancelled || !mounted) return; // 如果用户已取消或组件已卸载，不显示错误
                          
                          // 关闭当前对话框（如果还开着）
                          if (isDialogOpen) {
                            Navigator.of(dialogContext).pop();
                            isDialogOpen = false;
                          }
                          
                          // 使用保存的上下文显示错误对话框
                          if (mounted) {
                            showDialog(
                              context: currentContext,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  titlePadding: EdgeInsets.only(left: 24, top: 16, right: 16),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('错误'),
                                      // 历史记录图标按钮
                                      if (cardIndex != -1)
                                        IconButton(
                                          icon: Icon(Icons.history),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _showHistoryDialog(cardOptions[cardIndex]);
                                          },
                                          color: Theme.of(context).colorScheme.primary,
                                          iconSize: 24,
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(),
                                          splashRadius: 24,
                                        ),
                                    ],
                                  ),
                                  content: Text(e.toString()),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text('关闭'),
                                    ),
                                  ],
                                );
                              },
                            );
                            
                            // 即使报错也保存到历史记录，使用当前时间计算执行时间
                            if (cardIndex != -1) {
                              final duration = DateTime.now().difference(DateTime.now().subtract(Duration(seconds: 1))).inMilliseconds;
                              final executionTime = "${(duration / 1000).toStringAsFixed(3)}秒";
                              
                              final newHistory = CommandHistory(
                                timestamp: DateTime.now(),
                                success: false,
                                cmdBack: "执行错误: ${e.toString()}",
                                executionTime: executionTime,
                              );
                              
                              if (this.mounted) {
                                this.setState(() {
                                  addHistory(cardOptions[cardIndex], newHistory);
                                });
                              }
                            }
                          }
                        }).whenComplete(() {
                          // 无论成功失败，都重置卡片状态
                          if (cardIndex != -1 && this.mounted) {
                            this.setState(() {
                              isSelectedMap[cardIndex] = false;
                            });
                          }
                        });
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.indigo[800]
                            : Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      child: isExecuting
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).brightness == Brightness.dark
                                      ? Colors.blue[200]!
                                      : Colors.blue[700]!),
                              ),
                            )
                          : Text('执行'),
                    ),
                  ],
                );
              }
            ),
          );
        },
      ).then((_) {
        // 对话框关闭后（包括点击外部），标记对话框已关闭
        isDialogOpen = false;
      });
    } catch (e) {
      // 发生意外错误时重置卡片状态
      if (cardIndex != -1 && mounted) {
        setState(() {
          isSelectedMap[cardIndex] = false;
        });
      }
      if (mounted) {
        showNotificationBar(currentContext, "发生错误: ${e.toString()}");
      }
    }
  }

  Widget _buildLoadingDialog() {
    return AlertDialog(
      title: Text('Loading...'),
      content: CircularProgressIndicator(),
    );
  }

  Future<void> getisDarkMode_force() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode_force = prefs.getBool('暗黑模式') ?? false;
      isHuaDong = prefs.getBool('滑动控制') ?? false;
      //print("我在主页，我的暗黑模式是：$isDarkMode_force");
      //print("我在主页，我的滑动条命令执行方式是：$isHuaDong");
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 检查Provider中的历史记录上限设置是否有变化
    final provider = Provider.of<ProviderHANHANALL>(context, listen: false);
    if (provider.historyLimit != maxHistoryCount) {
      maxHistoryCount = provider.historyLimit;
      _settingsChanged = true;
      _loadHistorySettings(); // 重新加载设置并裁剪历史记录
    }
  }

  // 添加新的历史记录，根据配置的最大记录数保留
  void addHistory(CardOption cardOption, CommandHistory newHistory) {
    setState(() {
      if (cardOption.history.length >= maxHistoryCount) {
        cardOption.history.removeAt(0); // 移除最旧的记录
      }
      cardOption.history.add(newHistory);
    });
    _saveCommandHistory(cardOption);
  }

  // 处理URL编码的内容
  String decodeUrlContent(String content) {
    try {
      if (content.contains('%')) {
        return Uri.decodeComponent(content);
      }
      return content;
    } catch (e) {
      print('URL解码错误: $e');
      return content; // 解码失败时返回原始内容
    }
  }

  // 获取排序后的设备列表（在线设备在前）
  List<DeviceInfo> _getSortedDevices() {
    final devices = _deviceMap.values.toList();
    devices.sort((a, b) {
      // 首先按在线状态排序
      if (a.isOnline && !b.isOnline) return -1;
      if (!a.isOnline && b.isOnline) return 1;
      
      // 然后按最后见到时间排序
      return b.lastSeen.compareTo(a.lastSeen);
    });
    return devices;
  }

  @override
  Widget build(BuildContext context) {
    //黑夜模式
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    isDarkMode = brightness == Brightness.dark;
    ProviderHANHANALL ProviderWDWD = Provider.of<ProviderHANHANALL>(context);
    
    // 定义搜索按钮的原始颜色为命令元素颜色
    Color originalSearchButtonColor = AppColors.commandApiElement(context, hueShift: 10, saturationBoost: 1);
    
    return Scaffold(
      appBar: null,
      body: GestureDetector(
        onTap: () {
          // 合并原有的GestureDetector逻辑和之前Scaffold上的onTap逻辑
          FocusScope.of(context).unfocus();
          _focusNode.unfocus();
          
          // 添加之前Scaffold的onTap中的逻辑（虽然效果重复，但为了保持一致）
          if (_focusNode.hasFocus) {
            _focusNode.unfocus();
            FocusScope.of(context).unfocus();
          }
        },
        child:
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 输入框和搜索按钮部分 - 添加动画构建器
                    AnimatedBuilder(
                      animation: _colorAnimation,
                      builder: (context, child) {
                        // 获取输入框的基本背景颜色
                        Color inputBoxBgColor = ProviderWDWD.isDarkModeForce
                            ? AppColors.colorConfigShurukuKuang(ProviderWDWD.isDarkModeForce, isDarkMode)
                            : AppColors.colorConfigShurukuKuang(false, isDarkMode);
                            
                        // 定义搜索状态颜色 - 使用更明亮一点的红色改善暗模式下的视觉效果
                        Color searchStateColor = Color(0xFFFF3B30); // iOS风格的红色
                        
                        // 声明搜索按钮颜色和输入框颜色
                        Color searchButtonColor;
                        Color inputColor;
                        
                        if (_animatingToSearch) {
                          // 从右向左的动画过程 (正常→搜索中)
                          double progress = _colorAnimation.value;
                          
                          // 按钮颜色先变化 (提前启动，给人更顺滑的感觉)
                          searchButtonColor = Color.lerp(
                            originalSearchButtonColor,
                            searchStateColor,
                            progress
                          )!;
                          
                          // 输入框颜色效果：从右边界开始向左扩散红色
                          inputColor = Color.lerp(
                            inputBoxBgColor,
                            searchStateColor,
                            progress * 0.7  // 输入框变色不那么明显
                          )!;
                        } else if (_animatingFromSearch) {
                          // 从左向右的动画过程 (搜索中→正常)
                          double progress = 1.0 - _colorAnimation.value;
                          
                          // 输入框颜色逐渐恢复
                          inputColor = Color.lerp(
                            searchStateColor,
                            inputBoxBgColor,
                            progress
                          )!;
                          
                          // 按钮颜色恢复
                          searchButtonColor = Color.lerp(
                            searchStateColor,
                            originalSearchButtonColor,
                            progress
                          )!;
                        } else if (_searching) {
                          // 搜索状态 - 使用设定的搜索状态颜色
                          searchButtonColor = searchStateColor;
                          inputColor = Color.lerp(inputBoxBgColor, searchStateColor, 0.8)!;  // 输入框不要变得太红
                        } else {
                          // 正常状态 - 使用各自的原始颜色
                          searchButtonColor = originalSearchButtonColor;
                          inputColor = inputBoxBgColor;
                        }
                        
                        return Container(
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // 输入框容器部分
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      bottomLeft: Radius.circular(8),
                                    ),
                                    color: inputColor, // 使用计算好的颜色
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: TextField(
                                      controller: _textEditingController,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: ProviderWDWD.isDarkModeForce
                                            ? AppColors.colorConfigTextShuruku(ProviderWDWD.isDarkModeForce, isDarkMode)
                                            : AppColors.colorConfigTextShuruku(false, isDarkMode),
                                      ),
                                      focusNode: _focusNode,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: "请输入设备IP或搜索设备",
                                        hintStyle: TextStyle(color: Colors.black),
                                      ),
                                      onEditingComplete: _saveData,
                                    ),
                                  ),
                                ),
                              ),
                              // 搜索按钮部分
                              GestureDetector(
                                onTap: _startSearching,
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    ),
                                    color: searchButtonColor,
                                  ),
                                  child: Icon(
                                    Icons.search,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),    // iOS风格折叠列表
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,     
                        highlightColor: Colors.transparent, // 禁用点击高亮
                        splashColor: Colors.transparent,     // 禁用水波纹
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: ProviderWDWD.isDarkModeForce || isDarkMode
                              ? AppColors.colorConfigCard(ProviderWDWD.isDarkModeForce, isDarkMode)
                              : Colors.white,
                          border: Border.all(
                            color: ProviderWDWD.isDarkModeForce || isDarkMode
                                ? Colors.grey.withOpacity(0.3)
                                : Colors.transparent,
                            width: 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: (ProviderWDWD.isDarkModeForce || isDarkMode)
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.symmetric(horizontal: 16),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "设备列表",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: ProviderWDWD.isDarkModeForce || isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.circle, color: Colors.green, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${_deviceMap.values.where((device) => device.isOnline).length}/${_deviceMap.length}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ProviderWDWD.isDarkModeForce || isDarkMode
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          children: [
                            Container(
                              constraints: BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(12)
                                ),
                              ),
                              child: _deviceMap.isEmpty
                                  ? Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                        "暂无设备",
                                        style: TextStyle(
                                          color: ProviderWDWD.isDarkModeForce || isDarkMode
                                              ? Colors.grey.shade400
                                              : Colors.grey,
                                          fontSize: 15
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: EdgeInsets.zero,
                                      itemCount: _deviceMap.length,
                                      separatorBuilder: (context, index) => Divider(
                                        height: 0,
                                        thickness: 0,
                                        color: Colors.transparent,
                                      ),
                                      itemBuilder: (context, index) {
                                        final sortedDevices = _getSortedDevices();
                                        final device = sortedDevices[index];
                                        
                                        return Dismissible(
                                          key: Key(device.ip),
                                          direction: DismissDirection.endToStart,
                                          background: Container(
                                            color: Colors.red,
                                            alignment: Alignment.centerRight,
                                            padding: EdgeInsets.only(right: 20),
                                            child: Icon(Icons.delete, color: Colors.white),
                                          ),
                                          onDismissed: (direction) async {
                                            await _deleteDeviceHistory(device.ip);
                                          },
                                          child: ListTile(
                                            tileColor: ProviderWDWD.isDarkModeForce || isDarkMode
                                                ? Colors.transparent
                                                : null,
                                            leading: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: device.isOnline
                                                    ? Colors.green
                                                    : ProviderWDWD.isDarkModeForce || isDarkMode
                                                        ? Colors.grey.shade600
                                                        : Colors.grey,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            title: Text(
                                              '${device.ip} 【${device.name}】',
                                              style: TextStyle(
                                                color: ProviderWDWD.isDarkModeForce || isDarkMode
                                                    ? Colors.white
                                                    : null,
                                              ),
                                            ),
                                            subtitle: device.mac != '未知' ? Text(
                                              'MAC: ${device.mac}',
                                              style: TextStyle(
                                                color: ProviderWDWD.isDarkModeForce || isDarkMode
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ) : null,
                                            onTap: () => _updateInput(device.ip),
                                            trailing: _selectedIp == device.ip
                                                ? Icon(Icons.check, color: Colors.green)
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // 预处理卡片类型
                          final List<dynamic> layoutItems = [];
                          int index = 0;
                          while (index < cardOptions.length) {
                            final current = cardOptions[index];
                            if (current.value != null) {
                              // 带滚动条的卡片单独成项
                              layoutItems.add(current);
                              index++;
                            } else {
                              // 普通卡片成对组合
                              final List<CardOption> pair = [];
                              while (index < cardOptions.length && 
                                    cardOptions[index].value == null && 
                                    pair.length < 2) {
                                pair.add(cardOptions[index]);
                                index++;
                              }
                              layoutItems.add(pair);
                            }
                          }

                          return ListView.builder(
                            padding: EdgeInsets.all(8),
                            itemCount: layoutItems.length,
                            itemBuilder: (context, listIndex) {
                              final item = layoutItems[listIndex];
                              
                              // 统一卡片构建方法
                              Widget _buildCard(CardOption card, {bool hasSlider = false}) {
                                return Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: hasSlider ? 0 : 4,
                                    vertical: hasSlider ? 8 : 4
                                  ),
                                  child: Card(
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(hasSlider ? 16 : 12),
                                      side: BorderSide(
                                        color: AppColors.colorConfigCardBorder(context),
                                        width: 1,
                                      ),
                                    ),
                                    color: _inputBoxColor
                                        ? ProviderWDWD.isDarkModeForce || isDarkMode
                                            ? AppColors.colorConfigCard(ProviderWDWD.isDarkModeForce, isDarkMode)
                                            : AppColors.colorConfigCard(false, isDarkMode)
                                        : Colors.transparent,
                                    shadowColor: ProviderWDWD.isDarkModeForce || isDarkMode
                                        ? Colors.black.withOpacity(0.6)
                                        : Colors.black.withOpacity(0.2),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(hasSlider ? 14 : 12),
                                      onTap: () => _onCardTap(card),
                                      child: Column(
                                        children: [
                                          ListTile(
                                            title: Text(
                                              card.title,
                                              style: TextStyle(
                                                fontSize: hasSlider ? 16 : 16,
                                                fontWeight: FontWeight.w500,
                                                color: ProviderWDWD.isDarkModeForce || isDarkMode
                                                    ? Colors.white
                                                    : null,
                                              ),
                                            ),
                                            subtitle: card.dataCommand.isNotEmpty
                                                ? Text(
                                                    '自定义命令',
                                                    style: TextStyle(
                                                      color: AppColors.commandApiElement(context,
                                                          hueShift: hasSlider ? 3 : 0.1,
                                                          saturationBoost: hasSlider ? 0.3 : 0.5),
                                                      fontSize: 12
                                                    ),
                                                  )
                                                : card.apiUrlCommand.isNotEmpty
                                                    ? Text(
                                                        '自定义API',
                                                        style: TextStyle(
                                                          color: AppColors.commandApiElement(context,
                                                              hueShift: hasSlider ? -0.1 : -0.1,
                                                              saturationBoost: hasSlider ? 0.5 : 0.5),
                                                          fontSize: 12
                                                        ),
                                                      )
                                                    : null,
                                          ),
                                          if (hasSlider)
                                            Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 16),
                                              child: Slider(
                                                value: card.value!,
                                                min: 0,
                                                max: 100,
                                                onChanged: (v) => setState(() => card.value = v),
                                                onChangeEnd: (v) {
                                                  setState(() => card.value = v);
                                                  isSliderReleased = true;
                                                  
                                                  // 显示当前值的通知
                                                  showNotificationBar(context, '${card.title}： ${card.value?.floor()}');
                                                  
                                                  // 检查是否开启了滑动控制功能
                                                  if (ProviderWDWD.isHuaDong) {
                                                    // 如果开启了滑动控制，直接执行命令而不弹出确认窗口
                                                    fetchData(
                                                      card.apiUrl,  
                                                      card.dataCommand, 
                                                      card.value.toString()
                                                    ).then((responseData) {
                                                      // 处理命令执行结果并添加到历史记录
                                                      // 获取执行时间和命令输出
                                                      String executionTime = responseData['execution_time'];
                                                      // 修改: 当没有cmd_back时，使用整个JSON请求内容作为输出，并确保解码
                                                      String cmdBack;
                                                      if (responseData.containsKey('cmd_back')) {
                                                        cmdBack = responseData['cmd_back'];
                                                      } else {
                                                        // 返回整个响应内容
                                                        cmdBack = json.encode(responseData);
                                                      }
                                                      
                                                      // 对可能的URL编码内容进行解码
                                                      cmdBack = decodeUrlContent(cmdBack);
                                                      
                                                      bool success = responseData['success'] ?? true;
                                                      
                                                      // 创建历史记录
                                                      final newHistory = CommandHistory(
                                                        timestamp: DateTime.now(),
                                                        success: success,
                                                        cmdBack: cmdBack,
                                                        executionTime: executionTime,
                                                      );
                                                      
                                                      // 更新历史记录 - 使用新的addHistory方法
                                                      setState(() {
                                                        int cardIndex = cardOptions.indexOf(card);
                                                        if (cardIndex != -1) {
                                                          addHistory(cardOptions[cardIndex], newHistory);
                                                        }
                                                      });
                                                    }).catchError((e) {
                                                      // 处理执行错误
                                                      showNotificationBar(context, "执行错误: ${e.toString()}");
                                                      
                                                      // 计算执行时间
                                                      final duration = DateTime.now().difference(DateTime.now().subtract(Duration(seconds: 1))).inMilliseconds;
                                                      final executionTime = "${(duration / 1000).toStringAsFixed(3)}秒";
                                                      
                                                      // 即使报错也保存到历史记录
                                                      final newHistory = CommandHistory(
                                                        timestamp: DateTime.now(),
                                                        success: false,
                                                        cmdBack: "执行错误: ${e.toString()}",
                                                        executionTime: executionTime,
                                                      );
                                                      
                                                      setState(() {
                                                        int cardIndex = cardOptions.indexOf(card);
                                                        if (cardIndex != -1) {
                                                          addHistory(cardOptions[cardIndex], newHistory);
                                                        }
                                                      });
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                              // 处理带滚动条的卡片
                              if (item is CardOption) {
                                return _buildCard(item, hasSlider: true);
                              }
                              // 处理普通卡片对
                              if (item is List<CardOption>) {
                                return Row(
                                  children: item.map((card) => Expanded(
                                    child: _buildCard(card)
                                  )).toList(),
                                );
                              }
                              return SizedBox.shrink();
                            },
                          );
                        },
                      ),
                    )
                  ],
                ),
            ),
        ),
    );
  }

  // 修改卡片点击事件的方法
  void _onCardTap(CardOption card) {
    // 确保取消输入框焦点，避免命令执行完后键盘再次弹出
    _focusNode.unfocus();
    FocusScope.of(context).unfocus();
    
    setState(() => isSelectedMap[cardOptions.indexOf(card)] = true);
    myAsyncMethod(cardOptions.indexOf(card));
    
    // 使用新的_showDialog方法
    _showDialog(
      card.apiUrl,
      card.dataCommand,
      card.apiUrlCommand,
      card.value?.toString() ?? "null"
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveData();
    _colorAnimationController.dispose(); // 释放动画控制器
    _refreshTimer?.cancel(); // 取消命令列表刷新计时器
    super.dispose();
  }

  // 用户切换到其他应用或页面
  @override  
  void didChangeAppLifecycleState(AppLifecycleState state) {    
    super.didChangeAppLifecycleState(state);        
    
    if (state == AppLifecycleState.resumed) {
      // 应用恢复到前台时，立即刷新一次命令列表
      _refreshCommandList();
      // 重新启动定时刷新
      _startRefreshTimer();
    } else if (state == AppLifecycleState.paused) {
      // 应用进入后台时，暂停定时刷新
      _refreshTimer?.cancel();
    }
  }
}
