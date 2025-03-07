import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'color.dart';
import 'main.dart';

void main() => runApp(const First_launch());

class First_launch extends StatelessWidget {
  const First_launch({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
    );

    return MaterialApp(
      title: 'Introduction screen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const OnBoardingPage(),
    );
  }
}

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({Key? key}) : super(key: key);

  @override
  OnBoardingPageState createState() => OnBoardingPageState();
}

class OnBoardingPageState extends State<OnBoardingPage> {
  final introKey = GlobalKey<IntroductionScreenState>();

  void _onIntroEnd(context) async {
    // 设置首次启动为false
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_launch_one_Zhou', false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => CardApp()),
    );
  }

  Widget _buildFullscreenImage() {
    return Image.asset(
      'assets/niao.png',
      fit: BoxFit.cover,
      height: double.infinity,
      width: double.infinity,
      alignment: Alignment.center,
    );
  }

  Widget _buildImage(String assetName, [double width = 350]) {
    return Image.asset('assets/$assetName', width: width);
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 19.0);

    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
      bodyTextStyle: bodyStyle,
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      key: introKey,
      globalBackgroundColor: Colors.white,
      allowImplicitScrolling: true,
      autoScrollDuration: 120000,
      infiniteAutoScroll: false,
      globalHeader: Align(
        alignment: Alignment.topRight,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 16, right: 16),
          ),
        ),
      ),
      globalFooter: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.onboarding, // 文字颜色
            elevation: 0,
          ),
          child: const Text(
            '让我们开始吧！',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: AppColors.onboarding, // 双重确保颜色
            ),
          ),
          onPressed: () => _onIntroEnd(context),
        ),
      ),
      pages: [
        PageViewModel(
          title: "涵涵的超级命令面板",
          body:
              "这个命令面板用于提供局域网内的设备快捷命令控制，注意需要设备上有相应的服务端支持。",
          image: _buildImage('wecome_1.png'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "设计理由",
          body:
              "懒，懒得关机等，用一个服务端配合手机面板，远程遥控岂不是美哉😪😪",
          image: _buildImage('wecome_2.png'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "安全性",
          body:
              "可以在的服务端设备上面打开仅授权设备，避免被任意命令面板控制",
          image: _buildImage('wecome_3.png'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "让我们开始使用吧",
          body:
              "涵涵写这玩意简直是减了寿的，要嗝屁的😭😭",
          image: _buildImage('wecome_4.png'),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context),
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      back: const Icon(
        Icons.arrow_back, 
        color: AppColors.onboarding
      ),
      skip: const Text(
        '跳过', 
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.onboarding
        )
      ),
      next: const Icon(
        Icons.arrow_forward, 
        color: AppColors.onboarding
      ),
      done: const Text(
        '完成', 
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.onboarding
        )
      ),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: kIsWeb
          ? const EdgeInsets.all(12.0)
          : const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: AppColors.onboardingLight, // 非活跃点颜色
        activeColor: AppColors.onboarding, // 活跃点颜色
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
      dotsContainerDecorator: const ShapeDecoration(
        color: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
      ),
    );
  }
}
