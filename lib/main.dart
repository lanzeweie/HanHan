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
  await AppColors.initColor(); // 初始化颜色配置
  
  final provider = ProviderHANHANALL();
  await provider.loadProviderHANHANAL();
  
  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: MyAppRoot(isFirstLaunch: isFirstLaunch),
    ),
  );
}

class MyAppRoot extends StatelessWidget {
  final bool isFirstLaunch;
  
  const MyAppRoot({Key? key, required this.isFirstLaunch}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderHANHANALL>(
      builder: (context, provider, _) {
        // 使用Provider的isDarkMode getter，它会处理所有主题逻辑
        final isDark = provider.isDarkMode;
                       
        return MaterialApp(
          title: 'Han Han Interface',
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            // 配置浅色主题
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            // 配置深色主题
          ),
          home: isFirstLaunch ? First_launch() : CardApp(),
        );
      },
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
    super.build(context); // 必须调用super.build
    
    return Consumer<ProviderHANHANALL>(
      builder: (context, providerWDWD, _) {
        // 直接使用Provider的isDarkMode，确保统一逻辑
        isDarkMode = providerWDWD.isDarkMode;

        WidgetsBinding.instance!.addPostFrameCallback((_) {
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              systemNavigationBarColor: AppColors.colorConfigSystemChrome(context),
              // 强制设置状态栏颜色
              statusBarColor: Colors.transparent,
              // 根据当前主题设置状态栏图标颜色
              statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
              statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
            ),
          );
        });

        return MaterialApp(
          title: '涵涵面板',
          theme: ThemeData(
            // 亮色主题设置
            brightness: Brightness.light,
            // 明确设置背景色 - 使用colorScheme
            scaffoldBackgroundColor: AppColors.colorBackgroundcolor(context),
            colorScheme: ColorScheme.light(
              background: AppColors.colorBackgroundcolor(context),
            ),
            canvasColor: AppColors.colorBackgroundcolor(context),
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
          darkTheme: ThemeData(
            // 暗色主题设置
            brightness: Brightness.dark,
            // 明确设置背景色 - 使用colorScheme
            scaffoldBackgroundColor: AppColors.colorBackgroundcolor(context),
            colorScheme: ColorScheme.dark(
              background: AppColors.colorBackgroundcolor(context),
            ),
            canvasColor: AppColors.colorBackgroundcolor(context),
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
          ),
          // 添加以下两行，防止在高对比度设置下跟随系统
          highContrastTheme: null,
          highContrastDarkTheme: null,
          // 关键：使用isDarkMode，它会处理所有主题逻辑
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          // 添加这一行来禁止应用自动适应平台的亮暗设置
          builder: (context, child) {
            // 强制覆盖 MediaQuery 的平台亮度设置
            final mediaQuery = MediaQuery.of(context);
            final newMediaQuery = mediaQuery.copyWith(
              platformBrightness: isDarkMode ? Brightness.dark : Brightness.light,
            );
            return MediaQuery(
              data: newMediaQuery,
              child: child!,
            );
          },
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
