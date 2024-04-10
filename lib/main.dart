import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'zhu.dart';
import 'Function.dart';
import 'Introduction.dart';
import 'Startone.dart';
import 'package:flutter/services.dart';
import 'color.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstLaunch = prefs.getBool('first_launch_one_Zhou') ?? true;
  if (isFirstLaunch) {
    await prefs.setBool('first_launch_one_Zhou', false); // Set the value to false
    runApp(First_launch());
  } else {
    runApp(CardApp());
  }
}

class CardApp extends StatefulWidget {
  @override
  _CardAppState createState() => _CardAppState();
}

class _CardAppState extends State<CardApp> with AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool isDarkMode = false; // 必须的颜色代码

  @override
  bool get wantKeepAlive => true;
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 自动颜色主题
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    isDarkMode = brightness == Brightness.dark; // Update isDarkMode variable
    return MaterialApp(
      title: '涵涵面板',
      theme: isDarkMode
          ? ThemeData.dark().copyWith(primaryColor: darkColor_AppBar_zhu)
          : ThemeData.light().copyWith(primaryColor: lightColor_AppBar_zhu),
      home: Scaffold(
        body: WillPopScope(
          onWillPop: () async {
            if (_navigatorKey.currentState!.canPop()) {
              _navigatorKey.currentState!.pop();
              return false;
            } else {
              // 如果当前页面无法返回，则调用系统的返回按钮事件处理方法
              await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
              return true;
            }
          },
          child: Navigator(
            key: _navigatorKey,
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildScreen(settings.name ?? ''), // Call _buildScreen method here
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildScreen(String routeName) {
    switch (routeName) {
      case '/':
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                '涵涵的超级控制面板😀',
                style: TextStyle(
                  color: AppColors.colorConfigText(isDarkMode),
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.list,
                    color: AppColors.colorConfigText(isDarkMode),
                  ),
                  onPressed: () {
                    Navigator.push(
                      _navigatorKey.currentState!.context,
                      MaterialPageRoute(builder: (context) => FunctionList()),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.info,
                    color: AppColors.colorConfigText(isDarkMode),
                  ),
                  onPressed: () {
                    Navigator.push(
                      _navigatorKey.currentState!.context,
                      MaterialPageRoute(builder: (context) => IntroductionPage()),
                    );
                  },
                ),
              ],
            ),
            body: ZhuPage(),
          ),
        );
      default:
        return Container();
    }
  }
}
