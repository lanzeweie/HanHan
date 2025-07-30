import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:introduction_screen/introduction_screen.dart';

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
    // 不要在这里设置 first_launch_one_Zhou = false
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
              color: Color.fromARGB(255, 239, 118, 118), // 双重确保颜色
            ),
          ),
          onPressed: () => _onIntroEnd(context),
        ),
      ),
      pages: [
        PageViewModel(
          title: "涵涵的超级命令面板",
          body:
              "就是为了快捷快捷快捷快捷快捷快捷快捷快捷快捷！！！！！！",
          image: _buildImage('xiaolian.png'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "我能做到的🤔",
          body:
              "支持远程访问多个设备，动动手指完成快捷操作😪😪",
          image: _buildImage('boqijiang.png'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "🛡️非常安全🛡️",
          body:
              "只有通过验证的设备才能访问目标，不怕坏人来敲门了😀😀",
          image: _buildImage('360.png'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "让我们开始使用吧",
          body:
              "🎉🎉欢迎你使用涵涵的软件🎉🎉",
          image: _buildImage('xin.png'),
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