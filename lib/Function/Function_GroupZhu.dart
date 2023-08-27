import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '群体命令',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GroupZhu(),
    );
  }
}

class CardOption {
  final String title;
  final String apiUrl;

  CardOption(this.title, this.apiUrl);
}

class GroupZhu extends StatefulWidget {
  @override
  _GroupZhuState createState() => _GroupZhuState();
}

class _GroupZhuState extends State<GroupZhu> {
  bool _searching = false;
  Color _buttonColor = Colors.green;
  Color _frameColor = Colors.transparent;
  Color _inputBoxColor = Colors.white; // Change this to your desired color
  Color _searchingColor = Colors.blue; // Change this to your desired color
  Color _originalColor = Colors.white; // Change this to your desired color
  Set<String> _ipSet = {};
  int _lastSearchedIndex = 1;
  String _selectedIP = '';
  String _selectedDropdownIP = '';
  int _successfulCount = 0;
  int _failedCount = 0;
  List<String> _failedDevices = [];

  String _selectedItem = '请先搜索设备';

  List<CardOption> cardOptions = [
    CardOption('请先连接设备再进行操作', 'http://192.168.1.6:5202/hello'),
  ];

  final TextEditingController _textEditingController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('设备群命令操控'),
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: _startSearching,
              style: ElevatedButton.styleFrom(primary: _buttonColor),
              child: Text(_searching ? '停止搜索' : '开始搜索设备'),
            ),
          ),
          DropdownButton<String>(
            onChanged: (String? newValue) {
              print(""); //BUG语句，onChanged使用null就无法打开预览栏，此项目需要查看预览框的元素，所以设置print("空值")
            },
            value: _selectedDropdownIP.isNotEmpty ? _selectedDropdownIP : null,
            hint: Text(_ipSet.isEmpty
                ? "请先搜索设备"
                : "发现${_ipSet.length}个可用设备"),
            items: _ipSet.isEmpty
                ? null
                : _ipSet.map((String ip) {
                    return DropdownMenuItem<String>(
                      value: ip,
                      child: Text(ip),
                    );
                  }).toList(),
          ),
          ElevatedButton(
            onPressed: loadConfig,
            child: Text('加载配置(搜索到设备后加载)'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: cardOptions.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    if (_ipSet.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('控制台'),
                            content: Text('当前有${_ipSet.length}个设备，是否执行群体命令？'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('是'),
                                onPressed: () {
                                  Navigator.of(context).pop(); // Close the dialog
                                  // Execute group command
                                  _executeGroupCommand(cardOptions[index].apiUrl);
                                },
                              ),
                              TextButton(
                                child: Text('否'),
                                onPressed: () {
                                  Navigator.of(context).pop(); // Close the dialog
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: ListTile(
                    title: Text(cardOptions[index].title),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> loadConfig() async {
    print(_selectedIP);
    var url = Uri.parse('http://${_selectedIP}:5202/orderlist');
    var headers = {
      'Authorization': 'i am Han Han',
      'Content-Type': 'application/json',
    };
    try {
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        showNotificationBar(context, '已连接设备 ${_selectedIP}');
        String configString = response.body;
        List<dynamic> configData = json.decode(configString);

        setState(() {
          cardOptions = configData
              .map((item) => CardOption(item['title'], item['apiUrl']))
              .toList();
        });
      } else {
        throw Exception('Failed to load data');
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

  void _startSearching() async {
    setState(() {
      _searching = !_searching;
      if (_searching) {
        _buttonColor = Colors.red;
        _frameColor = Colors.white;
        _inputBoxColor = _searchingColor;
        //showNotificationBar(context, '正在搜索可用设备');
        _searchDevices();
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
          if (_selectedIP.isEmpty) {
            setState(() {
              _selectedIP = socket.remoteAddress.address;
              _textEditingController.text = _selectedIP;
            });
          }

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

  //格式工厂，将 url 去除地址。好让群体发送函数使用
  List<String> formatAndExtract(String apiUrl) {
    if (!apiUrl.startsWith("http://") && !apiUrl.startsWith("https://")) {
      throw ArgumentError("Invalid URL format. The URL must start with 'http://' or 'https://'");
    }
    
    String protocol = "";
    if (apiUrl.startsWith("http://")) {
      protocol = "http://";
    } else if (apiUrl.startsWith("https://")) {
      protocol = "https://";
    }
    
    int slashIndex = apiUrl.indexOf("/", protocol.length);
    if (slashIndex == -1) {
      throw ArgumentError("Invalid URL format. The URL must contain a path after the domain.");
    }
    
    String ipWithPort = apiUrl.substring(protocol.length, slashIndex);
    String port = "";
    String extractedPath = apiUrl.substring(slashIndex);
    
    int portIndex = ipWithPort.lastIndexOf(":");
    if (portIndex != -1) {
      port = ipWithPort.substring(portIndex + 1);
      ipWithPort = ipWithPort.substring(0, portIndex); // Remove the port part from the ipWithPort
    }
    
    return [protocol, port, extractedPath];
  }

  //群体命令执行
  void _executeGroupCommand(String apiUrl) {
    _successfulCount = 0;
    _failedCount = 0;
    _failedDevices.clear();

    List<String> apiUrlParts = formatAndExtract(apiUrl);

    Future.wait(_ipSet.map((ip) async {
      String combinedApiUrl = "${apiUrlParts[0]}${ip}:${apiUrlParts[1]}${apiUrlParts[2]}";
      String fetchDataUrl_return = await fetchData(combinedApiUrl);
      print(fetchDataUrl_return);
      if (fetchDataUrl_return == "success") {
        _successfulCount++;
      } else {
        _failedCount++;
        _failedDevices.add(ip);
      }
    })).then((_) {
      // Show the results dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('执行结果'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('成功发送: $_successfulCount'),
                Text('发送失败: $_failedCount'),
                if (_failedCount > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Text('失败的设备:'),
                      for (String failedDevice in _failedDevices) Text(failedDevice),
                    ],
                  ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text('关闭'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
            ],
          );
        },
      );
    });
  }

  //命令执行函数
  static Future<dynamic> fetchData(String apiUrl) async {
    final Map<String, String> headers = {
      'Authorization': 'i am Han Han',
      'Content-Type': 'application/json',
    };
    print(apiUrl);

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: headers).timeout(Duration(milliseconds: 500));
      //print("Status Code: ${response.statusCode}");
      //print("Body: ${response.body}");
      if (response.statusCode == 200) {
        return "success"; // 返回1表示成功访问
      } else {
        return "error"; // 返回"error"表示访问失败
      }
    } catch (e) {
      return "error"; // 返回"error"表示发生异常，访问失败或超时
    }
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
}