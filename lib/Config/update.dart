import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionChecker {
  static const String GITHUB_RELEASES_URL =
      "https://api.github.com/repos/{owner}/{repo}/releases/latest";
  static const String GITEE_RELEASES_URL =
      "https://gitee.com/api/v5/repos/{owner}/{repo}/releases/latest";

  static const String GITHUB_OWNER = "lanzeweie";
  static const String GITHUB_REPO = "HanHan";
  static const String GITEE_OWNER = "buxiangqumingzi";
  static const String GITEE_REPO = "han-han-flutter";
  static const String CURRENT_VERSION = "3.6.1"; // 当前版本号

  BuildContext? globalContext;

  VersionChecker({this.globalContext});

  Future<void> checkAndPromptForUpdates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastSkippedVersion = prefs.getString('skipped_version');

    print("[DEBUG] 检查更新中...");
    bool hasUpdate = await checkForUpdates();
    if (hasUpdate) {
      String newVersion = await fetchLatestVersion();
      print("[DEBUG] 最新版本: $newVersion, 当前版本: $CURRENT_VERSION");
      if (newVersion == lastSkippedVersion) {
        print("[DEBUG] 已跳过此版本: $newVersion");
        return;
      }

      _showUpdateDialog(newVersion);
    } else {
      print("[DEBUG] 当前已是最新版本");
    }
  }

  Future<bool> checkForUpdates() async {
    String latestVersion = await fetchLatestVersion();
    return _compareVersions(latestVersion, CURRENT_VERSION);
  }

  Future<String> fetchLatestVersion() async {
    print("[DEBUG] 正在获取最新版本信息...");
    String githubUrl = GITHUB_RELEASES_URL
        .replaceAll('{owner}', GITHUB_OWNER)
        .replaceAll('{repo}', GITHUB_REPO);
    Map<String, dynamic>? latestRelease = await _fetchLatestRelease(githubUrl);

    if (latestRelease == null) {
      print("[DEBUG] GitHub 获取失败，尝试从 Gitee 获取...");
      String giteeUrl = GITEE_RELEASES_URL
          .replaceAll('{owner}', GITEE_OWNER)
          .replaceAll('{repo}', GITEE_REPO);
      latestRelease = await _fetchLatestRelease(giteeUrl);
    }

    if (latestRelease == null) {
      print("[DEBUG] 无法获取最新版本信息，返回当前版本");
      return CURRENT_VERSION;
    }

    String version = latestRelease['tag_name']?.replaceFirst('v', '') ?? CURRENT_VERSION;
    print("[DEBUG] 获取到的最新版本: $version");
    return version;
  }

  Future<Map<String, dynamic>?> _fetchLatestRelease(String url) async {
    print("[DEBUG] 请求版本信息: $url");
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print("[DEBUG] 成功获取到版本信息");
        return jsonDecode(response.body) as Map<String, dynamic>?;
      } else {
        print("[DEBUG] 获取版本信息失败: HTTP ${response.statusCode}");
      }
    } catch (e) {
      print("[DEBUG] 获取版本信息失败: $e");
    }
    return null;
  }

  void _showUpdateDialog(String newVersion) {
    if (globalContext == null) return;

    print("[DEBUG] 显示更新对话框: $newVersion");
    showDialog(
      context: globalContext!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('发现新版本 $newVersion'),
          content: Text('请选择下载方式或跳过此版本：'),
          actions: [
            TextButton(
              child: Text('GitHub'),
              onPressed: () => _openUrl('https://github.com/lanzeweie/HanHan_terminal/releases'),
            ),
            TextButton(
              child: Text('Gitee'),
              onPressed: () => _openUrl('https://gitee.com/buxiangqumingzi/han-han_terminal/releases'),
            ),
            TextButton(
              child: Text('蓝奏云'),
              onPressed: () => _openUrl('https://wwpp.lanzouv.com/b0foy1bkb'),
            ),
            TextButton(
              child: Text('跳过此版本'),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.setString('skipped_version', newVersion);
                print("[DEBUG] 跳过版本: $newVersion");
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _openUrl(String url) async {
    print("[DEBUG] 尝试打开链接: $url");
    if (await canLaunch(url)) {
      await launch(url);
      print("[DEBUG] 成功打开链接");
    } else {
      print("[DEBUG] 无法打开链接: $url");
    }
  }

  bool _compareVersions(String latest, String current) {
    print("[DEBUG] 比较版本: 最新版本=$latest, 当前版本=$current");
    List<int> latestParts =
        latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> currentParts =
        current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length || latestParts[i] > currentParts[i]) {
        print("[DEBUG] 需要更新");
        return true;
      } else if (latestParts[i] < currentParts[i]) {
        print("[DEBUG] 无需更新");
        return false;
      }
    }

    print("[DEBUG] 版本一致，无需更新");
    return false;
  }
}
