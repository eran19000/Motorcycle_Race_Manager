import 'package:shared_preferences/shared_preferences.dart';

/// Resolves the Gemini API key without hardcoding it in source control.
///
/// Priority:
/// 1. `--dart-define=GEMINI_API_KEY=...` (CI / release builds)
/// 2. [SharedPreferences] key [prefsKeyGeminiApi] (in-app "Save API key")
const String prefsKeyGeminiApi = 'gemini_user_api_key';

class GeminiApiResolver {
  GeminiApiResolver._();

  static const String _fromDefine = String.fromEnvironment('GEMINI_API_KEY');

  static Future<String> resolve() async {
    if (_fromDefine.isNotEmpty) return _fromDefine;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(prefsKeyGeminiApi)?.trim();
    if (stored != null && stored.isNotEmpty) return stored;
    return '';
  }

  static Future<void> saveUserKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final t = key.trim();
    if (t.isEmpty) {
      await prefs.remove(prefsKeyGeminiApi);
      return;
    }
    await prefs.setString(prefsKeyGeminiApi, t);
  }

  static Future<void> clearUserKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKeyGeminiApi);
  }
}
