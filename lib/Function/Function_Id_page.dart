import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 导入 shared_preferences 包
import '../Config/device_utils.dart'; // 导入你创建的 device_utils.dart 文件

class IDPage extends StatefulWidget {
  @override
  _IDPageState createState() => _IDPageState();
}

class _IDPageState extends State<IDPage> {
  Map<String, dynamic>? _deviceData;

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
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    Map<String, dynamic> deviceData = {};

    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        deviceData = _readAndroidBuildData(await deviceInfoPlugin.androidInfo);
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        deviceData = _readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
      }
    } catch (e) {
      deviceData = {"Error": "Failed to get platform version: $e"};
    }

    if (!mounted) return;

    setState(() {
      _deviceData = deviceData;
    });

    // 调用独立的函数以获取和保存设备信息
    await updateDeviceData();
  }

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return {
      '设备ID': build.id,
      'Android版本': build.version.release,
      '设备品牌': build.brand,
      '设备型号': build.model,
      '硬件': build.hardware,
      '指纹': build.fingerprint,
    };
  }

  Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return {
      '设备ID': data.identifierForVendor,
      '系统名称': data.systemName,
      '系统版本': data.systemVersion,
      '设备型号': data.utsname.machine,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('设备信息'),
      ),
      body: _deviceData == null
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: _deviceData!.entries.map((entry) {
                return ListTile(
                  title: Text('${entry.key}'),
                  subtitle: Text('${entry.value}'),
                );
              }).toList(),
            ),
    );
  }
}
