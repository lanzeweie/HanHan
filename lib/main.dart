import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
  await AppColors.initColor(); // 初始化颜色配置
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProviderHANHANALL()..loadProviderHANHANAL()),
      ],
      child: Builder(
        builder: (context) {
          // 在 MaterialApp 中确保 VersionChecker 被调用
          if (isFirstLaunch) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              VersionChecker(globalContext: context).checkAndPromptForUpdates();
            });
          }

          return MaterialApp(
            title: '涵涵面板',
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              Locale('zh'), // 中文
              Locale('en'), // 英文
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              return locale ?? const Locale('zh');
            },
            theme: ThemeData.light(),
            home: isFirstLaunch ? First_launch() : CardApp(),
          );
        },
      ),
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
  void initState() {
    super.initState();
    // Call checkAndPromptForUpdates only once when the widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VersionChecker(globalContext: context).checkAndPromptForUpdates();
    });
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
        isDarkMode = brightness == Brightness.dark;

        WidgetsBinding.instance!.addPostFrameCallback((_) {
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              systemNavigationBarColor: AppColors.colorConfigSystemChrome(context),
            ),
          );
        });

        return MaterialApp(
          title: '涵涵面板',
          theme: providerWDWD.isDarkModeForce
            ? ThemeData.dark().copyWith(
                primaryColor: darkColor_AppBar_zhu,
                sliderTheme: SliderThemeData(
                  activeTrackColor: AppColors.sliderActiveColor(context),
                  inactiveTrackColor: AppColors.sliderInactiveColor(context),
                  thumbColor: AppColors.sliderThumbColor(context),
                  overlayColor: AppColors.sliderThumbColor(context).withOpacity(0.2),
                ),
                textSelectionTheme: TextSelectionThemeData(
                  selectionColor: AppColors.sliderActiveColor(context).withOpacity(0.4),
                  cursorColor: AppColors.colorConfigText(context),
                  selectionHandleColor: AppColors.sliderActiveColor(context),
                ),
              )
            : isDarkMode
              ? ThemeData.dark().copyWith(
                  primaryColor: darkColor_AppBar_zhu,
                  sliderTheme: SliderThemeData(
                    activeTrackColor: AppColors.sliderActiveColor(context),
                    inactiveTrackColor: AppColors.sliderInactiveColor(context),
                    thumbColor: AppColors.sliderThumbColor(context),
                    overlayColor: AppColors.sliderThumbColor(context).withOpacity(0.2),
                  ),
                  textSelectionTheme: TextSelectionThemeData(
                    selectionColor: AppColors.sliderActiveColor(context).withOpacity(0.4),
                    cursorColor: AppColors.colorConfigText(context),
                    selectionHandleColor: AppColors.sliderActiveColor(context),
                  ),
                  dialogTheme: DialogTheme(
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      color: AppColors.dialogTextColor(context),
                    ),
                    contentTextStyle: TextStyle(
                      fontSize: 16,
                      color: AppColors.dialogTextColor(context),
                    ),
                  ),
                )
              : ThemeData.light().copyWith(
                  primaryColor: lightColor_AppBar_zhu,
                  sliderTheme: SliderThemeData(
                    activeTrackColor: AppColors.sliderActiveColor(context),
                    inactiveTrackColor: AppColors.sliderInactiveColor(context),
                    thumbColor: AppColors.sliderThumbColor(context),
                    overlayColor: AppColors.sliderThumbColor(context).withOpacity(0.2),
                  ),
                  textSelectionTheme: TextSelectionThemeData(
                    selectionColor: AppColors.sliderActiveColor(context).withOpacity(0.4),
                    cursorColor: AppColors.colorConfigText(context),
                    selectionHandleColor: AppColors.sliderActiveColor(context),
                  ),
                ),
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
  }

  Widget _buildScreen(String routeName) {
    return Consumer<ProviderHANHANALL>(
      builder: (context, ProviderWDWD, _) {
        bool isDarkMode_force = ProviderWDWD.isDarkModeForce;
        return Builder(
          builder: (BuildContext context) {
            switch (routeName) {
              case '/':
                return Scaffold(
                  appBar: AppBar(
                    title: Text(
                      '涵涵的超级控制面板😀',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.dialogTextColor(context),
                      ),
                    ),
                    backgroundColor: isDarkMode_force
                        ? AppColors.colorConfigKuangJia((context),)
                        : isDarkMode
                            ? AppColors.colorConfigKuangJia((context),)
                            : AppColors.colorConfigKuangJia((context),),
                    elevation: 0,
                    actions: [
                      IconButton(
                        icon: Icon(
                          Icons.list,
                          color: isDarkMode_force
                              ? AppColors.colorConfigJianTou((context),)
                              : isDarkMode
                                  ? AppColors.colorConfigJianTou((context),)
                                  : AppColors.colorConfigJianTou((context),),
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
                              ? AppColors.colorConfigJianTou((context),)
                              : isDarkMode
                                  ? AppColors.colorConfigJianTou((context),)
                                  : AppColors.colorConfigJianTou((context),),
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
                              ? AppColors.colorConfigJianTou((context),)
                              : isDarkMode
                                  ? AppColors.colorConfigJianTou((context),)
                                  : AppColors.colorConfigJianTou((context),),
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
