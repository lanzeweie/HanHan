import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Config/first_teaching.dart';
import 'Function/AppUpdate.dart';
import 'Function/Function_Id_page.dart';
import 'color.dart';

export 'Function/AppUpdate.dart';

class FunctionList extends StatefulWidget {
  @override
  _FunctionListState createState() => _FunctionListState();
}

class _FunctionListState extends State<FunctionList> {
  bool isDarkMode_force = false; 
  bool isDarkMode = false; 
  List<CardConfig> cardConfigs = [
    CardConfig(
      title: '设备信息',
      description: '查看设备ID版本设备品牌设备型号',
      icon: Icons.phone_android,
      color: Colors.green.shade600,
      page: IDPage(),
    ),
    CardConfig(
      title: 'App更新',
      description: '检查更新、查看版本',
      icon: Icons.system_update_alt,
      color: Colors.blue.shade600,
      page: AppUpdatePage(),
    ),
    CardConfig(
      title: '使用教程',
      description: '15秒快速上手',
      icon: Icons.system_update_alt,
      color: const Color.fromARGB(255, 30, 240, 152),
      page: FirstTeachingPage(),
    ),
  ];

  late List<CardConfig> savedCardConfigs = []; 

  @override
  void initState() {
    super.initState();
    loadCardPositions();
    getisDarkMode_force();
  }

  Future<void> getisDarkMode_force() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode_force = prefs.getBool('暗黑模式') ?? false;
    });
  }

  Future<void> loadCardPositions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? positions = prefs.getStringList('card_positions');
    if (positions != null && positions.length == cardConfigs.length) {
      setState(() {
        savedCardConfigs = positions
            .map((position) => cardConfigs[int.parse(position)])
            .toList();
      });
    } else {
      setState(() {
        savedCardConfigs = List.from(cardConfigs);
      });
    }
  }

  Future<void> saveCardPositions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> positions =
        savedCardConfigs.map((card) => cardConfigs.indexOf(card).toString()).toList();
    await prefs.setStringList('card_positions', positions);
  }

  @override
  Widget build(BuildContext context) {
    // 自动颜色主题
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    isDarkMode = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.colorBackgroundcolor(context),
      appBar: AppBar(
        backgroundColor: AppColors.colorConfigKuangJia(context),
        elevation: 0,
        title: Text(
          '更多功能',
          style: TextStyle(
            color: AppColors.colorConfigText(context),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.colorConfigJianTou(context)),
        systemOverlayStyle: isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      body: ReorderableListView.builder(
        padding: EdgeInsets.all(16),
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final card = savedCardConfigs.removeAt(oldIndex);
            savedCardConfigs.insert(newIndex, card);
            saveCardPositions();
          });
        },
        itemCount: savedCardConfigs.length,
        itemBuilder: (context, index) {
          return buildCard(savedCardConfigs[index], index);
        },
        proxyDecorator: (widget, index, animation) {
          return Transform.scale(
            scale: 1.02,
            child: Opacity(
              opacity: 0.8,
              child: widget,
            ),
          );
        },
      ),
    );
  }

  Widget buildCard(CardConfig config, int index) {
    return Container(
      key: ValueKey(config),
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shadowColor: isDarkMode ? Colors.black26 : Colors.black12,
        color: AppColors.colorConfigSwitchGroupBackground(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => config.page),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: config.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    config.icon,
                    size: 24,
                    color: config.color,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.colorConfigText(context),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        config.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.colorConfigSettilteText(isDarkMode_force, isDarkMode),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.drag_handle,
                  color: AppColors.colorConfigIcon(isDarkMode_force, isDarkMode),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CardConfig {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget page;

  CardConfig({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.page,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CardConfig &&
        runtimeType == other.runtimeType &&
        title == other.title &&
        description == other.description;
  }

  @override
  int get hashCode => title.hashCode ^ description.hashCode;
}

class Page1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('单独设备命令操控'),
      ),
      body: Center(
        child: Text('请返回首页'),
      ),
    );
  }
}

class FirstTeachingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('使用教程'),
      ),
      body: Stack(
        children: [
          // 可根据需要添加背景或说明
          GuideOverlay(
            onLearned: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}


void main() {
  runApp(MaterialApp(
    home: FunctionList(),
  ));
}
