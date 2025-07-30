import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  // 添加状态管理各个卡片的展开状态
  bool _isCard1Expanded = false;
  bool _isCard2Expanded = true;
  bool _isCard3Expanded = true;
  bool _isCard4Expanded = false;
  
  @override
  void initState() {
    super.initState();
    getisDarkMode_force();
  }
  
  Future<void> getisDarkMode_force() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode_force = prefs.getBool('暗黑模式') ?? false;
    });
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
          '涵涵在这里',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.colorConfigText(context),
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: AppColors.colorConfigJianTou(context),
        ),
        systemOverlayStyle: isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  _buildInfoCard(
                    title: '涵涵的命令面板',
                    description: '这是信息块 1 的详细描述。\n这是第二行。',
                    icon: Icons.dashboard,
                    color: Colors.blue,
                    isExpandable: false,
                    isExpanded: _isCard1Expanded,
                    onToggle: (expanded) => setState(() => _isCard1Expanded = expanded),
                  ),
                  SizedBox(height: 8),
                  _buildInfoCard(
                    title: '设计原因',
                    description: '在移动端的快捷面板可以方便一些命令的实施\n简易快捷的与PC服务端进行对接\n快速进行命令交互',
                    icon: Icons.lightbulb,
                    color: Colors.green,
                    isExpandable: false,
                    isExpanded: _isCard2Expanded,
                    onToggle: (expanded) => setState(() => _isCard2Expanded = expanded),
                  ),
                  SizedBox(height: 8),
                  _buildInfoCard(
                    title: '开发者信息',
                    description: '邮箱：lanzeweie@foxmail.com\nQ Q：449003810',
                    icon: Icons.person,
                    color: Colors.orange,
                    isExpandable: true,
                    isExpanded: _isCard3Expanded,
                    onToggle: (expanded) => setState(() => _isCard3Expanded = expanded),
                  ),
                  SizedBox(height: 8),
                  _buildInfoCard(
                    title: '开源 [2023/8/26]',
                    description: '语言：Dart\n框架：Flutter\n开源：Github',
                    icon: Icons.code,
                    color: Colors.purple,
                    isExpandable: true,
                    isExpanded: _isCard4Expanded,
                    onToggle: (expanded) => setState(() => _isCard4Expanded = expanded),
                    url: 'https://github.com/lanzeweie/HanHan',
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        shadowColor: isDarkMode ? Colors.black26 : Colors.black12,
        color: AppColors.colorConfigSwitchGroupBackground(context), // 卡片背景色
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.commandApiElement(context),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage('https://q1.qlogo.cn/g?b=qq&nk=449003810&s=640'),
                  backgroundColor: Colors.grey[300],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '涵涵',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.colorConfigText(context),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Flutter & Python',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.colorConfigSettilteText(isDarkMode_force, isDarkMode),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isExpandable,
    required bool isExpanded,
    required Function(bool) onToggle,
    String? url,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Material(
        elevation: 2,
        shadowColor: isDarkMode ? Colors.black26 : Colors.black12,
        color: AppColors.colorConfigSwitchGroupBackground(context), // 卡片背景色
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isExpandable ? () => onToggle(!isExpanded) : null,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.colorConfigKuangJia(context), // 顶部色块更突出
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                    bottomLeft: isExpanded ? Radius.zero : Radius.circular(12),
                    bottomRight: isExpanded ? Radius.zero : Radius.circular(12),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.colorConfigText(context),
                          ),
                        ),
                      ),
                      if (isExpandable)
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.colorConfigIcon(isDarkMode_force, isDarkMode).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: AppColors.colorConfigIcon(isDarkMode_force, isDarkMode),
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: Container(),
                secondChild: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: BoxDecoration(
                    color: AppColors.colorConfigSwitchGroupBackground(context), // 内容区背景色
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.colorConfigSettilteText(isDarkMode_force, isDarkMode),
                          height: 1.6,
                        ),
                      ),
                      if (url != null) ...[
                        SizedBox(height: 16),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => launch(url),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.open_in_new,
                                    color: color,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '访问Github仓库',
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: color,
                                    size: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                crossFadeState: isExpanded 
                  ? CrossFadeState.showSecond 
                  : CrossFadeState.showFirst,
                duration: Duration(milliseconds: 250),
                sizeCurve: Curves.easeInOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
