import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'color.dart';
import 'package:provider/provider.dart';
import 'ProviderHanAll.dart';

class SwitchConfig {
  final String name;
  final String description;
  final bool defaultValue;
  final String group;
  final IconData icon;

  SwitchConfig({
    required this.name,
    required this.description,
    required this.defaultValue,
    required this.group,
    required this.icon,
  });
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SharedPreferences? _prefs; //读取持久化数据
  bool isDarkMode = false; // 必须的颜色代码
  ProviderHANHANALL? ProviderWDWD;
  bool _isLoading = true; // 数据加载状态，默认为true

  List<SwitchConfig> _switchConfigs = [
    SwitchConfig(
      name: '滑动控制',
      description: '让滑动条卡片滑动后立即执行命令',
      defaultValue: false,
      group: '功能',
      icon: Icons.settings,
    ),
    SwitchConfig(
      name: '暗黑模式',
      description: '强制更改为黑色主题',
      defaultValue: false,
      group: '个性化',
      icon: Icons.security,
    ),
  ];
  Map<String, bool> _switchValues = {};

  @override
  void initState() {
    super.initState();
    _initSharedPreferences().then((_) {
      setState(() {
        _loadSwitchValues();
        _isLoading = false; // 数据加载完成，将_isLoading设置为false
      });
    });
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
    ProviderWDWD = Provider.of<ProviderHANHANALL>(context);
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void _loadSwitchValues() {
    for (SwitchConfig config in _switchConfigs) {
      bool value = _prefs?.getBool(config.name) ?? config.defaultValue;
      _switchValues[config.name] = value;
    }
  }

  void _saveSwitchValue(String name, bool value) {
    _prefs?.setBool(name, value);
    setState(() {
      _switchValues[name] = value;
    });

    // If the switch that was changed is the '暗黑模式' switch, update ProviderHANHANALL
    if (name == '暗黑模式') {
      ProviderWDWD?.isDarkModeForce = value;
    }
    if (name == '滑动控制') {
      ProviderWDWD?.isHuaDong = value;
    }
  }

  bool get isDarkMode_force {
    return ProviderWDWD?.isDarkModeForce ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // 自动颜色主题
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    isDarkMode = brightness == Brightness.dark; // Update isDarkMode variable
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '设置',
          style: TextStyle(
            color: AppColors.colorConfigText(
              isDarkMode_force,
              isDarkMode,
            ),
            fontSize: 20, // 设置字号为20
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true, // 文字居中显示
        backgroundColor: AppColors.colorConfigKuangJia(
          isDarkMode_force,
          isDarkMode,
        ),
        iconTheme: IconThemeData(
          color: AppColors.colorConfigJianTou(
            isDarkMode_force,
            isDarkMode,
          ), // 设置箭头颜色为白色
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(), // 显示加载指示器
            )
          : ListView(
              padding: EdgeInsets.all(8.0),
              children: _buildSwitchGroups(),
            ),
    );
  }

  List<Widget> _buildSwitchGroups() {
    List<Widget> switchGroups = [];

    // Group the switches based on their group name
    Map<String, List<SwitchConfig>> groupedSwitches = {};
    for (SwitchConfig config in _switchConfigs) {
      groupedSwitches.putIfAbsent(config.group, () => []).add(config);
    }

    // Build switch groups
    for (String groupName in groupedSwitches.keys) {
      List<Widget> switches = groupedSwitches[groupName]!.map((config) {
        bool isDisabled = config.name == '暗黑模式' && isDarkMode;
        return ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
          title: Row(
            children: [
              SizedBox(
                width: 22.0, // 增加图标与文字之间的间距
                child: Icon(
                  config.icon,
                  size: 22.0,
                  color: AppColors.colorConfigIcon(
                    isDarkMode_force,
                    isDarkMode,
                  ),
                ),
              ),
              SizedBox(width: 18.0), // 增加图标与文字之间的间距
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.name,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: AppColors.colorConfigSettilte(
                          isDarkMode_force,
                          isDarkMode,
                        ),
                      ),
                    ),
                    SizedBox(height: 3.0), // 增加文字与描述之间的间距
                    Text(
                      config.description,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: AppColors.colorConfigSettilteText(
                          isDarkMode_force,
                          isDarkMode,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: isDisabled
              ? Icon(
                  Icons.check,
                  color: Colors.grey,
                )
              : Switch(
                  value: _switchValues[config.name] ?? config.defaultValue,
                  activeColor: Colors.blue, // 修改开关按钮的激活颜色
                  onChanged: (value) {
                    _saveSwitchValue(config.name, value);
                  },
                ),
        );
      }).toList();

      switchGroups.add(
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  groupName,
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                ),
              ),
              ...switches,
            ],
          ),
        ),
      );
    }

    return switchGroups;
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ProviderHANHANALL(),
      child: MaterialApp(
        home: SettingsPage(),
      ),
    ),
  );
}
