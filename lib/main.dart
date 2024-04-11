import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'zhu.dart';
import 'Function.dart';
import 'Introduction.dart';
import 'Startone.dart';
import 'package:flutter/services.dart';
import 'color.dart';
import 'Setconfig.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstLaunch = prefs.getBool('first_launch_one_Zhou') ?? true;
  if (isFirstLaunch) {
    await prefs.setBool('first_launch_one_Zhou', false); // Set the value to false
    runApp(First_launch());
  } else {
    runApp(
      ChangeNotifierProvider(
        create: (context) => DarkModeProvider()..loadDarkModeForce(),
        child: CardApp(),
      ),
    );
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
  bool isDarkMode_force = false;

  @override
  bool get wantKeepAlive => true;

  _CardAppState() {
    getisDarkMode_force();
  }

  Future<void> getisDarkMode_force() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode_force = prefs.getBool('暗黑模式') ?? false;
      print("我在主页，我的暗黑模式是：$isDarkMode_force");
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    isDarkMode = brightness == Brightness.dark; // Update isDarkMode variable
    DarkModeProvider darkModeProvider = Provider.of<DarkModeProvider>(context);

    return MaterialApp(
      title: '涵涵面板',
      theme: darkModeProvider.isDarkModeForce
          ? ThemeData.dark().copyWith(primaryColor: darkColor_AppBar_zhu)
          : isDarkMode
              ? ThemeData.dark().copyWith(primaryColor: darkColor_AppBar_zhu)
              : ThemeData.light().copyWith(primaryColor: lightColor_AppBar_zhu),
      home: Scaffold(
        body: WillPopScope(
          onWillPop: () async {
            if (_navigatorKey.currentState!.canPop()) {
              _navigatorKey.currentState!.pop();
              return false;
            } else {
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
                  child: _buildScreen(settings.name ?? ''),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildScreen(String routeName) {
    print("我在头部，我的暗黑模式是${Provider.of<DarkModeProvider>(context).isDarkModeForce}");
    return Consumer<DarkModeProvider>(
      builder: (context, darkModeProvider, _) {
        bool isDarkMode_force = darkModeProvider.isDarkModeForce;
        return Builder(
          builder: (BuildContext context) {
            switch (routeName) {
              case '/':
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Scaffold(
                    appBar: AppBar(
                      title: Text(
                        '涵涵的超级控制面板😀',
                        style: TextStyle(
                          color: isDarkMode_force ? Colors.white : Colors.black,
                        ),
                      ),
                      backgroundColor: isDarkMode_force ? Colors.black : Colors.white,
                      elevation: 0,
                      actions: [
                        IconButton(
                          icon: Icon(
                            Icons.list,
                            color: isDarkMode_force ? Colors.white : Colors.black,
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
                            Icons.settings,
                            color: isDarkMode_force ? Colors.white : Colors.black,
                          ),
                          onPressed: () {
                            Navigator.push(
                              _navigatorKey.currentState!.context,
                              MaterialPageRoute(builder: (context) => SettingsPage()),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.info,
                            color: isDarkMode_force ? Colors.white : Colors.black,
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
                    body: _selectedIndex == 0 ? ZhuPage() : Container(),
                  ),
                );
              default:
                return Container();
            }
          },
        );
      },
    );
  }
}