import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'color.dart';
//介绍页面

void main() {
  runApp(IntroductionApp());
}

class IntroductionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: IntroductionPage(),
    );
  }
}

class IntroductionPage extends StatefulWidget {
  @override
  _IntroductionPageState createState() => _IntroductionPageState();
}

class _IntroductionPageState extends State<IntroductionPage> {
  bool isDarkMode = false; 
  bool isDarkMode_force = false;
  
  @override
  void initState() {
    super.initState();
    getisDarkMode_force();
  }
  
  Future<void> getisDarkMode_force() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode_force = prefs.getBool('暗黑模式') ?? false;
      //print("我在个人介绍页面，我的暗黑模式是：$isDarkMode_force");
    });
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
            '涵涵在这里',
            style: TextStyle(
              fontSize: 20, // 设置字号为20
              color: AppColors.colorConfigText(context),
            ),
          ),
          centerTitle: true, // 文字居中显示
          backgroundColor: AppColors.colorConfigKuangJia(context),
          iconTheme: IconThemeData(
            color: AppColors.colorConfigJianTou(context), // 设置返回箭头的颜色
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileHeader(), // 添加头像框
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  AnimatedCard(
                    title: '涵涵的命令面板',
                    description: '这是信息块 1 的详细描述。\n这是第二行。',
                    color: Colors.blue,
                    isExpandable: false,
                    isExpandedByDefault: false, // 默认展开
                    cardIcon: Icons.star, // 添加卡片图标
                  ),
                  AnimatedCard(
                    title: '设计原因',
                    description: '在移动端的快捷面板可以方便一些命令的实施\n简易快捷的与PC服务端进行对接\n快速进行命令交互',
                    color: Colors.green,
                    isExpandable: false, // 禁止收回
                    isExpandedByDefault: true, // 默认展开
                    cardIcon: Icons.favorite, // 添加卡片图标
                  ),
                  AnimatedCard(
                    title: '开发者信息',
                    description: '邮箱：lanzeweie@foxmail.com\nQ Q：449003810',
                    color: Colors.orange,
                    isExpandable: true,
                    isExpandedByDefault: true, // 默认展开
                    cardIcon: Icons.wechat, // 添加卡片图标
                  ),
                  AnimatedCard(
                    title: '开源 [2023/8/26]',
                    description: '语言：Dart\n框架：Flutter\n开源：Github',
                    color: Colors.orange,
                    isExpandable: true,
                    isExpandedByDefault: false, // 默认展开
                    url: 'https://github.com/lanzeweie/HanHan',
                    cardIcon: Icons.link, // 添加卡片图标
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40.0,
            backgroundImage: NetworkImage('https://q1.qlogo.cn/g?b=qq&nk=449003810&s=640'), // 替换成您的图片链接
          ),
        ],
      ),
    );
  }
}

class AnimatedCard extends StatefulWidget {
  final String title;
  final String description;
  final Color color;
  final bool isExpandable;
  final bool isExpandedByDefault; // 新增属性
  final String? url;
  final IconData cardIcon;

  AnimatedCard({
    required this.title,
    required this.description,
    required this.color,
    required this.isExpandable,
    this.isExpandedByDefault = false, // 默认值为false
    this.url,
    required this.cardIcon,
  });

  @override
  _AnimatedCardState createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpandedByDefault;
  }

  void _toggleExpansion() {
    if (widget.isExpandable) {
      setState(() {
        _isExpanded = !_isExpanded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: _toggleExpansion,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
            leading: Icon(widget.cardIcon, color: Colors.white),
            title: Text(widget.title, style: TextStyle(color: Colors.white)),
            trailing: widget.isExpandable
                ? _isExpanded
                    ? Icon(Icons.expand_less, color: Colors.white)
                    : Icon(Icons.expand_more, color: Colors.white)
                : null,
          ),
          if (_isExpanded)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // 添加垂直间距
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.description,
                    style: TextStyle(color: Colors.white),
                  ),
                  if (widget.url != null)
                    GestureDetector(
                      onTap: () => launch(widget.url!),
                      child: Row(
                        children: [
                          Icon(Icons.link, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '点击查看链接',
                            style: TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
