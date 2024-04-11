import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'color.dart';
import 'package:provider/provider.dart';

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

class DarkModeProvider with ChangeNotifier {
  bool _isDarkModeForce = false;

  bool get isDarkModeForce => _isDarkModeForce;

  set isDarkModeForce(bool value) {
    _isDarkModeForce = value;
    notifyListeners();
  }

  Future<void> loadDarkModeForce() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkModeForce = prefs.getBool('暗黑模式') ?? false;
    notifyListeners();
  }
}


class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
    SharedPreferences? _prefs; //读取持久化数据
    //bool isDarkMode_force = false;
    bool isDarkMode = false; // 必须的颜色代码
    DarkModeProvider? darkModeProvider;
    
    List<SwitchConfig> _switchConfigs = [
        SwitchConfig(
            name: '开关1',
            description: '这是开关1的介绍',
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
            });
        });
    }

    void didChangeDependencies() {
        super.didChangeDependencies();
        darkModeProvider = Provider.of<DarkModeProvider>(context);
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

    // If the switch that was changed is the '暗黑模式' switch, update DarkModeProvider
    if (name == '暗黑模式') {
        darkModeProvider?.isDarkModeForce = value;
    }
    }

    bool get isDarkMode_force {
        return darkModeProvider?.isDarkModeForce ?? false;
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
                        color: AppColors.colorConfigText(isDarkMode_force,isDarkMode),
                        fontSize: 20, // 设置字号为20
                        fontWeight: FontWeight.bold,
                    ),
                ),
                centerTitle: true, // 文字居中显示
                backgroundColor: AppColors.colorConfigKuangJia(isDarkMode_force,isDarkMode),
                iconTheme: IconThemeData(
                  color: AppColors.colorConfigJianTou(isDarkMode_force,isDarkMode), // 设置箭头颜色为白色
                ),
            ),
            body: ListView(
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
                return ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                    title: Row(
                        children: [
                            SizedBox(
                                width: 22.0, // 增加图标与文字之间的间距
                                child: Icon(
                                    config.icon,
                                    size: 22.0,
                                    color: AppColors.colorConfigIcon(isDarkMode_force,isDarkMode),
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
                                                color: AppColors.colorConfigSettilte(isDarkMode_force,isDarkMode),
                                            ),
                                        ),
                                        SizedBox(height: 3.0), // 增加文字与描述之间的间距
                                        Text(
                                            config.description,
                                            style: TextStyle(
                                                fontSize: 12.0,
                                                color: AppColors.colorConfigSettilteText(isDarkMode_force,isDarkMode),
                                            ),
                                        ),
                                    ],
                                ),
                            ),
                        ],
                    ),
                    trailing: Switch(
                        value: _switchValues[config.name] ?? config.defaultValue,
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
    runApp(MaterialApp(
        home: SettingsPage(),
    ));
}
