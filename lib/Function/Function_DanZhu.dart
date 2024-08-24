import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

//我是主页面，很多函数都可以互相调用的

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '指定设备命令',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: DanZhu(),
    );
  }
}

class CardOption {
  final String title;
  final String apiUrl;

  CardOption(this.title, this.apiUrl);
}

class DanZhu extends StatefulWidget {
  @override
  _DanZhuState createState() => _DanZhuState();
}

class _DanZhuState extends State<DanZhu> {
  
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
  Color _inputBoxColor = Colors.white; // 输入框的初始颜色
  Color _originalColor = Colors.white; // 替换为你的原始颜色
  Color _searchingColor = Colors.red;  // 替换为你的搜索颜色
  Duration _animationDuration = Duration(milliseconds: 300); // 动画的时间
  FocusNode _focusNode = FocusNode();
  //命令列表
  Map<int, bool> isSelectedMap = {};

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
      content: Text(message),
      duration: Duration(seconds: 2),
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
        _inputBoxColor = _searchingColor;
        //showNotificationBar(context, '正在搜索可用设备 | 网段 ${networkSegment}');
        _searchDevices(); // 将搜索设备的代码移至这里
      } else {
        if (_ipSet.isNotEmpty) {
          showNotificationBar(context, '搜索停止，发现可用设备${_ipSet.length}个');
        } else {
          showNotificationBar(context, '停止搜索');
        }
        _inputBoxColor = _originalColor;
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
  void _searchDevices() async {
    int maxIP = 255;
    int foundCount = 0;

    String currentDeviceIP = await _getLocalIPv4Address();
    List<String> parts = currentDeviceIP.split('.');
    String networkSegment = '${parts[0]}.${parts[1]}.${parts[2]}';
    showNotificationBar(context, '正在搜索可用设备 | 网段 ${networkSegment}');
    for (int i = _lastSearchedIndex; i <= maxIP; i++) {
      if (_searching) {
        try {
          final socket = await Socket.connect(
            '$networkSegment.$i',
            5201,
            timeout: Duration(milliseconds: 100),
          );
          _ipSet.add(socket.remoteAddress.address);
          foundCount++;

          setState(() {
            _lastSearchedIndex = i + 1;
          });
        } catch (e) {
          print(e);
        }
      } else {
        setState(() {
          _lastSearchedIndex = i;
        });
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
    var url = Uri.parse('http://${_textEditingController.text}:5202/orderlist');
    var headers = {
      'Authorization': 'i am Han Han',
      'Content-Type': 'application/json',
    };
    try {
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        showNotificationBar(context, '已连接设备 ${_textEditingController.text}');
        String configString = response.body;
        List<dynamic> configData = json.decode(configString);

        setState(() {
          cardOptions = configData
              .map((item) => CardOption(item['title'], item['apiUrl']))
              .toList();
        });
      } else {
        throw Exception('未能从读取配置数据');
      }
    } catch (e) {
      print('Error: $e');
      
      setState(() {
        // Default configuration
        cardOptions = [
          CardOption('请先连接设备再进行操作', 'http://192.168.1.6:5202/hello'),
        ];
      });
    }
  }

  //命令执行函数
  Future<Map<String, dynamic>> fetchData(String apiUrl) async {
    print(_textEditingController.text);
    String apiurlip = _textEditingController.text;
    if (apiurlip.isEmpty) {
      apiurlip = '127.0.0.1';
    }
    final Map<String, String> headers = {
      'Authorization': 'i am Han Han',
      'Content-Type': 'application/json',
    };

    // 使用正则表达式来提取协议、地址、端口和路径
    final RegExp regex = RegExp(r'^(https?://)?([^:/]+)(:([0-9]+))?(/.*)?$');
    final Match? match = regex.firstMatch(apiUrl);

    if (match != null) {
      // 提取协议、地址、端口和路径部分
      final String? protocol = match.group(1);
      final String? address = match.group(2);
      final String? port = match.group(4);
      final String? path = match.group(5);

      // Check if the address is an IP
      final isIPAddress = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(address ?? '');

      // Modify the URL only if the address is an IP
      final modifiedUrl = isIPAddress ? '$protocol$apiurlip:$port$path' : apiUrl;
      print(modifiedUrl);

      final response = await http.get(Uri.parse(modifiedUrl), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to load data');
      }
    } else {
      throw Exception('Invalid apiUrl format');
    }
  }


  //命令列表的点击动画
  Future<void> myAsyncMethod(index) async {
    await Future.delayed(Duration(milliseconds: 235)); //总消耗时间 毫秒
    
    setState(() {
      isSelectedMap[index] = false;
    });
  }
  //命令列表结束

  Future<void> _showDialog(String apiUrl) async {
    try {
      setState(() {
        _isLoading = true; // 显示等待框
      });

      Map<String, dynamic> responseData = await fetchData(apiUrl);

      setState(() {
        _isLoading = false; // 隐藏等待框
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('API Response'),
            content: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Title: ${responseData['title']}'),
                  SizedBox(height: 8),
                  Text('Execution Time: ${responseData['execution_time']}'),
                  SizedBox(height: 8),
                  Text('Success: ${responseData['success']}'),
                ],
              ),
            ),
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
    } catch (e) {
      setState(() {
        _isLoading = false; // 隐藏等待框
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to load data from API.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('设备固定地址操控'),
      ),
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
                  Stack(
                    children: [
                      AnimatedContainer(
                        duration: _animationDuration, // 动画持续时间
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: _inputBoxColor, // 使用动画颜色
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5), // Shadow color
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3), // Shadow offset
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextField(
                            controller: _textEditingController,
                            style: TextStyle(fontSize: 16, color: Colors.black), // Normal font size and black text color
                            focusNode: _focusNode,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "请输入设备IP或搜索设备",
                              hintStyle: TextStyle(color: Colors.grey), // Gray hint text color
                            ),
                            onEditingComplete: _saveData,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: GestureDetector(
                          onTap: _startSearching,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _buttonColor,
                            ),
                            child: Icon(
                              _searching ? Icons.close : Icons.search,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                        return Card(
                          elevation: 4,
                          margin: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
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
                                    content:
                                        Text('是否执行此命令?'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _showDialog(cardOptions[index].apiUrl);
                                          Navigator.of(context).pop();
                                        },
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.indigo,
                                        ),
                                        child: Text('执行'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 140), //变色需要多久
                              curve: Curves.elasticOut,
                              color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent, //颜色深度
                              child: ListTile(
                                leading: Icon(Icons.play_arrow),
                                title: Text(cardOptions[index].title),
                              ),
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

//我是主页面，很多函数都可以互相调用的

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '指定设备命令',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: DanZhu(),
    );
  }
}

class CardOption {
  final String title;
  final String apiUrl;

  CardOption(this.title, this.apiUrl);
}

class DanZhu extends StatefulWidget {
  @override
  _DanZhuState createState() => _DanZhuState();
}

class _DanZhuState extends State<DanZhu> {
  
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
  Color _inputBoxColor = Colors.white; // 输入框的初始颜色
  Color _originalColor = Colors.white; // 替换为你的原始颜色
  Color _searchingColor = Colors.red;  // 替换为你的搜索颜色
  Duration _animationDuration = Duration(milliseconds: 300); // 动画的时间
  FocusNode _focusNode = FocusNode();
  //命令列表
  Map<int, bool> isSelectedMap = {};

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
      content: Text(message),
      duration: Duration(seconds: 2),
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
        _inputBoxColor = _searchingColor;
        //showNotificationBar(context, '正在搜索可用设备 | 网段 ${networkSegment}');
        _searchDevices(); // 将搜索设备的代码移至这里
      } else {
        if (_ipSet.isNotEmpty) {
          showNotificationBar(context, '搜索停止，发现可用设备${_ipSet.length}个');
        } else {
          showNotificationBar(context, '停止搜索');
        }
        _inputBoxColor = _originalColor;
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
  void _searchDevices() async {
    int maxIP = 255;
    int foundCount = 0;

    String currentDeviceIP = await _getLocalIPv4Address();
    List<String> parts = currentDeviceIP.split('.');
    String networkSegment = '${parts[0]}.${parts[1]}.${parts[2]}';
    showNotificationBar(context, '正在搜索可用设备 | 网段 ${networkSegment}');
    for (int i = _lastSearchedIndex; i <= maxIP; i++) {
      if (_searching) {
        try {
          final socket = await Socket.connect(
            '$networkSegment.$i',
            5201,
            timeout: Duration(milliseconds: 100),
          );
          _ipSet.add(socket.remoteAddress.address);
          foundCount++;

          setState(() {
            _lastSearchedIndex = i + 1;
          });
        } catch (e) {
          print(e);
        }
      } else {
        setState(() {
          _lastSearchedIndex = i;
        });
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
    var url = Uri.parse('http://${_textEditingController.text}:5202/orderlist');
    var headers = {
      'Authorization': 'i am Han Han',
      'Content-Type': 'application/json',
    };
    try {
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        showNotificationBar(context, '已连接设备 ${_textEditingController.text}');
        String configString = response.body;
        List<dynamic> configData = json.decode(configString);

        setState(() {
          cardOptions = configData
              .map((item) => CardOption(item['title'], item['apiUrl']))
              .toList();
        });
      } else {
        throw Exception('未能从读取配置数据');
      }
    } catch (e) {
      print('Error: $e');
      
      setState(() {
        // Default configuration
        cardOptions = [
          CardOption('请先连接设备再进行操作', 'http://192.168.1.6:5202/hello'),
        ];
      });
    }
  }

  //命令执行函数
  Future<Map<String, dynamic>> fetchData(String apiUrl) async {
    print(_textEditingController.text);
    String apiurlip = _textEditingController.text;
    if (apiurlip.isEmpty) {
      apiurlip = '127.0.0.1';
    }
    final Map<String, String> headers = {
      'Authorization': 'i am Han Han',
      'Content-Type': 'application/json',
    };

    // 使用正则表达式来提取协议、地址、端口和路径
    final RegExp regex = RegExp(r'^(https?://)?([^:/]+)(:([0-9]+))?(/.*)?$');
    final Match? match = regex.firstMatch(apiUrl);

    if (match != null) {
      // 提取协议、地址、端口和路径部分
      final String? protocol = match.group(1);
      final String? address = match.group(2);
      final String? port = match.group(4);
      final String? path = match.group(5);

      // Check if the address is an IP
      final isIPAddress = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(address ?? '');

      // Modify the URL only if the address is an IP
      final modifiedUrl = isIPAddress ? '$protocol$apiurlip:$port$path' : apiUrl;
      print(modifiedUrl);

      final response = await http.get(Uri.parse(modifiedUrl), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to load data');
      }
    } else {
      throw Exception('Invalid apiUrl format');
    }
  }


  //命令列表的点击动画
  Future<void> myAsyncMethod(index) async {
    await Future.delayed(Duration(milliseconds: 235)); //总消耗时间 毫秒
    
    setState(() {
      isSelectedMap[index] = false;
    });
  }
  //命令列表结束

  Future<void> _showDialog(String apiUrl) async {
    try {
      setState(() {
        _isLoading = true; // 显示等待框
      });

      Map<String, dynamic> responseData = await fetchData(apiUrl);

      setState(() {
        _isLoading = false; // 隐藏等待框
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('API Response'),
            content: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Title: ${responseData['title']}'),
                  SizedBox(height: 8),
                  Text('Execution Time: ${responseData['execution_time']}'),
                  SizedBox(height: 8),
                  Text('Success: ${responseData['success']}'),
                ],
              ),
            ),
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
    } catch (e) {
      setState(() {
        _isLoading = false; // 隐藏等待框
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to load data from API.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('设备固定地址操控'),
      ),
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
                  Stack(
                    children: [
                      AnimatedContainer(
                        duration: _animationDuration, // 动画持续时间
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: _inputBoxColor, // 使用动画颜色
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5), // Shadow color
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3), // Shadow offset
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextField(
                            controller: _textEditingController,
                            style: TextStyle(fontSize: 16, color: Colors.black), // Normal font size and black text color
                            focusNode: _focusNode,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "请输入设备IP或搜索设备",
                              hintStyle: TextStyle(color: Colors.grey), // Gray hint text color
                            ),
                            onEditingComplete: _saveData,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: GestureDetector(
                          onTap: _startSearching,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _buttonColor,
                            ),
                            child: Icon(
                              _searching ? Icons.close : Icons.search,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                        return Card(
                          elevation: 4,
                          margin: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
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
                                    content:
                                        Text('是否执行此命令?'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _showDialog(cardOptions[index].apiUrl);
                                          Navigator.of(context).pop();
                                        },
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.indigo,
                                        ),
                                        child: Text('执行'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 140), //变色需要多久
                              curve: Curves.elasticOut,
                              color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent, //颜色深度
                              child: ListTile(
                                leading: Icon(Icons.play_arrow),
                                title: Text(cardOptions[index].title),
                              ),
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