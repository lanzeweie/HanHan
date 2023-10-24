import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:async';

//我是主页面，很多函数都可以互相调用的

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Options App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: ZhuPage(),
    );
  }
}

class CardOption {
  final String title;
  final String apiUrl;
  final String dataCommand;
  final String apiUrlCommand;

  CardOption(this.title, this.apiUrl, {required this.dataCommand,required this.apiUrlCommand});
}

class ZhuPage extends StatefulWidget {
  @override
  _ZhuPageState createState() => _ZhuPageState();
}

class _ZhuPageState extends State<ZhuPage> {
  
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
          cardOptions = configData.map((item) {
            if (item.containsKey('datacommand')) {
              return CardOption(
                item['title'],
                item['apiUrl'],
                dataCommand: item['datacommand'],
                apiUrlCommand: '',
              );
            } else if (item.containsKey('apiUrlCommand')) {
              return CardOption(
                item['title'],
                item['apiUrl'],
                dataCommand: '',
                apiUrlCommand: item['apiUrlCommand'],
              );
            } else {
              return CardOption(item['title'], item['apiUrl'], dataCommand: '', apiUrlCommand: '');
            }
          }).toList();
        });
      } else {
        throw Exception('未能从读取配置数据');
      }
    } catch (e) {
      print('Error: $e');
      
      setState(() {
        // Default configuration
        cardOptions = [
          CardOption('请先连接设备再进行操作', 'http://192.168.1.6:5202/hello', dataCommand: '', apiUrlCommand:''),
        ];
      });
    }
  }

  // 命令执行函数
  static Future<String> fetchData(String apiUrl, String dataCommand) async {
    final Map<String, String> headers = {
      'Authorization': 'i am Han Han',
      'Content-Type': 'application/json',
    };

    if (dataCommand.isEmpty) {
      final response = await http.get(Uri.parse(apiUrl), headers: headers).timeout(Duration(seconds: 3));
      print("设备进行了 get 请求");
      if (response.statusCode == 200) {
        return response.body;
      } else if (response.statusCode != 200) {
        print("状态码: ${response.statusCode},\n响应数据: \n${response.body}");
        throw Exception("状态码: ${response.statusCode},\n响应数据: \n${response.body}");
      } else {
        print("请求失败，状态码: ${response.statusCode}");
        throw Exception("请求失败，状态码: ${response.statusCode}");
      }
    } else {
      final Map<String, dynamic> requestData = {
        'name': 'han han',
        'command': dataCommand,
      };
      print("设备进行了 post 请求");
      final response = await http.post(Uri.parse(apiUrl), headers: headers, body: json.encode(requestData)).timeout(Duration(seconds: 3));

      if (response.statusCode == 200) {
        return response.body;
      } else if (response.statusCode != 200) {
        print("状态码: ${response.statusCode},\n响应数据: \n${response.body}");
        throw Exception("状态码: ${response.statusCode},\n响应数据: \n${response.body}");
      } else {
        print("请求失败，状态码: ${response.statusCode}");
        throw Exception("请求失败，状态码: ${response.statusCode}");
      }
    }
  }




  //命令列表的点击动画
  Future<void> myAsyncMethod(index) async {
    await Future.delayed(Duration(milliseconds: 235)); //总消耗时间 毫秒
    
    setState(() {
      isSelectedMap[index] = false;
    });
  }

  //控制台提示窗
  Future<void> _showDialog(String apiUrl, String dataCommand, String apiUrlCommand) async {
    try {
      setState(() {
        _isLoading = true; // 显示等待框
      });
      
      if (responseData.isNotEmpty) {
        String responseData = await fetchData(apiUrl, dataCommand);
        Map<String, dynamic> formattedData;
      }
      
      try {
        formattedData = json.decode(responseData);
      } catch (e) {
        // 处理解析JSON时的异常
        print("解析JSON时出现异常: $e");
        // 这里可以添加适当的错误处理逻辑
      }

      print("啊？");

      setState(() {
        _isLoading = false; // 隐藏等待框
      });
      print("控制台窗口的逻辑判断");
      if (responseData.isNotEmpty) {
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
                    Text('Title: ${responseData['title']}'),
                    SizedBox(height: 8),
                    Text('Execution Time: ${responseData['execution_time']}'),
                    SizedBox(height: 8),
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
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    primary: Colors.red,
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
              title: Text('API Response'),
              content: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('$responseData'),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    primary: Colors.red,
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
            title: Text('控制台 原数据'),
            content: Text('$e'), // 输出原始数据
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  primary: Colors.red,
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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(45),
        child: AppBar(
          title: Text(
            '涵涵的超级控制面板',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Color(0xFF5d58c1),
        ),
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
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: _inputBoxColor,
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
                                style: TextStyle(fontSize: 16, color: Colors.black),
                                focusNode: _focusNode,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "请输入设备IP或搜索设备",
                                  hintStyle: TextStyle(color: Colors.grey),
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
                                shape: BoxShape.circle,
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
                            elevation: 4,
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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
                                        ],
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          style: TextButton.styleFrom(
                                            primary: Colors.red,
                                          ),
                                          child: Text('取消'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            _showDialog(cardOption.apiUrl, cardOption.dataCommand, cardOption.apiUrlCommand);
                                            Navigator.of(context).pop();
                                          },
                                          style: TextButton.styleFrom(
                                            primary: Colors.indigo,
                                          ),
                                          child: Text('执行'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                                ),
                                child: ListTile(
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