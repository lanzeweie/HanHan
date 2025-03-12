import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ProviderHanAll.dart';
import 'color.dart';

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
  int _historyLimit = 5; // 历史记录上限，默认为5条
  final TextEditingController _historyLimitController = TextEditingController();

  List<SwitchConfig> _switchConfigs = [
    SwitchConfig(
      name: '滑动控制',
      description: '让滑动条卡片滑动后立即执行命令',
      defaultValue: false,
      group: '功能',
      icon: Icons.keyboard_double_arrow_right,
    ),
    SwitchConfig(
      name: '暗黑模式',
      description: '强制更改为黑色主题',
      defaultValue: false,
      group: '个性化',
      icon: Icons.wb_sunny,
    ),
    SwitchConfig(
      name: '跟随系统',
      description: '主题颜色自动跟随系统设置',
      defaultValue: true,
      group: '个性化',
      icon: Icons.sync,
    ),
    SwitchConfig(
      name: '边框强制色',
      description: '卡片边框使用主题色而非默认灰色',
      defaultValue: false,
      group: '个性化',
      icon: Icons.border_style,
    ),
    SwitchConfig(
      name: '框架强制色',
      description: '框架使用主题色而非默认黑白',
      defaultValue: false,
      group: '个性化',
      icon: Icons.border_all,
    ),
  ];

  Map<String, bool> _switchValues = {};

  @override
  void initState() {
    _initSharedPreferences().then((_) {
      setState(() {
        _loadSwitchValues();
        _loadHistoryLimit();
        _historyLimitController.text = _historyLimit.toString();
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
    
    if (_switchValues['暗黑模式'] == true && _switchValues['跟随系统'] == true) {
      // 如果两个设置都为true，优先使用暗黑模式
      _switchValues['跟随系统'] = false;
    }
    ProviderWDWD?.isDarkModeForce = _switchValues['暗黑模式'] ?? false;
    ProviderWDWD?.isFollowSystem = _switchValues['跟随系统'] ?? true;
    ProviderWDWD?.notifyListeners();
  }

  void _loadHistoryLimit() {
    // 使用统一的键名 'historyLimit'
    _historyLimit = _prefs?.getInt('historyLimit') ?? 5;
    // 更新 Provider 中的历史记录上限
    ProviderWDWD?.historyLimit = _historyLimit;
    ProviderWDWD?.notifyListeners();
  }

  void _saveHistoryLimit(int limit) async {
    // 确保数值有效
    if (limit <= 0) limit = 1;
    // 使用统一的键名保存
    await _prefs?.setInt('historyLimit', limit);
    setState(() {
      _historyLimit = limit;
      _historyLimitController.text = limit.toString();
    });
    // 更新 Provider 中的历史记录上限
    ProviderWDWD?.historyLimit = limit;
    // 通知监听者设置已更改，不再设置不存在的属性
    ProviderWDWD?.notifyListeners();
  }

  void _saveSwitchValue(String name, bool value) {
    _prefs?.setBool(name, value);
    
    setState(() {
      _switchValues[name] = value;
      
      // 处理暗黑模式与跟随系统之间的互斥关系
      if (name == '暗黑模式' && value == true) {
        _switchValues['跟随系统'] = false;
        _prefs?.setBool('跟随系统', false);
      } else if (name == '跟随系统' && value == true) {
        _switchValues['暗黑模式'] = false;
        _prefs?.setBool('暗黑模式', false);
      }
    });
    // 更新Provider状态
    if (name == '滑动控制') {
      ProviderWDWD?.isHuaDong = value;
    } else if (name == '暗黑模式') {
      ProviderWDWD?.isDarkModeForce = value;
    } else if (name == '跟随系统') {
      ProviderWDWD?.isFollowSystem = value;
    } else if (name == '边框强制色') {
      ProviderWDWD?.isForceBorderColor = value;
    } else if (name == '框架强制色') {
      ProviderWDWD?.isForceFrameColor = value;
    }
    // 确保界面刷新
    ProviderWDWD?.notifyListeners();
    
    // 使用Future.microtask确保状态已经更新后再强制刷新
    Future.microtask(() {
      setState(() {});
    });
  }

  bool get isDarkMode_force {
    return ProviderWDWD?.isDarkModeForce ?? false;
  }

  bool get isFollowSystem {
    return ProviderWDWD?.isFollowSystem ?? true;
  }

  bool get isActuallyDarkMode {
    // 修改这里：直接使用Provider的isDarkMode
    return ProviderWDWD?.isDarkMode ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // 自动颜色主题
    final brightness = MediaQuery.of(context).platformBrightness;
    isDarkMode = brightness == Brightness.dark;

    // 订阅Provider变化，确保主题更改时UI会更新
    final provider = Provider.of<ProviderHANHANALL>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '设置',
          style: TextStyle(
            fontSize: 20, // 设置字号为20
            color: AppColors.colorConfigText(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true, // 文字居中显示
        backgroundColor: AppColors.colorConfigKuangJia(context),
        iconTheme: IconThemeData(
          color: AppColors.colorConfigJianTou(context), // 设置箭头颜色为白色
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

  Widget _buildColorPickerItem({
    required String title,
    required Color? currentColor,
    required ValueChanged<Color> onColorChanged,
  }) {
    return ListTile(
      title: Text(title),
      trailing: GestureDetector(
        onTap: () async {
          Color _color = currentColor ?? Colors.blue; // 临时存储选择颜色
          final color = await showDialog<Color>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('选择颜色'),
              content: SingleChildScrollView(
                child: BlockPicker(
                  pickerColor: _color,
                  onColorChanged: (value) => _color = value,
                  availableColors: const [
                    Colors.red,
                    Colors.pink,
                    Colors.purple,
                    Colors.deepPurple,
                    Colors.indigo,
                    Colors.blue,
                    Colors.lightBlue,
                    Colors.cyan,
                    Colors.teal,
                    Colors.green,
                    Colors.lightGreen,
                    Colors.lime,
                    Colors.yellow,
                    Colors.amber,
                    Colors.orange,
                    Colors.deepOrange,
                    Colors.brown,
                    Colors.grey,
                    Colors.blueGrey,
                    Colors.black,
                    Colors.white,
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, _color),
                  child: Text('确定'),
                ),
              ],
            ),
          );
          if (color != null) {
            onColorChanged(color);
          }
        },
        child: Consumer<ProviderHANHANALL>(
          builder: (context, provider, _) => Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: provider.subElementColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildColorSettings() {
    final provider = Provider.of<ProviderHANHANALL>(context);
    return [
      _buildColorPickerItem(
        title: '子元素颜色',
        currentColor: provider.subElementColor,
        onColorChanged: (color) {
          provider.updateSubElementColor(color);
        },
      ),
    ];
  }

  List<Widget> _buildSwitchGroups() {
    // Group the switches based on their group name
    Map<String, List<SwitchConfig>> groupedSwitches = {};
    for (SwitchConfig config in _switchConfigs) {
      groupedSwitches.putIfAbsent(config.group, () => []).add(config);
    }

    // Build switch groups
    List<Widget> switchGroups = [];
    for (String groupName in groupedSwitches.keys) {
      List<Widget> switches = [];
      
      for (SwitchConfig config in groupedSwitches[groupName]!) {
        // 处理特殊显示逻辑
        bool isDisabled = false;
        // 如果是系统深色模式，且跟随系统开启，则显示暗黑模式为不可交互的已勾选状态
        if (config.name == '暗黑模式' && isDarkMode && isFollowSystem) {
          isDisabled = true;
        }

        switches.add(
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
            title: Row(
              children: [
                SizedBox(
                  width: 22.0, // 增加图标与文字之间的间距
                  child: Icon(
                    config.icon,
                    size: 18.0,
                    color: AppColors.colorConfigIcon(isDarkMode_force, isDarkMode),
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
                          fontWeight: FontWeight.bold,
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
                    activeColor: AppColors.commandApiElement(context, hueShift: 1, saturationBoost: 1), // 修改开关按钮的激活颜色
                    onChanged: (value) {
                      _saveSwitchValue(config.name, value);
                    },
                  ),
          ),
        );
      }

      switchGroups.add(
        Card(
          // 添加背景颜色和圆角
          color: AppColors.colorConfigSwitchGroupBackground(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 0.0, // 去除阴影效果
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
              if (groupName == '个性化') ..._buildColorSettings(),
              if (groupName == '功能') _buildHistoryLimitSetting(),
            ],
          ),
        ),
      );
    }

    return switchGroups;
  }

  Widget _buildHistoryLimitSetting() {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
      title: Row(
        children: [
          SizedBox(
            width: 22.0,
            child: Icon(
              Icons.history,
              size: 22.0,
              color: AppColors.colorConfigIcon(isDarkMode_force, isDarkMode),
            ),
          ),
          SizedBox(width: 18.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '卡片运行历史记录',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: AppColors.colorConfigSettilte(
                      isDarkMode_force,
                      isDarkMode,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3.0),
                Text(
                  '每张卡片最大保存的运行历史记录',
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
      trailing: Container(
        width: 100,
        child: TextField(
          controller: _historyLimitController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            int? limit = int.tryParse(value);
            if (limit != null) {
              _saveHistoryLimit(limit);
            } else {
              // 如果输入的不是有效数字，恢复原值
              _historyLimitController.text = _historyLimit.toString();
            }
          },
        ),
      ),
    );
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