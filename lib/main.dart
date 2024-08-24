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
import 'ProviderHanAll.dart';
import 'package:flutter/services.dart';

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
        create: (context) => ProviderHANHANALL()..loadProviderHANHANAL(),
        child: CardApp(),
      ),
    );
  }
}

class CardApp extends StatefulWidget {
  @override
  _CardAppState createState() => _CardAppState();

	@@ -26,158 +25,107 @@ class CardApp extends StatefulWidget {

}

class _CardAppState extends State<CardApp> with AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool isDarkMode = false; // 必须的颜色代码

  PageController _pageController = PageController();
  @override
  bool get wantKeepAlive => true;
  MaterialColor customColor = MaterialColor(
    0xFF40356F, // 颜色代码
    <int, Color>{
      50: Color(0xFFEAEAF2),
      100: Color(0xFFB3B3D9),
      200: Color(0xFF7C7CBF),
      300: Color(0xFF4545A6),
      400: Color(0xFF2E2E91),
      500: Color(0xFF17177C),
      600: Color(0xFF12126F),
      700: Color(0xFF0D0D61),
      800: Color(0xFF080854),
      900: Color(0xFF030347),
    },
  );
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MaterialApp(
      title:"涵涵面板",
      theme: Theme.of(context).copyWith(
        //scaffoldBackgroundColor: Colors.transparent,  //所有页面的背景颜色
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: customColor, // 设置主题颜色为自定义颜色
        ),
      ),
      home: Scaffold(
        body: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          itemCount: 3,
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return KeepAlivePage(ZhuPage());
              case 1:
                return KeepAlivePage(FunctionList());
              case 2:
                return KeepAlivePage(IntroductionPage());
              default:
                return Container();
            }
          },
                ),
        bottomNavigationBar: Container(
          color: Colors.transparent,
          child: MoltenBottomNavigationBar(
            selectedIndex: _selectedIndex,
            barHeight: 50,
            domeHeight: 15,
            domeWidth: 72,
            domeCircleSize: 45,
            onTabChange: (clickedIndex) {
              setState(() {
                _selectedIndex = clickedIndex;
                _pageController.animateToPage(
                  clickedIndex,
                  duration: Duration(milliseconds: 128),
                  curve: Curves.linear,
              );
              });
            },
            tabs: [
              MoltenTab(
                icon: Icon(Icons.phonelink_ring),
              ),
              MoltenTab(
                icon: Icon(Icons.credit_card),
              ),
              MoltenTab(
                icon: Icon(Icons.person),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


  @override
  bool get wantKeepAlive => true;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Consumer<ProviderHANHANALL>(
      builder: (context, providerWDWD, _) {
        final Brightness brightness = MediaQuery.of(context).platformBrightness;
        isDarkMode = brightness == Brightness.dark; // Update isDarkMode variable

        WidgetsBinding.instance!.addPostFrameCallback((_) {
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              systemNavigationBarColor: providerWDWD.isDarkModeForce
                  ? AppColors.colorConfigSystemChrome(providerWDWD.isDarkModeForce, isDarkMode)
                  : isDarkMode
                      ? AppColors.colorConfigSystemChrome(false, isDarkMode)
                      : AppColors.colorConfigSystemChrome(false, isDarkMode),
            ),
          );
        });

        return MaterialApp(
          title: '涵涵面板',
          theme: providerWDWD.isDarkModeForce
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
      },
    );

    return Center(
      child: Text(
        '搜索页面',
                style: TextStyle(
          fontSize: 20,
                ),
              ),
                    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '主页',
        style: TextStyle(
          fontSize: 20,
                ),
                  ),
                    );

  }

  Widget _buildScreen(String routeName) {
    //print("我在头部，我的暗黑模式是 ${Provider.of<ProviderHANHANALL>(context).isDarkModeForce}");
    return Consumer<ProviderHANHANALL>(
      builder: (context, ProviderWDWD, _) {
        bool isDarkMode_force = ProviderWDWD.isDarkModeForce;
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
                          color: isDarkMode_force
                              ? AppColors.colorConfigText(isDarkMode_force, isDarkMode)
                              : isDarkMode
                                  ? AppColors.colorConfigText(false, isDarkMode)
                                  : AppColors.colorConfigText(false, isDarkMode)
                        ),
                      ),
                      backgroundColor: isDarkMode_force
                              ? AppColors.colorConfigKuangJia(isDarkMode_force, isDarkMode)
                              : isDarkMode
                                  ? AppColors.colorConfigKuangJia(false, isDarkMode)
                                  : AppColors.colorConfigKuangJia(false, isDarkMode),
                      elevation: 0,
                      actions: [
                        IconButton(
                          icon: Icon(
                            Icons.list,
                            color: isDarkMode_force
                              ? AppColors.colorConfigJianTou(isDarkMode_force, isDarkMode)
                              : isDarkMode
                                  ? AppColors.colorConfigJianTou(false, isDarkMode)
                                  : AppColors.colorConfigJianTou(false, isDarkMode)
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
                            color: isDarkMode_force
                              ? AppColors.colorConfigJianTou(isDarkMode_force, isDarkMode)
                              : isDarkMode
                                  ? AppColors.colorConfigJianTou(false, isDarkMode)
                                  : AppColors.colorConfigJianTou(false, isDarkMode)
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
                            color: isDarkMode_force
                              ? AppColors.colorConfigJianTou(isDarkMode_force, isDarkMode)
                              : isDarkMode
                                  ? AppColors.colorConfigJianTou(false, isDarkMode)
                                  : AppColors.colorConfigJianTou(false, isDarkMode)
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

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '个人资料页面',
        style: TextStyle(
          fontSize: 20,
            ),
          ),
        );

  }
}