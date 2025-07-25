import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../Config/device_utils.dart';

class IDPage extends StatefulWidget {
  @override
  _IDPageState createState() => _IDPageState();
}

class _IDPageState extends State<IDPage> {
  Map<String, Map<String, dynamic>> _deviceData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initDeviceData();
  }

  Future<void> _initDeviceData() async {
    setState(() {
      _isLoading = true;
    });

    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    Map<String, Map<String, dynamic>> deviceData = {};

    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        deviceData = _readAndroidBuildData(await deviceInfoPlugin.androidInfo);
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        deviceData = _readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
      }
    } catch (e) {
      deviceData = {"错误信息": {"详情": "无法获取设备信息: $e"}};
    }

    if (!mounted) return;

    setState(() {
      _deviceData = deviceData;
      _isLoading = false;
    });

    // 调用独立的函数以获取和保存设备信息
    await updateDeviceData();
  }

  Map<String, Map<String, dynamic>> _readAndroidBuildData(AndroidDeviceInfo build) {
    return {
      "基本信息": {
        '设备ID': build.id,
        '制造商': build.manufacturer,
        '品牌': build.brand,
        '型号': build.model,
        '设备名': build.device,
        '产品名': build.product,
        '设备类型': build.isPhysicalDevice ? '实体设备' : '模拟器',
      },
      "系统信息": {
        'Android版本': build.version.release,
        'SDK版本': build.version.sdkInt.toString(),
        '安全补丁级别': build.version.securityPatch ?? '未知',
        '操作系统代号': build.version.codename,
      },
      "硬件信息": {
        '处理器': build.hardware,
        '支持的ABIs': build.supportedAbis.join(', '),
        '设备形态': _guessDeviceType(build),
        '支持32位ABIs': build.supported32BitAbis.join(', '),
        '支持64位ABIs': build.supported64BitAbis.join(', '),
      },
      "其他信息": {
        '指纹': build.fingerprint,
        '主板': build.board,
        '引导加载程序': build.bootloader,
        '构建标签': build.tags,
        '构建类型': build.type,
        '主机': build.host,
      },
    };
  }

  // 根据设备信息推测设备类型
  String _guessDeviceType(AndroidDeviceInfo build) {
    // 一些常见的平板品牌型号关键词
    final List<String> tabletIndicators = [
      'tablet', 'tab', 'pad', 'mediapad', 'slate'
    ];
    
    String model = build.model.toLowerCase();
    String device = build.device.toLowerCase();
    String product = build.product.toLowerCase();
    
    // 检查设备名称中是否包含平板相关关键词
    for (String indicator in tabletIndicators) {
      if (model.contains(indicator) || 
          device.contains(indicator) || 
          product.contains(indicator)) {
        return '可能是平板';
      }
    }
    
    // 默认认为是手机
    return '可能是手机';
  }

  Map<String, Map<String, dynamic>> _readIosDeviceInfo(IosDeviceInfo data) {
    return {
      "基本信息": {
        '设备ID': data.identifierForVendor ?? '未知',
        '设备名称': data.name,
        '型号': data.model,
        '本地化型号': data.localizedModel,
        '设备类型': data.isPhysicalDevice ? '实体设备' : '模拟器',
      },
      "系统信息": {
        '系统名称': data.systemName,
        '系统版本': data.systemVersion,
        '系统语言': Localizations.localeOf(context).languageCode,
      },
      "硬件信息": {
        'CPU架构': data.utsname.machine,
        '节点名': data.utsname.nodename,
      },
      "其他信息": {
        '构建版本': data.utsname.version,
        '发行版': data.utsname.release,
        '系统名称': data.utsname.sysname,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '设备信息', 
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 18,
          )
        ),
        iconTheme: IconThemeData(color: Colors.grey[700]),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              )
            )
          : _buildModernContent(),
    );
  }

  Widget _buildModernContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: _deviceData.entries.map((entry) {
          String sectionKey = entry.key;
          Map<String, dynamic> sectionData = entry.value;
          
          return Container(
            margin: EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 2,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      sectionKey,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  ...sectionData.entries.map<Widget>((dataEntry) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[200]!,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              dataEntry.key,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${dataEntry.value}',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}