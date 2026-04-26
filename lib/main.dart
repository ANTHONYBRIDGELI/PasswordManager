import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'models/password_entry.dart';
import 'services/storage_service.dart';
import 'constants/app_constants.dart';

void main() {
  runApp(const PasswordManagerApp());
}

class PasswordManagerApp extends StatelessWidget {
  const PasswordManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Password Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}

class AppColors {
  final Color bgColor;
  final Color cardColor;
  final Color primaryColor;
  final Color accentColor;
  final Color dangerColor;
  final Color textColor;
  final Color subtextColor;

  AppColors({
    required this.bgColor,
    required this.cardColor,
    required this.primaryColor,
    required this.accentColor,
    required this.dangerColor,
    required this.textColor,
    required this.subtextColor,
  });

  factory AppColors.fromMap(Map<String, String> map) {
    return AppColors(
      bgColor: Color(int.parse(map['bg_color']!.replaceFirst('#', '0xFF'))),
      cardColor: Color(int.parse(map['card_color']!.replaceFirst('#', '0xFF'))),
      primaryColor: Color(int.parse(map['primary_color']!.replaceFirst('#', '0xFF'))),
      accentColor: Color(int.parse(map['accent_color']!.replaceFirst('#', '0xFF'))),
      dangerColor: Color(int.parse(map['danger_color']!.replaceFirst('#', '0xFF'))),
      textColor: Color(int.parse(map['text_color']!.replaceFirst('#', '0xFF'))),
      subtextColor: Color(int.parse(map['subtext_color']!.replaceFirst('#', '0xFF'))),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StorageService _storage = StorageService();
  List<PasswordEntry> _passwords = [];
  List<PasswordEntry> _filteredPasswords = [];
  String _searchQuery = '';

  String _themeSetting = 'dark';
  String _langSetting = 'zh';
  Map<String, Map<String, String>> _colorThemes = {};
  Map<String, Map<String, String>> _languages = {};

  late AppColors _colors;
  bool _isLoading = true;
  bool _isDarkMode = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initApp() async {
    final hasStorage = await _storage.hasStorage();
    if (!hasStorage) {
      await _storage.setStoragePath((await getApplicationDocumentsDirectory()).path);
      await _storage.ensureAppFolder();
    }

    _colorThemes = Map.from(defaultColorThemes);
    final fileThemes = await _storage.loadColorThemes();
    if (fileThemes != null) {
      _colorThemes.addAll(fileThemes);
    }

    _languages = Map.from(defaultLanguages);
    final fileLangs = await _storage.loadLanguages();
    if (fileLangs != null) {
      _languages.addAll(fileLangs);
    } else {
      await _storage.saveLanguages(defaultLanguages);
    }

    final settings = await _storage.loadSettings();
    if (settings != null) {
      _themeSetting = settings['theme'] ?? 'dark';
      _langSetting = settings['lang'] ?? 'zh';
    } else {
      await _storage.saveSettings(defaultSettings);
    }

    _updateThemeMode();
    _setupColors();

    _passwords = await _storage.loadPasswords();
    _filteredPasswords = List.from(_passwords);

    setState(() {
      _isLoading = false;
    });
  }

  void _updateThemeMode() {
    String theme = _themeSetting;
    if (theme == 'system') {
      theme = 'dark';
    }
    _isDarkMode = theme == 'dark' || theme == 'green' || theme == 'blue' || theme == 'red' || theme == 'purple';
  }

  void _setupColors() {
    Map<String, String> colorMap;
    if (_colorThemes.containsKey(_themeSetting)) {
      colorMap = _colorThemes[_themeSetting]!;
    } else if (_isDarkMode) {
      colorMap = defaultDarkColors;
    } else {
      colorMap = defaultLightColors;
    }
    _colors = AppColors.fromMap(colorMap);
  }

  String t(String key) {
    return _languages[_langSetting]?[key] ?? defaultLanguages['zh']?[key] ?? key;
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredPasswords = List.from(_passwords);
      } else {
        _filteredPasswords = _passwords.where((p) {
          return p.name.toLowerCase().contains(_searchQuery) ||
              p.account.toLowerCase().contains(_searchQuery) ||
              p.password.toLowerCase().contains(_searchQuery) ||
              p.notes.toLowerCase().contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _savePasswords() async {
    await _storage.savePasswords(_passwords);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _colors.cardColor,
      ),
    );
  }

  Future<void> _showAddDialog() async {
    await _showEntryDialog(null);
  }

  Future<void> _showEditDialog(PasswordEntry entry) async {
    await _showEntryDialog(entry);
  }

  Future<void> _showEntryDialog(PasswordEntry? entry) async {
    final isEdit = entry != null;
    final nameController = TextEditingController(text: entry?.name ?? '');
    final accountController = TextEditingController(text: entry?.account ?? '');
    final passwordController = TextEditingController(text: entry?.password ?? '');
    final notesController = TextEditingController(text: entry?.notes ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _colors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEdit ? t('edit_password') : t('add_password'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _colors.textColor,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: t('name_field'),
                  filled: true,
                  fillColor: const Color(0xFF21262D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: accountController,
                decoration: InputDecoration(
                  labelText: t('account_field'),
                  filled: true,
                  fillColor: const Color(0xFF21262D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: t('password_field'),
                  filled: true,
                  fillColor: const Color(0xFF21262D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: t('notes_field'),
                  filled: true,
                  fillColor: const Color(0xFF21262D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel'), style: TextStyle(color: _colors.subtextColor)),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                _showSnackBar('Name is required');
                return;
              }

              if (isEdit) {
                entry.name = name;
                entry.account = accountController.text.trim();
                entry.password = passwordController.text.trim();
                entry.notes = notesController.text.trim();
              } else {
                _passwords.insert(0, PasswordEntry(
                  name: name,
                  account: accountController.text.trim(),
                  password: passwordController.text.trim(),
                  notes: notesController.text.trim(),
                ));
              }

              await _savePasswords();
              setState(() {
                _onSearch(_searchQuery);
              });

              Navigator.pop(context);
            },
            child: Text(t('save'), style: TextStyle(color: _colors.primaryColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(PasswordEntry entry) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _colors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('confirm_delete'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _colors.textColor,
          ),
        ),
        content: Text(
          t('delete_message'),
          style: TextStyle(fontSize: 15, color: _colors.subtextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel'), style: TextStyle(color: _colors.subtextColor)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _passwords.remove(entry);
              await _savePasswords();
              setState(() {
                _onSearch(_searchQuery);
              });
            },
            child: Text(t('delete'), style: TextStyle(color: _colors.dangerColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetailDialog(PasswordEntry entry) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _colors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _colors.primaryColor,
              child: Text(
                entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              entry.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _colors.textColor,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(t('account'), entry.account),
            const SizedBox(height: 16),
            _detailRow(t('password'), entry.password),
            if (entry.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              _detailRow(t('notes'), entry.notes),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('close'), style: TextStyle(color: _colors.subtextColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditDialog(entry);
            },
            child: Text(t('edit'), style: TextStyle(color: _colors.primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: _colors.subtextColor),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.copy, size: 18, color: _colors.subtextColor),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                _showSnackBar('$label ${t('copied')}');
              },
            ),
          ],
        ),
        Text(
          value.isEmpty ? '-' : value,
          style: TextStyle(fontSize: 15, color: _colors.textColor),
        ),
      ],
    );
  }

  Future<void> _showSettingsDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _colors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('settings'),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _colors.textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(t('theme'), style: TextStyle(fontSize: 16, color: _colors.textColor)),
                const Spacer(),
                DropdownButton<String>(
                  value: _themeSetting,
                  dropdownColor: _colors.cardColor,
                  items: [
                    DropdownMenuItem(value: 'system', child: Text(t('follow_system'))),
                    DropdownMenuItem(value: 'dark', child: Text(t('dark'))),
                    DropdownMenuItem(value: 'light', child: Text(t('light'))),
                    ..._colorThemes.entries.map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value['name'] ?? e.key),
                    )),
                  ],
                  onChanged: (value) async {
                    if (value != null) {
                      _themeSetting = value;
                      _updateThemeMode();
                      _setupColors();
                      await _storage.saveSettings({'theme': _themeSetting, 'lang': _langSetting});
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Text(t('language'), style: TextStyle(fontSize: 16, color: _colors.textColor)),
                const Spacer(),
                DropdownButton<String>(
                  value: _langSetting,
                  dropdownColor: _colors.cardColor,
                  items: _languages.entries.map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value['name'] ?? e.key),
                  )).toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      _langSetting = value;
                      await _storage.saveSettings({'theme': _themeSetting, 'lang': _langSetting});
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _exportPasswords,
              child: Text(t('export'), style: TextStyle(color: _colors.primaryColor)),
            ),
            TextButton(
              onPressed: _importPasswords,
              child: Text(t('import'), style: TextStyle(color: _colors.primaryColor)),
            ),
            const SizedBox(height: 5),
            Text(
              '${t('version')}: $appVersion',
              style: TextStyle(fontSize: 12, color: _colors.subtextColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPasswords() async {
    Navigator.pop(context);

    if (_passwords.isEmpty) {
      _showSnackBar(t('no_passwords'));
      return;
    }

    try {
      final jsonContent = await _storage.exportPasswords(_passwords);
      final now = DateTime.now();
      final fileName = 'Password_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}_${now.minute.toString().padLeft(2, '0')}_${now.second.toString().padLeft(2, '0')}.json';

      final result = await FilePicker.platform.saveFile(
        dialogTitle: t('export'),
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(jsonContent),
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(jsonContent);
        _showSnackBar(t('export_success'));
      }
    } catch (e) {
      _showSnackBar('${t('export_failed')}: $e');
    }
  }

  Future<void> _importPasswords() async {
    Navigator.pop(context);

    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: t('select_file'),
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final imported = await _storage.importPasswords(content);

        if (imported.isEmpty) {
          _showSnackBar(t('import_failed'));
          return;
        }

        final existingNames = _passwords.map((p) => p.name).toSet();
        final duplicates = imported.where((e) => existingNames.contains(e.name)).length;

        if (duplicates > 0) {
          _showImportModeDialog(imported);
        } else {
          _passwords.addAll(imported);
          await _savePasswords();
          setState(() {
            _onSearch(_searchQuery);
          });
          _showSnackBar('${t('import_success')}: ${imported.length}');
        }
      }
    } catch (e) {
      _showSnackBar('${t('import_failed')}: $e');
    }
  }

  Future<void> _showImportModeDialog(List<PasswordEntry> imported) async {
    String selectedMode = 'direct_add';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _colors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('select_import_mode'),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _colors.textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${t('duplicates_found')} ${imported.length} ${t('import_mode_desc')}',
              style: TextStyle(fontSize: 14, color: _colors.subtextColor),
            ),
            const SizedBox(height: 10),
            RadioListTile<String>(
              value: 'direct_add',
              groupValue: selectedMode,
              title: Text(t('direct_add'), style: TextStyle(color: _colors.textColor)),
              subtitle: Text(t('direct_add_desc'), style: TextStyle(fontSize: 12, color: _colors.subtextColor)),
              onChanged: (v) => setState(() => selectedMode = v!),
            ),
            RadioListTile<String>(
              value: 'update_add',
              groupValue: selectedMode,
              title: Text(t('update_add'), style: TextStyle(color: _colors.textColor)),
              subtitle: Text(t('update_add_desc'), style: TextStyle(fontSize: 12, color: _colors.subtextColor)),
              onChanged: (v) => setState(() => selectedMode = v!),
            ),
            RadioListTile<String>(
              value: 'diff_add',
              groupValue: selectedMode,
              title: Text(t('diff_add'), style: TextStyle(color: _colors.textColor)),
              subtitle: Text(t('diff_add_desc'), style: TextStyle(fontSize: 12, color: _colors.subtextColor)),
              onChanged: (v) => setState(() => selectedMode = v!),
            ),
            RadioListTile<String>(
              value: 'overwrite_add',
              groupValue: selectedMode,
              title: Text(t('overwrite_add'), style: TextStyle(color: _colors.textColor)),
              subtitle: Text(t('overwrite_add_desc'), style: TextStyle(fontSize: 12, color: _colors.subtextColor)),
              onChanged: (v) => setState(() => selectedMode = v!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel'), style: TextStyle(color: _colors.subtextColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _doImport(imported, selectedMode);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _colors.primaryColor),
            child: Text(t('confirm')),
          ),
        ],
      ),
    );
  }

  Future<void> _doImport(List<PasswordEntry> imported, String mode) async {
    final existingNames = _passwords.map((p) => p.name).toSet();
    int count = 0;

    switch (mode) {
      case 'overwrite_add':
        _passwords.clear();
        _passwords.addAll(imported);
        count = imported.length;
        break;
      case 'direct_add':
        _passwords.addAll(imported);
        count = imported.length;
        break;
      case 'update_add':
        for (final entry in imported) {
          final existingIndex = _passwords.indexWhere((p) => p.name == entry.name);
          if (existingIndex >= 0) {
            _passwords[existingIndex] = entry;
          } else {
            _passwords.add(entry);
          }
          count++;
        }
        break;
      case 'diff_add':
        for (final entry in imported) {
          if (!existingNames.contains(entry.name)) {
            _passwords.add(entry);
            count++;
          }
        }
        break;
    }

    await _savePasswords();
    setState(() {
      _onSearch(_searchQuery);
    });
    _showSnackBar('${t('import_success')}: $count');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _colors.bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 50, bottom: 10),
                  child: Text(
                    t('app_name'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _colors.textColor,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: t('search_hint'),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: _colors.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      hintStyle: TextStyle(color: _colors.subtextColor),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0),
                    decoration: BoxDecoration(
                      color: _colors.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _filteredPasswords.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.key, size: 64, color: _colors.subtextColor),
                                const SizedBox(height: 8),
                                Text(
                                  t('no_passwords'),
                                  style: TextStyle(fontSize: 18, color: _colors.subtextColor),
                                ),
                                Text(
                                  t('add_hint'),
                                  style: TextStyle(fontSize: 14, color: _colors.subtextColor),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _filteredPasswords.length,
                            itemBuilder: (context, index) {
                              final p = _filteredPasswords[index];
                              return _buildPasswordCard(p);
                            },
                          ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 10,
              left: 10,
              child: IconButton(
                icon: Icon(Icons.settings, color: _colors.subtextColor),
                onPressed: _showSettingsDialog,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: _colors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPasswordCard(PasswordEntry p) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _colors.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showDetailDialog(p),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _colors.primaryColor,
                  child: Text(
                    p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _colors.textColor,
                        ),
                      ),
                      Text(
                        p.account.isEmpty ? 'No account' : p.account,
                        style: TextStyle(fontSize: 13, color: _colors.subtextColor),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: _colors.subtextColor),
                  onPressed: () => _showEditDialog(p),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: _colors.dangerColor),
                  onPressed: () => _showDeleteDialog(p),
                ),
              ],
            ),
            Container(
              height: 1,
              color: const Color(0xFF21262D),
              margin: const EdgeInsets.only(top: 10),
            ),
          ],
        ),
      ),
    );
  }
}