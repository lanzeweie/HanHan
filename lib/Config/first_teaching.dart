import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuideOverlay extends StatefulWidget {
  final VoidCallback onLearned;
  const GuideOverlay({super.key, required this.onLearned});

  @override
  State<GuideOverlay> createState() => _GuideOverlayState();
}

class _GuideOverlayState extends State<GuideOverlay> {
  final List<String> _images = [
    'assets/first1.png',
    'assets/first2.png',
    'assets/first3.png',
  ];
  int _seconds = 15;
  bool _buttonEnabled = false;
  Timer? _timer;
  int _currentPage = 0;
  late bool _forceWait;

  // 每页的 TransformationController，用于控制和记录缩放状态
  late List<TransformationController> _controllers;

  @override
  void initState() {
    super.initState();
    // 为每一页都创建一个独立的 TransformationController
    _controllers =
        List.generate(_images.length, (_) => TransformationController());
    _initForceWait();
  }

  Future<void> _initForceWait() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // 在实际开发中，建议为 'first_launch_one_Zhou' 定义一个常量
    _forceWait = prefs.getBool('first_launch_one_Zhou') ?? true;
    if (_forceWait) {
      _buttonEnabled = false;
      _seconds = 15;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _seconds--;
          if (_seconds <= 0) {
            _buttonEnabled = true;
            _timer?.cancel();
          }
        });
      });
    } else {
      setState(() {
        _buttonEnabled = true;
        _seconds = 0;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    // 释放所有 TransformationController
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// 构建 PageView
  Widget _buildPageView(BuildContext context) {
    return PageView.builder(
      itemCount: _images.length,
      onPageChanged: (index) {
        // 当页面切换时，重置上一页的缩放状态
        // 这是一个优化，可以防止用户在多个页面之间来回切换时，页面保持着缩放状态
        _controllers[_currentPage].value = Matrix4.identity();
        setState(() {
          _currentPage = index;
        });
      },
      itemBuilder: (context, index) {
        // 关键改动：移除了 GestureDetector，直接使用 InteractiveViewer
        return InteractiveViewer(
          transformationController: _controllers[index],
          minScale: 1.0,  // 最小缩放比例
          maxScale: 4.0,  // 最大缩放比例
          // InteractiveViewer 默认就会处理双击放大，并以点击位置为中心
          child: Image.asset(
            _images[index],
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }
  
  /// 构建页面指示器
  Widget _buildIndicator(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_images.length, (index) {
        bool isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          width: isActive ? 18 : 10,
          height: isActive ? 18 : 10,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.grey[400],
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                color: theme.cardColor.withOpacity(0.95),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Stack(
                    children: [
                      _buildPageView(context),
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: _buildIndicator(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: ElevatedButton(
                  onPressed: _buttonEnabled ? widget.onLearned : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: _buttonEnabled ? 2 : 0,
                    backgroundColor:
                        Colors.lightBlue.withOpacity(_buttonEnabled ? 1.0 : 0.5),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _buttonEnabled
                        ? '我已经学会了'
                        : '我已经学会了（$_seconds）',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// 这个工具类没有问题，保持原样即可
class FirstTeachingUtil {
  static const _key = 'first_launch_one_Zhou';

  static Future<bool> isFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }

  static Future<void> setLearned() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, false);
  }
}