import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../color.dart';

class VersionChecker {
  static const String GITHUB_RELEASES_URL =
      "https://api.github.com/repos/{owner}/{repo}/releases/latest";
  static const String GITEE_RELEASES_URL =
      "https://gitee.com/api/v5/repos/{owner}/{repo}/releases/latest?access_token={token}";

  static const String GITHUB_OWNER = "lanzeweie";
  static const String GITHUB_REPO = "HanHan";
  static const String GITEE_OWNER = "buxiangqumingzi";
  static const String GITEE_REPO = "han-han-flutter";
  static const String CURRENT_VERSION = "3.7.2"; // 当前版本号 每次修改还需与在pubspec.yaml中保持一致
  static const String ACCESS_TOKEN = "10ca1c7562fd92a87c3205d7af8ba01d"; // Gitee API Access Token

  BuildContext? globalContext;

  Map<String, dynamic>? _latestReleaseData; // 存储最新版本的完整数据

  VersionChecker({this.globalContext});

  // 添加公共方法来访问发布数据
  Map<String, dynamic>? get latestReleaseData => _latestReleaseData;
  
  // 添加公共方法来设置发布数据（用于测试）
  set latestReleaseData(Map<String, dynamic>? data) {
    _latestReleaseData = data;
  }

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
    _latestReleaseData = await _fetchLatestRelease(githubUrl);

    if (_latestReleaseData == null) {
      print("[DEBUG] GitHub 获取失败，尝试从 Gitee 获取...");
      String giteeUrl = GITEE_RELEASES_URL
          .replaceAll('{owner}', GITEE_OWNER)
          .replaceAll('{repo}', GITEE_REPO)
          .replaceAll('{token}', ACCESS_TOKEN);
      _latestReleaseData = await _fetchLatestRelease(giteeUrl);
    }

    if (_latestReleaseData == null) {
      print("[DEBUG] 无法获取最新版本信息，返回当前版本");
      return CURRENT_VERSION;
    }

    String version = _latestReleaseData!['tag_name']?.replaceFirst('v', '') ?? CURRENT_VERSION;
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

  // 添加公共方法来显示更新对话框（用于开发者模式）
  void showUpdateDialogPublic(String newVersion) {
    _showUpdateDialog(newVersion);
  }

  void _showUpdateDialog(String newVersion) {
    if (globalContext == null || _latestReleaseData == null) return;

    print("[DEBUG] 显示更新对话框: $newVersion");
    
    String releaseNotes = _latestReleaseData!['body'] ?? '暂无更新说明';
    String publishedAt = _latestReleaseData!['published_at'] ?? '';
    String formattedDate = '';
    
    if (publishedAt.isNotEmpty) {
      try {
        DateTime date = DateTime.parse(publishedAt);
        formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      } catch (e) {
        print("[DEBUG] 日期解析失败: $e");
      }
    }

    showDialog(
      context: globalContext!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.system_update,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '发现新版本',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (formattedDate.isNotEmpty)
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              color: AppColors.colorBackgroundcolor(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Text(
                      'v$newVersion',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '更新内容：',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.colorBackgroundcolor(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      releaseNotes,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('跳过此版本'),
                    onPressed: () async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      prefs.setString('skipped_version', newVersion);
                      print("[DEBUG] 跳过版本: $newVersion");
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('立即更新'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showDownloadOptions();
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showDownloadOptions() {
    if (globalContext == null) return;

    showDialog(
      context: globalContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '选择下载方式',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDownloadOption(
                icon: Icons.code,
                title: 'GitHub',
                subtitle: '官方发布渠道',
                onTap: () => _openUrl('https://github.com/lanzeweie/HanHan/releases'),
              ),
              const Divider(),
              _buildDownloadOption(
                icon: Icons.cloud_download,
                title: 'Gitee',
                subtitle: '国内镜像源',
                onTap: () => _openUrl('https://gitee.com/buxiangqumingzi/han-han-flutter/releases'),
              ),
              const Divider(),
              _buildDownloadOption(
                icon: Icons.storage,
                title: '蓝奏云',
                subtitle: '高速下载',
                onTap: () => _openUrl('https://wwpp.lanzouv.com/b0foy1bkb'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDownloadOption({
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
              child: Icon(icon, color: Colors.blue, size: 20),
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
            const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    print("[DEBUG] 尝试打开链接: $url");
    try {
      final uri = Uri.parse(url);
      // 优先尝试用默认浏览器打开
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) {
          print("[DEBUG] 成功用默认浏览器打开链接");
          return;
        }
      }
    } catch (e) {
      print("[DEBUG] launchUrl 异常: $e");
    }
    // 打开失败，复制到剪贴板并提示
    await Clipboard.setData(ClipboardData(text: url));
    if (globalContext != null) {
      ScaffoldMessenger.of(globalContext!).showSnackBar(
        SnackBar(content: Text('链接已复制到剪贴板，请在浏览器中打开')),
      );
    }
    print("[DEBUG] 无法打开链接，已复制到剪贴板: $url");
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
