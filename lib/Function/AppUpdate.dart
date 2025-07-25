import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../Config/update.dart';
import 'Function_DanZhu.dart';
import 'Function_GroupZhu.dart';

class AppUpdatePage extends StatefulWidget {
  const AppUpdatePage({Key? key}) : super(key: key);

  @override
  State<AppUpdatePage> createState() => _AppUpdatePageState();
}

class _AppUpdatePageState extends State<AppUpdatePage> {
  bool _isChecking = false;
  int _tapCount = 0;
  int _lastTapTime = 0;

  // 显示现代化弹窗
  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '确定',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 检查更新并显示结果
  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
    });

    final versionChecker = VersionChecker(globalContext: context);
    bool hasUpdate = await versionChecker.checkForUpdates();
    
    if (!hasUpdate) {
      _showAlert('当前已是最新版本', '您正在使用最新版本的应用(${VersionChecker.CURRENT_VERSION})');
    } else {
      await versionChecker.checkAndPromptForUpdates();
    }

    setState(() {
      _isChecking = false;
    });
  }

  // 彩蛋：强制显示更新弹窗
  void _onVersionInfoTap() {
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    
    // 如果距离上次点击超过2秒，重置计数
    if (currentTime - _lastTapTime > 2000) {
      _tapCount = 0;
    }
    
    _tapCount++;
    _lastTapTime = currentTime;
    
    print("[DEBUG] 版本信息点击次数: $_tapCount");
    
    if (_tapCount >= 5) {
      _tapCount = 0; // 重置计数器
      _triggerDeveloperMode();
    }
  }

  // 开发者模式：强制显示更新弹窗
  void _triggerDeveloperMode() async {
    print("[DEBUG] 触发开发者模式");
    
    // 显示开发者模式提示
    showDialog(
      context: context,
      barrierDismissible: false, // 禁止点击外部区域关闭
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.developer_mode, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('开发者模式'),
            ],
          ),
          content: const Text('开发者功能测试\n继续后进入开发者功能测试模式...'),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('继续'),
              onPressed: () {
                Navigator.of(context).pop();
                _showDeveloperTestMenu();
              },
            ),
          ],
        );
      },
    );
  }

  // 显示开发者测试菜单
  void _showDeveloperTestMenu() {
    showDialog(
      context: context,
      barrierDismissible: false, // 禁止点击外部区域关闭
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.bug_report, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('开发者功能测试'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTestOption(
                icon: Icons.system_update,
                title: '强制弹出更新窗口',
                subtitle: '测试更新弹窗UI和功能',
                onTap: () {
                  Navigator.of(context).pop();
                  _forceShowUpdateDialog();
                },
              ),
              const Divider(),
              _buildTestOption(
                icon: Icons.devices,
                title: '指定设备命令测试',
                subtitle: '跳转到单珠功能页面',
                onTap: () {
                  Navigator.of(context).pop();
                  _navigateToSingleDevice();
                },
              ),
              const Divider(),
              _buildTestOption(
                icon: Icons.device_hub,
                title: '多设备集体命令测试',
                subtitle: '跳转到群珠功能页面',
                onTap: () {
                  Navigator.of(context).pop();
                  _navigateToGroupDevice();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('关闭'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  // 构建测试选项UI
  Widget _buildTestOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.orange, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // 跳转到单珠功能页面
  void _navigateToSingleDevice() {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => DanZhu()),
      );
      print("[DEBUG] 导航到单珠功能页面");
    } catch (e) {
      print("[DEBUG] 导航失败: $e");
      _showAlert('导航失败', '无法跳转到单珠功能页面');
    }
  }

  // 跳转到群珠功能页面
  void _navigateToGroupDevice() {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => GroupZhu()),
      );
      print("[DEBUG] 导航到群珠功能页面");
    } catch (e) {
      print("[DEBUG] 导航失败: $e");
      _showAlert('导航失败', '无法跳转到群珠功能页面');
    }
  }

  // 强制显示更新弹窗（用于测试）
  void _forceShowUpdateDialog() async {
    final versionChecker = VersionChecker(globalContext: context);
    
    // 先尝试获取真实的版本信息
    await versionChecker.fetchLatestVersion();
    
    // 如果获取到了真实数据，直接显示
    if (versionChecker.latestReleaseData != null) {
      String latestVersion = versionChecker.latestReleaseData!['tag_name']?.replaceFirst('v', '') ?? '0.0.0';
      versionChecker.showUpdateDialogPublic(latestVersion);
    } else {
      // 如果没有获取到真实数据，创建测试数据
      versionChecker.latestReleaseData = {
        'tag_name': 'v999.9.9',
        'body': '🎉 开发者测试模式\n\n• 测试功能1\n• 测试功能2\n• 修复若干问题',
        'published_at': DateTime.now().toIso8601String(),
      };
      versionChecker.showUpdateDialogPublic('999.9.9');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('App更新'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              Container(
                margin: const EdgeInsets.all(20.0),
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      CupertinoIcons.cube_box,
                      size: 60,
                      color: CupertinoColors.activeBlue,
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _onVersionInfoTap,
                      child: const Text(
                        '版本信息',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '当前版本: ${VersionChecker.CURRENT_VERSION}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: CupertinoButton(
                  color: CupertinoColors.activeBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  borderRadius: BorderRadius.circular(12),
                  onPressed: _isChecking ? null : _checkForUpdates,
                  child: _isChecking 
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CupertinoActivityIndicator(color: CupertinoColors.white),
                          SizedBox(width: 10),
                          Text('检查中...', style: TextStyle(color: CupertinoColors.white)),
                        ],
                      )
                    : const Text('检查更新', style: TextStyle(fontSize: 17)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
