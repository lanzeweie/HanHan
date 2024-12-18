import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
  Color _buttonColor = Colors.green;
  Color _frameColor = Colors.transparent;
  List<CardOption> cardOptions = [];
  bool _isLoading = false;
  // 搜索专用
  String? _selectedIp;
  int _lastSearchedIndex = 1; // 用于记录最后一次搜索的IP位置，默认从1开始
  Set<String> _ipSet = {}; // 使用 Set 而不是 List
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

  // 持久化保存数据
  Future<void> _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String savedData = prefs.getString('input_data') ?? '';
    setState(() {
      _textEditingController.text = savedData;
    });
  }

  //输入框信息自动保存
  void _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('input_data', _textEditingController.text);

    if (!mounted) return;

    showNotificationBar(context, "数据已保存");
    //同步一次命令列表
    loadConfig();
  }



  //搜索函数 真jb长
  void _startSearching() async {
    setState(() {
      _searching = !_searching;
      if (_searching) {
        _buttonColor = Colors.red;
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
        _buttonColor = Colors.green;
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
  //2023.10.22 新版搜索函数
  void _searchDevices() async {
    int maxIP = 255;
    int foundCount = 0;

    String currentDeviceIP = await _getLocalIPv4Address();
    List<String> parts = currentDeviceIP.split('.');
    String networkSegment = '${parts[0]}.${parts[1]}.${parts[2]}';
    showNotificationBar(context, '正在搜索可用设备 | 网段 ${networkSegment}');

    final futures = <Future>[];
    int i = 1;
    while (i <= maxIP) {
      if (_searching) {
        final batch = <Future>[];
        for (int j = i; j < i + 20 && j <= maxIP; j++) {
          final ip = '$networkSegment.$j';
          batch.add(
            Socket.connect(ip, 5201, timeout: Duration(milliseconds: 100))
                .then((socket) {
              _ipSet.add(socket.remoteAddress.address);
              foundCount++;
            }).catchError((error) {
              // Ignore connection errors.
            }),
          );
        }
        i += 20;
        futures.addAll(batch);
        await Future.wait(batch);
      } else {
        break;
      }
    }

    if (!_searching) {
      setState(() {
        _buttonColor = Colors.green;
        _frameColor = Colors.transparent;
      });
    } else {
      setState(() {
        _searching = false;
        _buttonColor = Colors.green;
        _frameColor = Colors.transparent;
      });

      if (foundCount == 0) {
        showNotificationBar(context, '搜索完毕，未发现可用设备');
        _inputBoxColor = _originalColor;
      } else {
        showNotificationBar(context, '搜索完毕，发现可用设备$foundCount个');
      }
      _inputBoxColor = _originalColor;
      // 初始化搜索进度
      _lastSearchedIndex = 1;
    }
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
                          if (item.containsKey('datacommand') && !item.containsKey('value')) {
                              return CardOption(
                                  item['title'],
                                  item['apiUrl'],
                                  dataCommand: item['datacommand'],
                                  apiUrlCommand: '',
                                  value: null,
                              );
                          } else if (item.containsKey('apiUrlCommand')) {
                              return CardOption(
                                  item['title'],
                                  item['apiUrl'],
                                  dataCommand: '',
                                  apiUrlCommand: item['apiUrlCommand'],
                                  value: null,
                              );
                          } else if (item.containsKey('datacommand') && item.containsKey('value')) {
                              return CardOption(
                                  item['title'],
                                  item['apiUrl'],
                                  dataCommand: item['datacommand'],
                                  apiUrlCommand: '',
                                  value: double.parse(item['value'].toString()),
                              );
                          } else {
                              return CardOption(
                                  item['title'],
                                  item['apiUrl'],
                                  dataCommand: '',
                                  apiUrlCommand: '',
                                  value: null,
                              );
                          }
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
    throw Exception("未知错误");
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
    try {
      setState(() {
        _isLoading = true; // 显示等待框
      });
      
      String responseData = await fetchData(apiUrl, dataCommand, value);
      Map<String, dynamic> formattedData;
      
      setState(() {
        _isLoading = false; // 隐藏等待框
      });

      try {
        formattedData = json.decode(responseData);
        if (formattedData != null && formattedData.containsKey('execution_time')) {
          dynamic executionTime = formattedData['execution_time'];
          // 执行适当的操作
          showDialog(
            context: context,
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
                      Text('Execution Time: $executionTime'),
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
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red, // 保持背景色不变
                      foregroundColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white // 黑夜模式字体颜色
                          : Colors.black, // 日间模式字体颜色
                    ),
                    child: Text('Close'),
                  ),
                ],
              );
            },
          );
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('控制台 原数据'),
                content: Text('$formattedData'), // 输出原始数据
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white // 黑夜模式字体颜色
                          : Colors.black, // 日间模式字体颜色
                    ),
                    child: Text('Close'),
                  ),
                ],
              );
            },
          );
        }
      } catch (e) {
        // 处理解析JSON时的异常
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('控制台 原数据'),
              content: Text('$responseData'), // 输出原始数据
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white // 黑夜模式字体颜色
                        : Colors.black, // 日间模式字体颜色
                  ),
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // 隐藏等待框
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('控制台 错误信息'),
            content: Text('$e'), // 输出原始数据
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text('Close'),
              ),
            ],
          );
        },
      );
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
    isDarkMode = brightness == Brightness.dark; // Update isDarkMode variable
    ProviderHANHANALL ProviderWDWD = Provider.of<ProviderHANHANALL>(context);
    //print("我在主页2，我的暗黑模式是：${ProviderWDWD.isDarkModeForce}");
    //print("我在主页2，我的暗黑模式是：${isDarkMode}");
    //print("我在主页2，我的滑动条命令执行方式是：${ProviderWDWD.isHuaDong}");
    return Scaffold(
      appBar: null,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          _focusNode.unfocus();
        },
        child: _isLoading
            ? _buildLoadingDialog()
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: _inputBoxColor
                            ? ProviderWDWD.isDarkModeForce
                                ? AppColors.colorConfigShurukuKuang(ProviderWDWD.isDarkModeForce, isDarkMode)
                                : isDarkMode
                                    ? AppColors.colorConfigShurukuKuang(false, isDarkMode)
                                    : AppColors.colorConfigShurukuKuang(false, isDarkMode)
                            : Colors.red,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5), //输入框四周的背景颜色
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
                                      ? AppColors.colorConfigTextShuruku(ProviderWDWD.isDarkModeForce,isDarkMode)
                                      : isDarkMode
                                          ? AppColors.colorConfigTextShuruku(false,isDarkMode)
                                          : AppColors.colorConfigTextShuruku(false,isDarkMode),
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
                                shape: BoxShape.rectangle, // 使用矩形形状搜索框按钮
                                color: _buttonColor,
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
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.only(left: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: _ipSet.isEmpty
                              ? Text("请先搜索设备")
                              : Text("发现${_ipSet.length}个可用设备"),
                          value: _selectedIp,
                          onChanged: _updateInput,
                          items: _ipSet.isEmpty
                              ? null
                              : _ipSet.map((String ip) {
                                  return DropdownMenuItem(
                                    value: ip,
                                    child: Text(
                                      ip,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  );
                                }).toList(),
                          icon: _ipSet.isEmpty
                              ? Icon(Icons.arrow_drop_down, color: Colors.grey)
                              : Icon(Icons.arrow_drop_down, color: Colors.green),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: cardOptions.length,
                        itemBuilder: (context, index) {
                          final isSelected = isSelectedMap[index] ?? false;
                          final cardOption = cardOptions[index];
                          return Card(
                            elevation: 8,  // 增加阴影的高度
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),  // 边角更圆润
                              side: BorderSide(
                                color: isDarkMode_force
                                    ? Colors.grey.shade600 // 夜间模式下的边框颜色
                                    : Colors.grey.shade300, // 白天模式下的边框颜色
                                width: 1,
                              ),
                            ),
                            color: _inputBoxColor
                              ? ProviderWDWD.isDarkModeForce
                                  ? AppColors.colorConfigCard(ProviderWDWD.isDarkModeForce, isDarkMode)
                                  : isDarkMode
                                      ? AppColors.colorConfigCard(false, isDarkMode)
                                      : AppColors.colorConfigCard(false, isDarkMode)
                              : Colors.transparent,  // 透明背景
                            shadowColor: isDarkMode_force
                              ? Colors.black.withOpacity(0.6) // 夜间模式下的阴影颜色
                              : Colors.black.withOpacity(0.2), // 白天模式下的阴影颜色
                            child: InkWell(
                              onTap: () async {
                                setState(() {
                                  isSelectedMap[index] = true;
                                });
                                myAsyncMethod(index);
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('控制台'),
                                      content: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Text('是否执行此命令?'),
                                          if (cardOption.dataCommand != null && cardOption.dataCommand.isNotEmpty)
                                            Text(
                                              '命令内容: ${cardOption.dataCommand.substring(0, min(cardOption.dataCommand.length, 150))}${cardOption.dataCommand.length > 150 ? "..." : ""}',
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          if (cardOption.apiUrlCommand != null && cardOption.apiUrlCommand.isNotEmpty)
                                            Text(
                                              'API URL命令: ${cardOption.apiUrl}',
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          if (cardOption.value != null) // Added condition to display value
                                            Text(
                                              '${cardOption.title}: ${cardOption.value?.floor()}',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                        ],
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          style: TextButton.styleFrom(
                                            backgroundColor: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.red[700] // 黑夜模式
                                                : Colors.red, // 日间模式
                                            foregroundColor: Colors.white, // 字体颜色统一为白色
                                          ),
                                          child: Text('取消'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            _showDialog(cardOption.apiUrl, cardOption.dataCommand, cardOption.apiUrlCommand, cardOption.value.toString());
                                            Navigator.of(context).pop();
                                          },
                                          style: TextButton.styleFrom(
                                            backgroundColor: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.indigo[800] // 黑夜模式
                                                : Colors.indigo, // 日间模式
                                            foregroundColor: Colors.white, // 字体颜色统一为白色
                                          ),
                                          child: Text('执行'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    leading: Icon(Icons.play_arrow),
                                    title: Text(cardOption.title),
                                    subtitle: cardOption.dataCommand != null && cardOption.dataCommand.isNotEmpty
                                        ? Text(
                                            '自定义命令',
                                            style: TextStyle(color: Colors.green),
                                          )
                                        : cardOption.apiUrlCommand != null && cardOption.apiUrlCommand.isNotEmpty
                                            ? Text(
                                                '自定义API',
                                                style: TextStyle(color: Colors.green),
                                              )
                                            : null,
                                  ),
                                  if (cardOption.value != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Slider(
                                        value: cardOption.value!,
                                        min: 0,
                                        max: 100,
                                        onChanged: (newValue) {
                                          setState(() {
                                            cardOption.value = newValue;
                                          });
                                        },
                                        onChangeEnd: (newValue) {
                                          setState(() {
                                            cardOption.value = newValue;
                                          });
                                          isSliderReleased = true;
                                          _timer = Timer(Duration(milliseconds: 500), () {
                                            if (isSliderReleased && ProviderWDWD.isHuaDong) {
                                              // 执行命令
                                              _showDialog(cardOption.apiUrl, cardOption.dataCommand, cardOption.apiUrlCommand, cardOption.value.toString());
                                            }
                                          });
                                          showNotificationBar(context, '${cardOption.title}： ${cardOption.value?.floor()}');
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
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
