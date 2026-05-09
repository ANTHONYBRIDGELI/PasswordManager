import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path_provider/path_provider.dart';
import '../models/password_entry.dart';

class StorageService {
  static const String _appFolder = 'PasswordManager';
  static const String _passwordFile = 'passwords.dat';
  static const String _keyFile = 'encryption_key';
  static const String _groupsFile = 'groups.json';

  String? _storagePath;
  encrypt.Key? _encryptionKey;

  Future<String?> getStoragePath() async {
    if (_storagePath != null) return _storagePath;
    final extDir = await getExternalStorageDirectory();
    if (extDir != null) {
      _storagePath = extDir.path;
      return _storagePath;
    }
    final docsDir = await getApplicationDocumentsDirectory();
    _storagePath = docsDir.path;
    return _storagePath;
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
        _encryptionKey = encrypt.Key.fromSecureRandom(32);
        return _encryptionKey;
      }
    }

    _encryptionKey = encrypt.Key.fromSecureRandom(32);
    try {
      final dir = Directory(folderPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      await keyFile.writeAsString(_encryptionKey!.base64);
    } catch (e) {
    }
    return _encryptionKey;
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
      if (parts.length == 2) {
        try {
          final iv = encrypt.IV.fromBase64(parts[0]);
          final encrypter = _getEncrypter(key);
          final encryptedBytes = encrypt.Encrypted.fromBase64(parts[1]);
          final decrypted = encrypter.decrypt(encryptedBytes, iv: iv);
          final data = jsonDecode(decrypted) as List;
          return data.map((item) => PasswordEntry.fromDict(item)).toList();
        } catch (e) {
        }
      }

      return [];
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

  Future<void> saveGroups(List<PasswordGroup> groups) async {
    final folderPath = await getAppFolderPath();
    if (folderPath == null) return;

    await ensureAppFolder();

    try {
      final groupsFile = File('$folderPath/$_groupsFile');
      await groupsFile.writeAsString(jsonEncode(groups.map((g) => g.toDict()).toList()));
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PasswordGroup>> loadGroups() async {
    final folderPath = await getAppFolderPath();
    if (folderPath == null) return [];

    final groupsFile = File('$folderPath/$_groupsFile');
    if (!await groupsFile.exists()) return [];

    try {
      final content = await groupsFile.readAsString();
      final data = jsonDecode(content) as List;
      return data.map((item) => PasswordGroup.fromDict(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<String> exportData(List<PasswordEntry> passwords, List<PasswordGroup> groups) async {
    final data = {
      'version': '2.0',
      'exported_at': DateTime.now().toIso8601String(),
      'password_count': passwords.length,
      'group_count': groups.length,
      'passwords': passwords.map((p) => p.toDict()).toList(),
      'groups': groups.map((g) => g.toDict()).toList(),
    };
    return jsonEncode(data);
  }

  Future<({List<PasswordEntry> passwords, List<PasswordGroup> groups})> importData(String jsonContent) async {
    final data = jsonDecode(jsonContent);

    List<PasswordGroup> groups = [];
    List<PasswordEntry> passwords = [];

    final bool isOldFormat = data is List || (data is Map && !data.containsKey('groups'));

    if (isOldFormat) {
      List<dynamic> imported;
      if (data is Map && data.containsKey('passwords')) {
        imported = data['passwords'] as List;
      } else if (data is List) {
        imported = data;
      } else {
        throw FormatException('Invalid file format');
      }

      passwords = imported
          .whereType<Map<String, dynamic>>()
          .where((item) => item.containsKey('name') && item.containsKey('password'))
          .map((item) => PasswordEntry(
                name: item['name']?.toString() ?? '',
                account: item['account']?.toString() ?? '',
                password: item['password']?.toString() ?? '',
                notes: item['notes']?.toString() ?? '',
                groupId: 'default',
              ))
          .toList();

      groups = [
        PasswordGroup(id: 'default', name: '默认分组', color: '#58A6FF'),
      ];
    } else {
      if (data is Map) {
        if (data.containsKey('groups')) {
          groups = (data['groups'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => PasswordGroup.fromDict(item))
              .toList();
        }

        final passwordList = data['passwords'] as List? ?? [];
        passwords = passwordList
            .whereType<Map<String, dynamic>>()
            .map((item) => PasswordEntry.fromDict(item))
            .toList();
      }
    }

    return (passwords: passwords, groups: groups);
  }
}
