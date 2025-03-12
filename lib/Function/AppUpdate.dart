import 'package:flutter/cupertino.dart';

import '../Config/update.dart';

class AppUpdatePage extends StatefulWidget {
  const AppUpdatePage({Key? key}) : super(key: key);

  @override
  State<AppUpdatePage> createState() => _AppUpdatePageState();
}

class _AppUpdatePageState extends State<AppUpdatePage> {
  bool _isChecking = false;

  // 显示提示弹窗
  void _showAlert(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('确定'),
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
                    const Text(
                      '版本信息',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.black,
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
