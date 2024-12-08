import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Config/update.dart';
import 'Function.dart';
import 'Introduction.dart';
import 'ProviderHanAll.dart';
import 'Setconfig.dart';
import 'Startone.dart';
import 'color.dart';
import 'zhu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstLaunch = prefs.getBool('first_launch_one_Zhou') ?? true;
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProviderHANHANALL()..loadProviderHANHANAL()),
      ],
      child: isFirstLaunch ? First_launch() : CardApp(),
    ),
  );
}

class CardApp extends StatefulWidget {
  @override
  _CardAppState createState() => _CardAppState();
}

class _CardAppState extends State<CardApp> with AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool isDarkMode = false;

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
        isDarkMode = brightness == Brightness.dark;

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
            body: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  VersionChecker(globalContext: context).checkAndPromptForUpdates();
                });

                return WillPopScope(
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
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildScreen(String routeName) {
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
                          fontSize: 18,
                          color: isDarkMode_force
                              ? AppColors.colorConfigText(isDarkMode_force, isDarkMode)
                              : isDarkMode
                                  ? AppColors.colorConfigText(false, isDarkMode)
                                  : AppColors.colorConfigText(false, isDarkMode),
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
                                    : AppColors.colorConfigJianTou(false, isDarkMode),
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
                                    : AppColors.colorConfigJianTou(false, isDarkMode),
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
                                    : AppColors.colorConfigJianTou(false, isDarkMode),
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
