import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  factory SharedPrefs() => SharedPrefs._internal();
  SharedPrefs._internal();
  static SharedPreferences? _sharedPrefs;

  Future<void> init() async {
    _sharedPrefs ??= await SharedPreferences.getInstance();
  }

  String get id => _sharedPrefs!.getString(keyID) ?? '';
  String get channel => _sharedPrefs!.getString(keyChannel) ?? '';

  bool get authed => _sharedPrefs!.getBool(authenticated) ?? false;
  int get timestamp =>
      _sharedPrefs!.getInt(time) ??
      (DateTime.now().millisecondsSinceEpoch - (24 * 60 * 60 * 1000));

  set setId(String value) {
    _sharedPrefs!.setString(keyID, value);
  }

  set setChannel(String value) {
    _sharedPrefs!.setString(keyChannel, value);
  }

  set setAuthed(bool value) {
    _sharedPrefs!.setBool(authenticated, value);
  }

  set setTimestamp(int value) {
    _sharedPrefs!.setInt(time, value);
  }
}

// constants/strings.dart
const String keyID = 'id';
const String keyChannel = 'channel';
const String authenticated = 'authed';
const String time = "timestamp";
