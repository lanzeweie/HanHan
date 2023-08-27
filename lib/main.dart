import 'package:flutter/material.dart';
import 'package:molten_navigationbar_flutter/molten_navigationbar_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
//本地包↓ 第三方包↑
import 'zhu.dart';
import 'Function.dart';
import 'Introduction.dart';
import 'Startone.dart';

//路由框架
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
  //第一次使用的介绍 开始

  @override
  void initState() {
    super.initState();
  }

  int _selectedIndex = 0;
  PageController _pageController = PageController();
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MaterialApp(
      title:"涵涵面板",
      theme: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepPurple,
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
        bottomNavigationBar: MoltenBottomNavigationBar(
          selectedIndex: _selectedIndex,
          barHeight: 50,
          domeHeight: 15,
          domeWidth: 72,
          domeCircleSize:45,
          onTabChange: (clickedIndex) {
            setState(() {
              _selectedIndex = clickedIndex;
              _pageController.animateToPage(
                clickedIndex,
                duration: Duration(milliseconds: 350),
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
              title: Text('功能'),
            ),
            MoltenTab(
              icon: Icon(Icons.person),
            ),
          ],
        ),
      ),
    );
  }
}

class KeepAlivePage extends StatefulWidget {
  final Widget child;
  const KeepAlivePage(this.child);
  @override
  _KeepAlivePageState createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class SearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
}

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
