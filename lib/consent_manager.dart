import 'package:shared_preferences/shared_preferences.dart';
import 'keys.dart';

class ConsentManager {
  static Future<bool> isConsented() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(kConsentKey) ?? false;
  }
  static Future<void> setConsented(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(kConsentKey, v);
  }
}