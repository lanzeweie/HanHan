import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Function/Function_GroupZhu.dart';
class FunctionList extends StatefulWidget {
  @override
  _FunctionListState createState() => _FunctionListState();
}

class _FunctionListState extends State<FunctionList> {
  List<CardConfig> cardConfigs = [
    CardConfig(
      title: '单独设备命令操控',
      description: '只能对一台设备进行操控',
      useBackgroundImage: false,
      backgroundColor: Colors.blue,
      page: Page1(),
    ),
    CardConfig(
      title: '实验性功能：设备群命令操控',
      description: '对局域网中任何可用的设备进行群体操控',
      useBackgroundImage: false,
      backgroundColor: Colors.black,
      backgroundImage: AssetImage('assets/background_image.jpg'),
      page: GroupZhu(),
    ),
  ];

  late List<CardConfig> savedCardConfigs = []; 

  @override
  void initState() {
    super.initState();
    loadCardPositions();
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
    return Scaffold(
      appBar: AppBar(
        title: Text('更多功能'),
      ),
      body: Container(
        color: Colors.transparent,
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
      width: double.infinity,
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
