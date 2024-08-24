// device_utils.dart
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> updateDeviceData() async {
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  try {
    if (await deviceInfoPlugin.androidInfo != null) {
      final AndroidDeviceInfo build = await deviceInfoPlugin.androidInfo;
      await prefs.setString('modelID', build.model);
      await prefs.setString('deviceID', build.id);
    } else if (await deviceInfoPlugin.iosInfo != null) {
      final IosDeviceInfo data = await deviceInfoPlugin.iosInfo;
      await prefs.setString('modelID', data.utsname.machine);
      await prefs.setString('deviceID', data.identifierForVendor ?? '');
    }
  } catch (e) {
    print("Failed to get or save device information: $e");
  }
}
