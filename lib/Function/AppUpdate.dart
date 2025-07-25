import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.blue[700], size: 20),
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
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'App更新',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.grey[700]),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.system_update_alt,
                          size: 48,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _onVersionInfoTap,
                        child: Text(
                          '版本信息',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '当前版本: ${VersionChecker.CURRENT_VERSION}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: Colors.blue.withOpacity(0.3),
                ),
                onPressed: _isChecking ? null : _checkForUpdates,
                child: _isChecking 
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '检查中...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      '检查更新',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
