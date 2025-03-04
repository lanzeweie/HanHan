import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Config/device_utils.dart';
import 'ProviderHanAll.dart';
import 'color.dart';

//我是主页面，很多函数都可以互相调用的

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ZhuPage(),
    );
  }
}

class CardOption {
  final String title;
  final String apiUrl;
  final String dataCommand;
  final String apiUrlCommand;
  double? _value; // 将类型更改为可为空

  CardOption(this.title, this.apiUrl, {required this.dataCommand, required this.apiUrlCommand, double? value})
      : _value = value; // 在构造函数中进行初始化

  double? get value => _value;

  set value(double? newValue) {
    _value = newValue;
  }
}

class ZhuPage extends StatefulWidget {
  @override
  _ZhuPageState createState() => _ZhuPageState();
}

class _ZhuPageState extends State<ZhuPage> {
  Timer? _timer;
  //颜色默认值
  bool isDarkMode = false;
  bool isDarkMode_force = false;
  //持久化数据
  bool isHuaDong = false;

  TextEditingController _textEditingController = TextEditingController();
  bool _searching = false;
  Color _frameColor = Colors.transparent;
  List<CardOption> cardOptions = [];
  // 搜索专用
  String? _selectedIp;
  int _lastSearchedIndex = 1; // 用于记录最后一次搜索的IP位置，默认从1开始
  Set<String> _ipSet = {}; // 使用 Set 而不是 List
  final Map<String, String?> _deviceNames = {};
  final Map<String, bool> _deviceOnlineStatus = {};
  //通知栏排队
  SnackBar? _currentSnackBar;
  // 输入栏
  bool _inputBoxColor = true; // 输入框的初始颜色
  bool _originalColor = true; // 输入框回归颜色
  Color _searchingColor = Colors.red;  // 替换为你的搜索颜色
  Duration _animationDuration = Duration(milliseconds: 300); // 动画的时间
  FocusNode _focusNode = FocusNode();
  //命令列表
  Map<int, bool> isSelectedMap = {};
  // 滑动条
  bool isSliderReleased = false;

  set timer(Timer? value) {
    _timer = value;
  }

  //应用程序启动时执行
  @override
  void initState() {
    super.initState();
    _init();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _saveData();
      }
    });
    getisDarkMode_force();
  }

  Future<void> _init() async {
    //加载永久信息
    await _loadSavedData();
    //加载命令列表，需要连接设备
    await loadConfig();
  }

  //就是个底部通知栏
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

  // 获取设备名称
  Future<String?> _getDeviceName(String ip) async {
      if (_deviceNames.containsKey(ip)) return _deviceNames[ip];
      try {
        final response = await http.get(
          Uri.parse('http://$ip:5202/name'),
          headers: {
            'Authorization': 'i am Han Han',
            'Content-Type': 'application/json',
          },
        ).timeout(Duration(seconds: 2));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final name = data['title'] as String?;
          setState(() {
            _deviceNames[ip] = name;
          });
          return name;
        }
      } catch (e) {
        print('获取设备名称错误: $e');
      }
      return null;
    }


  // 检查设备在线状态
  Future<bool> _checkDeviceOnline(String ip) async {
    bool isOnline;
    try {
      final socket = await Socket.connect(ip, 5201)
          .timeout(const Duration(seconds: 1));
      socket.destroy();
      isOnline = true;
    } catch (e) {
      isOnline = false;
    }
    
    if (mounted) {
      setState(() => _deviceOnlineStatus[ip] = isOnline);
    }
    return isOnline;
  }

  // 持久化保存数据
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    // 只加载持久化保存的已验证 IP 列表
    final savedIps = prefs.getStringList('daixuankuang_shared') ?? [];
    final savedData = prefs.getString('input_data') ?? '';
    
    setState(() {
      _ipSet.addAll(savedIps);  // 加载持久化保存的 IP
      _textEditingController.text = savedData;  // 恢复输入框内容，但不添加到设备列表
    });
  }

  // 输入框信息自动保存（修复：只有通过验证的设备才会被保存到设备列表）
  void _saveData() async {
    final ip = _textEditingController.text.trim();
    // 空值检查
    if (ip.isEmpty) {
      showNotificationBar(context, "设备地址不能为空");
      return;
    }
    // 自动保存输入内容（仅保存到输入框历史，不保存到设备列表）
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('input_data', _textEditingController.text); // 保存最后一次输入
    
    // 验证设备连接
    bool isValid = false;
    await _checkDeviceOnline(ip);
    isValid = _deviceOnlineStatus[ip] ?? false;
    
    if (isValid) {
      setState(() {
        if (!_ipSet.contains(ip)) {
          _ipSet.add(ip);
        }
      });
      // 持久化存储有效IP和设备名（只有验证成功的才保存到设备列表）
      final deviceName = await _getDeviceName(ip);
      await prefs.setStringList('daixuankuang_shared', _ipSet.toList());
      await prefs.setString('deviceName_$ip', deviceName ?? '未知设备');
      showNotificationBar(context, "验证成功，IP和设备名已保存");
    } else {
      showNotificationBar(context, "设备连接验证失败");
    }
    
    if (!mounted) return;
    // 同步命令列表
    loadConfig();
  }

    
  //搜索函数 真jb长
  void _startSearching() async {
    setState(() {
      _searching = !_searching;
      if (_searching) {
        _frameColor = Colors.white;
        _inputBoxColor = false;
        //showNotificationBar(context, '正在搜索可用设备 | 网段 ${networkSegment}');
        _searchDevices(); // 将搜索设备的代码移至这里
      } else {
        if (_ipSet.isNotEmpty) {
          showNotificationBar(context, '搜索停止，发现可用设备${_ipSet.length}个');
        } else {
          showNotificationBar(context, '停止搜索');
        }
        _inputBoxColor = true;
        _frameColor = Colors.transparent;
      }
    });
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

  // 2023.10.22 新版搜索函数（2025 2 26优化版）
  void _searchDevices() async {
    int maxIP = 255;
    int foundCount = 0;
    Set<String> _countedInThisScan = Set(); // 本次扫描去重集合
    // 获取本机IP和网段（强制/24子网）
    String currentDeviceIP = await _getLocalIPv4Address();
    List<String> parts = currentDeviceIP.split('.');
    String networkSegment = '${parts[0]}.${parts[1]}.${parts[2]}';
    showNotificationBar(context, '扫描中 | 网段 $networkSegment.0/24');

    final prefs = await SharedPreferences.getInstance();
    // 阶段1: 强制测试所有历史IP（无论是否存活）-------------------------
    List<String> savedIPs = prefs.getStringList('daixuankuang_shared') ?? [];
    await Future.wait(
      savedIPs.map((ip) => Socket.connect(ip, 5201, timeout: Duration(milliseconds: 100))
        .then((socket) {
          final connectedIP = socket.remoteAddress.address;
          final isNewIP = _ipSet.add(connectedIP);
          if (isNewIP) prefs.setStringList('daixuankuang_shared', _ipSet.toList());
          
          // 修复点：只要连接成功且未在本轮计数过就+1
          if (!_countedInThisScan.contains(connectedIP)) {
            foundCount++;
            _countedInThisScan.add(connectedIP);
          }
          
          _getDeviceName(connectedIP);
          _checkDeviceOnline(connectedIP);
          socket.destroy();
        }).catchError((_) {}) 
      )
    );
    // 阶段2: 强制全量扫描当前网段（跳过阶段1已处理的IP）
    int i = 1;
    while (i <= maxIP && _searching) {
      final batch = <Future>[];
      for (int j = i; j < i + 20 && j <= maxIP; j++) {
        final ip = '$networkSegment.$j';
        
        // 新增：跳过已被阶段1处理的IP（包括历史IP和本次新增）
        if (_ipSet.contains(ip)) {  // _ipSet存储所有已知IP
          continue;
        }
        
        batch.add(Socket.connect(ip, 5201, timeout: Duration(milliseconds: 100))
          .then((socket) {
            final connectedIP = socket.remoteAddress.address;
            final isNewIP = _ipSet.add(connectedIP);
            if (isNewIP) prefs.setStringList('daixuankuang_shared', _ipSet.toList());
            
            if (!_countedInThisScan.contains(connectedIP)) {
              foundCount++;
              _countedInThisScan.add(connectedIP);
            }
            
            _getDeviceName(connectedIP);
            _checkDeviceOnline(connectedIP);
            socket.destroy();
          }).catchError((_) {})
        );
      }
      
      i += 20;
      await Future.wait(batch);
    }

    // 状态更新（保持不变）
    setState(() {
      _searching = false;
      _frameColor = Colors.transparent;
    });
    if (foundCount == 0) {
      showNotificationBar(context, '搜索完毕，未发现可用设备');
      _inputBoxColor = _originalColor;
    } else {
      showNotificationBar(context, '搜索完毕，发现可用设备$foundCount个');
    }
    _inputBoxColor = _originalColor;
    _lastSearchedIndex = 1;
    // 搜索完成后更新所有设备状态
    await Future.wait(_ipSet.map((ip) => _checkDeviceOnline(ip)));
  }
  
  //搜索函数结束

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
          
          var response = await responseFuture.timeout(Duration(seconds: 8), onTimeout: () {
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

          setState(() {
              cardOptions = [
                  CardOption('请先连接设备再进行操作', 'http://192.168.1.6:5202/hello', dataCommand: 'echo nb', apiUrlCommand: '', value: null),
              ];
          });
      }
  }


  // 命令执行函数
  static Future<String> fetchData(String apiUrl, String dataCommand, String value) async {
    print("apiUrl: $apiUrl, dataCommand: $dataCommand, value: $value");

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

    if (dataCommand.isEmpty) {
      final response = await http.get(Uri.parse(apiUrl), headers: headers).timeout(Duration(seconds: 10));
      print("设备进行了 get 请求");
      if (response.statusCode == 200) {
        return response.body;
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
        return response.body;
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
        return response.body;
      } else {
        print("状态码: ${response.statusCode},\n响应数据: \n${response.body}");
        throw Exception("状态码: ${response.statusCode},\n响应数据: \n${response.body}");
      }
    }

    // 添加一个默认的返回语句
    throw Exception("无效的命令参数组合");
  }





  //命令列表的点击动画
  Future<void> myAsyncMethod(index) async {
    await Future.delayed(Duration(milliseconds: 235)); //总消耗时间 毫秒
    
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
        barrierDismissible: true, // 允许点击外部关闭对话框
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
                  title: Text('控制台'),
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
                          
                          // 解析响应并显示结果对话框（仅在没取消的情况下）
                          final formattedData = json.decode(responseData);
                          if (formattedData.containsKey('execution_time')) {
                            // 使用保存的上下文显示结果对话框
                            if (mounted) {
                              showDialog(
                                context: currentContext,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('控制台'),
                                    content: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Title: ${formattedData['title']}'),
                                          SizedBox(height: 8),
                                          Text('Execution Time: ${formattedData['execution_time']}'),
                                          SizedBox(height: 8),
                                          Text('Success: ${formattedData['success']}'),
                                          if (formattedData.containsKey('cmd_back') && formattedData['cmd_back'] != null)
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(height: 8),
                                                Text('输出结果:'),
                                                SizedBox(height: 8),
                                                Text('${formattedData['cmd_back']}'),
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
                                  title: Text('错误'),
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
  Widget build(BuildContext context) {
    //黑夜模式
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    isDarkMode = brightness == Brightness.dark;
    ProviderHANHANALL ProviderWDWD = Provider.of<ProviderHANHANALL>(context);
    
    return Scaffold(
      appBar: null,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          _focusNode.unfocus();
        },
        child:
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 输入框和搜索按钮部分
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: _inputBoxColor
                            ? ProviderWDWD.isDarkModeForce
                                ? AppColors.colorConfigShurukuKuang(ProviderWDWD.isDarkModeForce, isDarkMode)
                                : AppColors.colorConfigShurukuKuang(false, isDarkMode)
                            : Colors.red,
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
                          Expanded(
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
                          GestureDetector(
                            onTap: _startSearching,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                color: _searching 
                                    ? Colors.red 
                                    : AppColors.commandApiElement(context, hueShift: 10, saturationBoost: 1),
                              ),
                              child: Icon(
                                _searching ? Icons.close : Icons.search,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // iOS风格折叠列表
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,     
                        highlightColor: Colors.transparent, // 禁用点击高亮
                        splashColor: Colors.transparent,     // 禁用水波纹
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: ProviderWDWD.isDarkModeForce
                              ? AppColors.colorConfigCard(ProviderWDWD.isDarkModeForce, isDarkMode)
                              : Colors.white,
                          border: Border.all(color: Colors.transparent, width: 0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
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
                                  color: ProviderWDWD.isDarkModeForce
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.circle, color: Colors.green, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${_ipSet.where((ip) => _deviceOnlineStatus[ip] ?? false).length}/${_ipSet.length}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
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
                              child: _ipSet.isEmpty
                                  ? Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                        "暂无设备",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 15
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: EdgeInsets.zero,
                                      itemCount: _ipSet.length,
                                      separatorBuilder: (context, index) => Divider(
                                        height: 0,
                                        thickness: 0,
                                        color: Colors.transparent,
                                      ),
                                      itemBuilder: (context, index) {
                                        final ip = _ipSet.elementAt(index);
                                        return Dismissible(
                                          key: Key(ip),
                                          direction: DismissDirection.endToStart,
                                          background: Container(
                                            color: Colors.red,
                                            alignment: Alignment.centerRight,
                                            padding: EdgeInsets.only(right: 20),
                                            child: Icon(Icons.delete, color: Colors.white),
                                          ),
                                          onDismissed: (direction) async {
                                            setState(() {
                                              _ipSet.remove(ip);
                                              _deviceNames.remove(ip);
                                              _deviceOnlineStatus.remove(ip);
                                            });
                                            final prefs = await SharedPreferences.getInstance();
                                            prefs.setStringList('daixuankuang_shared', _ipSet.toList());
                                          },
                                          child: ListTile(
                                            leading: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: _deviceOnlineStatus[ip] ?? false
                                                    ? Colors.green
                                                    : Colors.grey,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            title: FutureBuilder<String?>(
                                              future: Future.any([
                                                _getDeviceName(ip),
                                                Future.delayed(Duration(seconds: 1))
                                              ]),
                                              builder: (context, snapshot) {
                                                final name = snapshot.hasData ? '${snapshot.data}' : '未知设备';
                                                return Text('$ip 【$name】');
                                              },
                                            ),
                                            onTap: () => _updateInput(ip),
                                            trailing: _selectedIp == ip
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
                                        ? ProviderWDWD.isDarkModeForce
                                            ? AppColors.colorConfigCard(ProviderWDWD.isDarkModeForce, isDarkMode)
                                            : AppColors.colorConfigCard(false, isDarkMode)
                                        : Colors.transparent,
                                    shadowColor: isDarkMode_force
                                        ? Colors.black.withOpacity(0.6)
                                        : Colors.black.withOpacity(0.2),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(hasSlider ? 14 : 12),
                                      onTap: () async {
                                        setState(() => isSelectedMap[cardOptions.indexOf(card)] = true);
                                        myAsyncMethod(cardOptions.indexOf(card));
                                        
                                        // 修改这里，使用新的_showDialog方法
                                        _showDialog(
                                          card.apiUrl,
                                          card.dataCommand,
                                          card.apiUrlCommand,
                                          card.value?.toString() ?? "null"
                                        );
                                      },
                                      child: Column(
                                        children: [
                                          ListTile(
                                            title: Text(
                                              card.title,
                                              style: TextStyle(
                                                fontSize: hasSlider ? 16 : 16,
                                                fontWeight: FontWeight.w500,
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
                                                  _timer = Timer(Duration(milliseconds: 500), () {
                                                    if (isSliderReleased && ProviderWDWD.isHuaDong) {
                                                      _showDialog(
                                                        card.apiUrl,
                                                        card.dataCommand,
                                                        card.apiUrlCommand,
                                                        card.value.toString()
                                                      );
                                                    }
                                                  });
                                                  showNotificationBar(context, '${card.title}： ${card.value?.floor()}');
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

  @override
  void dispose() {
    _saveData();
    super.dispose();
  }
}
