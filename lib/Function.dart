import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      useBackgroundImage: false,
      backgroundColor: Colors.green,
      page: IDPage(),
    ),
    CardConfig(
      title: 'App更新',
      description: '检查更新、查看版本',
      useBackgroundImage: false,
      backgroundColor: Colors.blue,
      page: AppUpdatePage(),
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
      //print("我在更多功能，我的暗黑模式是：$isDarkMode_force");
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
    isDarkMode = brightness == Brightness.dark; // Update isDarkMode variable
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(45), // 设置顶部栏的高度为 80 像素
        child: AppBar(
          title: Text(
            '更多功能',
            style: TextStyle(
              fontSize: 20,
              color: AppColors.colorConfigText(context),
            ),
          ),
          centerTitle: true,
          backgroundColor: AppColors.colorConfigKuangJia(context),
          iconTheme: IconThemeData(
            color: AppColors.colorConfigJianTou(context), // 设置返回箭头的颜色
          ),
        ),
      ),
      body: Container(
        child: ReorderableListView.builder(
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
            return Opacity(
              opacity: animation.value,
              child: widget,
            );
          },
        ),
      ),
    );
  }

  Widget buildCard(CardConfig config, int index) {
    return Container(
      key: ValueKey(config),
      width: null, // 让卡片自适应宽度
      height: 90,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Listener(
        onPointerDown: (_) {}, // 空回调防止点击时触发排序
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => config.page),
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: config.useBackgroundImage
                  ? null
                  : config.backgroundColor ?? Colors.blue,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
              image: config.useBackgroundImage
                  ? DecorationImage(
                      image: config.backgroundImage ??
                          AssetImage('assets/default_background.jpg'), //默认背景
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    config.title,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    config.description,
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
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
  final bool useBackgroundImage;
  final Color? backgroundColor;
  final ImageProvider? backgroundImage;
  final Widget page;

  CardConfig({
    required this.title,
    required this.description,
    required this.useBackgroundImage,
    this.backgroundColor,
    this.backgroundImage,
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


void main() {
  runApp(MaterialApp(
    home: FunctionList(),
  ));
}
