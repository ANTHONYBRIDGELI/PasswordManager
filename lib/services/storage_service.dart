import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/password_entry.dart';

class StorageService {
  static const String _appFolder = 'PasswordManager';
  static const String _passwordFile = '.passwords.dat';
  static const String _keyFile = '.encryption_key';
  static const String _settingsFile = 'settings.json';
  static const String _colorThemesFile = 'color_themes.json';
  static const String _langFile = 'language.json';
  static const String _storagePathKey = 'documents_uri';

  String? _storagePath;
  encrypt.Key? _encryptionKey;

  Future<String?> getStoragePath() async {
    if (_storagePath != null) return _storagePath;

    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_storagePathKey);

    if (savedPath != null && await Directory(savedPath).exists()) {
      _storagePath = savedPath;
      return _storagePath;
    }

    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        String docsPath = extDir.path;
        if (docsPath.endsWith('/Android/data')) {
          docsPath = docsPath.replaceAll('/Android/data', '');
        }
        docsPath = '$docsPath/Documents';

        final docsDir = Directory(docsPath);
        if (!await docsDir.exists()) {
          await docsDir.create(recursive: true);
        }
        if (await docsDir.exists()) {
          _storagePath = docsPath;
          await prefs.setString(_storagePathKey, _storagePath!);
          return _storagePath;
        }

        _storagePath = extDir.path;
        await prefs.setString(_storagePathKey, _storagePath!);
        return _storagePath;
      }
    } catch (e) {
    }

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      _storagePath = docsDir.path;
      await prefs.setString(_storagePathKey, _storagePath!);
      return _storagePath;
    } catch (e) {
    }

    return null;
  }

  Future<String?> getAppFolderPath() async {
    final base = await getStoragePath();
    if (base == null) return null;
    return '$base/$_appFolder';
  }

  Future<bool> ensureAppFolder() async {
    final path = await getAppFolderPath();
    if (path == null) return false;

    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return true;
  }

  Future<encrypt.Key?> _getOrCreateKey() async {
    if (_encryptionKey != null) return _encryptionKey;

    final folderPath = await getAppFolderPath();
    if (folderPath == null) return null;

    final keyFile = File('$folderPath/$_keyFile');

    if (await keyFile.exists()) {
      try {
        final keyData = await keyFile.readAsString();
        _encryptionKey = encrypt.Key.fromBase64(keyData.trim());
        return _encryptionKey;
      } catch (e) {
        return null;
      }
    }

    _encryptionKey = encrypt.Key.fromSecureRandom(32);
    try {
      final dir = Directory(folderPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      await keyFile.writeAsString(_encryptionKey!.base64);
      return _encryptionKey;
    } catch (e) {
      return null;
    }
  }

  encrypt.Encrypter _getEncrypter(encrypt.Key key) {
    return encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  }

  Future<List<PasswordEntry>> loadPasswords() async {
    final folderPath = await getAppFolderPath();
    if (folderPath == null) return [];

    final dataFile = File('$folderPath/$_passwordFile');
    if (!await dataFile.exists()) return [];

    try {
      final encryptedContent = await dataFile.readAsString();
      if (encryptedContent.isEmpty) return [];

      final key = await _getOrCreateKey();
      if (key == null) return [];

      final parts = encryptedContent.split('|');
      if (parts.length != 2) return [];

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypter = _getEncrypter(key);

      final encryptedBytes = encrypt.Encrypted.fromBase64(parts[1]);
      final decrypted = encrypter.decrypt(encryptedBytes, iv: iv);
      final data = jsonDecode(decrypted) as List;

      return data.map((item) => PasswordEntry.fromDict(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> savePasswords(List<PasswordEntry> passwords) async {
    final folderPath = await getAppFolderPath();
    if (folderPath == null) return;

    await ensureAppFolder();

    try {
      final key = await _getOrCreateKey();
      if (key == null) return;

      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = _getEncrypter(key);

      final data = jsonEncode(passwords.map((p) => p.toDict()).toList());
      final encrypted = encrypter.encrypt(data, iv: iv);

      final dataFile = File('$folderPath/$_passwordFile');
      await dataFile.writeAsString(iv.base64 + '|' + encrypted.base64);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, String>?> loadSettings() async {
    final folderPath = await getAppFolderPath();
    if (folderPath == null) return null;

    final settingsFile = File('$folderPath/$_settingsFile');
    if (!await settingsFile.exists()) return null;

    try {
      final content = await settingsFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      return data.map((k, v) => MapEntry(k, v.toString()));
    } catch (e) {
      return null;
    }
  }

  Future<void> saveSettings(Map<String, String> settings) async {
    final folderPath = await getAppFolderPath();
    if (folderPath == null) return;

    await ensureAppFolder();
    final settingsFile = File('$folderPath/$_settingsFile');
    await settingsFile.writeAsString(jsonEncode(settings));
  }

  Future<Map<String, Map<String, String>>?> loadColorThemes() async {
    final folderPath = await getAppFolderPath();
    if (folderPath == null) return null;

    final themesFile = File('$folderPath/$_colorThemesFile');
    if (!await themesFile.exists()) return null;

    try {
      final content = await themesFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      return data.map((k, v) => MapEntry(
        k,
        (v as Map<String, dynamic>).map((k2, v2) => MapEntry(k2, v2.toString())),
      ));
    } catch (e) {
      return null;
    }
  }

  Future<void> saveColorThemes(Map<String, Map<String, String>> themes) async {
    final folderPath = await getAppFolderPath();
    if (folderPath == null) return;

    await ensureAppFolder();
    final themesFile = File('$folderPath/$_colorThemesFile');
    await themesFile.writeAsString(jsonEncode(themes));
  }

  Future<Map<String, Map<String, String>>?> loadLanguages() async {
    final folderPath = await getAppFolderPath();
    if (folderPath == null) return null;

    final langFile = File('$folderPath/$_langFile');
    if (!await langFile.exists()) return null;

    try {
      final content = await langFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      return data.map((k, v) => MapEntry(
        k,
        (v as Map<String, dynamic>).map((k2, v2) => MapEntry(k2, v2.toString())),
      ));
    } catch (e) {
      return null;
    }
  }

  Future<void> saveLanguages(Map<String, Map<String, String>> languages) async {
    final folderPath = await getAppFolderPath();
    if (folderPath == null) return;

    await ensureAppFolder();
    final langFile = File('$folderPath/$_langFile');
    await langFile.writeAsString(jsonEncode(languages));
  }

  Future<bool> hasStorage() async {
    final path = await getAppFolderPath();
    return path != null;
  }

  Future<String?> selectStorageFolder() async {
    final path = await getStoragePath();
    return path;
  }

  Future<void> setStoragePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storagePathKey, path);
    _storagePath = path;
  }

  Future<String> exportPasswords(List<PasswordEntry> passwords) async {
    final data = {
      'version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'password_count': passwords.length,
      'passwords': passwords.map((p) => p.toDict()).toList(),
    };
    return jsonEncode(data);
  }

  Future<List<PasswordEntry>> importPasswords(String jsonContent) async {
    final data = jsonDecode(jsonContent);

    List<dynamic> imported;
    if (data is Map && data.containsKey('passwords')) {
      imported = data['passwords'] as List;
    } else if (data is List) {
      imported = data;
    } else {
      throw FormatException('Invalid file format');
    }

    return imported
        .whereType<Map<String, dynamic>>()
        .where((item) => item.containsKey('name') && item.containsKey('password'))
        .map((item) => PasswordEntry(
              name: item['name']?.toString() ?? '',
              account: item['account']?.toString() ?? '',
              password: item['password']?.toString() ?? '',
              notes: item['notes']?.toString() ?? '',
            ))
        .toList();
  }
}