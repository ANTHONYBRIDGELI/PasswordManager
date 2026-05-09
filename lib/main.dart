import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'models/password_entry.dart';
import 'services/storage_service.dart';
import 'constants/app_constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  List<PasswordGroup> _groups = [];
  String _searchQuery = '';

  String _themeSetting = 'dark';
  String _langSetting = 'zh';
  Map<String, Map<String, String>> _colorThemes = {};
  Map<String, Map<String, String>> _languages = {};

  late AppColors _colors = AppColors.fromMap(defaultDarkColors);
  bool _isLoading = true;
  bool _isDarkMode = true;

  int _currentTab = 0;
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
    await _storage.getStoragePath();
    await _storage.ensureAppFolder();

    _colorThemes = Map.from(defaultColorThemes);
    _languages = Map.from(defaultLanguages);

    _updateThemeMode();
    _setupColors();

    try {
      _passwords = await _storage.loadPasswords();
    } catch (_) {}

    try {
      _groups = await _storage.loadGroups();
    } catch (_) {}
    if (_groups.isEmpty) {
      _groups = [PasswordGroup(id: 'default', name: '默认分组', color: '#58A6FF')];
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _updateThemeMode() {
    String theme = _themeSetting;
    if (theme == 'system') {
      theme = MediaQuery.platformBrightnessOf(context) == Brightness.dark ? 'dark' : 'light';
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
    });
  }

  List<PasswordEntry> _getFilteredPasswords() {
    if (_searchQuery.isEmpty) return _passwords;
    return _passwords.where((p) {
      return p.name.toLowerCase().contains(_searchQuery) ||
          p.account.toLowerCase().contains(_searchQuery) ||
          p.password.toLowerCase().contains(_searchQuery) ||
          p.notes.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  List<PasswordEntry> _getPasswordsByGroup(String groupId) {
    return _getFilteredPasswords().where((p) => p.groupId == groupId).toList();
  }

  int _getGroupPasswordCount(String groupId) {
    return _passwords.where((p) => p.groupId == groupId).length;
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

  static const List<String> groupColors = [
    '#58A6FF', '#238636', '#F85149', '#A371F7',
    '#F0883E', '#8957E5', '#3FB950', '#DB61A2',
  ];

  Future<void> _showAddGroupDialog() async {
    final nameController = TextEditingController();
    String selectedColor = groupColors[0];

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _colors.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                t('add_password'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _colors.textColor),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 16),
                    Text('Color', style: TextStyle(fontSize: 14, color: _colors.subtextColor)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: groupColors.map((color) {
                        final isSelected = color == selectedColor;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = color),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(t('cancel'), style: TextStyle(color: _colors.subtextColor)),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      _showSnackBar('Name is required');
                      return;
                    }
                    final newGroup = PasswordGroup(name: name, color: selectedColor);
                    setState(() {
                      _groups.add(newGroup);
                    });
                    await _storage.saveGroups(_groups);
                    Navigator.pop(dialogContext);
                  },
                  child: Text(t('save'), style: TextStyle(color: _colors.primaryColor)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteGroupDialog(PasswordGroup group) async {
    final count = _getGroupPasswordCount(group.id);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _colors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('confirm_delete'),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _colors.textColor),
        ),
        content: Text(
          'Delete group "${group.name}" and $count passwords?',
          style: TextStyle(fontSize: 15, color: _colors.subtextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t('cancel'), style: TextStyle(color: _colors.subtextColor)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() {
                _passwords.removeWhere((p) => p.groupId == group.id);
                _groups.remove(group);
              });
              await _savePasswords();
              await _storage.saveGroups(_groups);
            },
            child: Text(t('delete'), style: TextStyle(color: _colors.dangerColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _showGroupOptionsDialog(PasswordGroup group) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _colors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          group.name,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _colors.textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: _colors.primaryColor),
              title: Text(t('edit'), style: TextStyle(color: _colors.textColor)),
              onTap: () {
                Navigator.pop(dialogContext);
                _showEditGroupDialog(group);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: _colors.dangerColor),
              title: Text(t('delete'), style: TextStyle(color: _colors.textColor)),
              onTap: () {
                Navigator.pop(dialogContext);
                _showDeleteGroupDialog(group);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditGroupDialog(PasswordGroup group) async {
    final nameController = TextEditingController(text: group.name);
    String selectedColor = group.color;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _colors.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                t('edit_password'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _colors.textColor),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 16),
                    Text('Color', style: TextStyle(fontSize: 14, color: _colors.subtextColor)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: groupColors.map((color) {
                        final isSelected = color == selectedColor;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = color),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(t('cancel'), style: TextStyle(color: _colors.subtextColor)),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      _showSnackBar('Name is required');
                      return;
                    }
                    setState(() {
                      final index = _groups.indexWhere((g) => g.id == group.id);
                      if (index >= 0) {
                        _groups[index] = group.copyWith(name: name, color: selectedColor);
                      }
                    });
                    await _storage.saveGroups(_groups);
                    Navigator.pop(dialogContext);
                  },
                  child: Text(t('save'), style: TextStyle(color: _colors.primaryColor)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddDialog(String groupId) async {
    final nameController = TextEditingController();
    final accountController = TextEditingController();
    final passwordController = TextEditingController();
    final notesController = TextEditingController();
    bool passwordVisible = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _colors.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                t('add_password'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _colors.textColor),
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
                      obscureText: !passwordVisible,
                      decoration: InputDecoration(
                        labelText: t('password_field'),
                        filled: true,
                        fillColor: const Color(0xFF21262D),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(passwordVisible ? Icons.visibility_off : Icons.visibility, color: _colors.subtextColor),
                          onPressed: () {
                            setDialogState(() => passwordVisible = !passwordVisible);
                          },
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(t('cancel'), style: TextStyle(color: _colors.subtextColor)),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      _showSnackBar('Name is required');
                      return;
                    }
                    final newEntry = PasswordEntry(
                      name: name,
                      account: accountController.text.trim(),
                      password: passwordController.text.trim(),
                      notes: notesController.text.trim(),
                      groupId: groupId,
                    );
                    setState(() {
                      _passwords.insert(0, newEntry);
                    });
                    await _savePasswords();
                    Navigator.pop(dialogContext);
                  },
                  child: Text(t('save'), style: TextStyle(color: _colors.primaryColor)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditDialog(PasswordEntry entry) async {
    final nameController = TextEditingController(text: entry.name);
    final accountController = TextEditingController(text: entry.account);
    final passwordController = TextEditingController(text: entry.password);
    final notesController = TextEditingController(text: entry.notes);
    bool passwordVisible = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _colors.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                t('edit_password'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _colors.textColor),
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
                      obscureText: !passwordVisible,
                      decoration: InputDecoration(
                        labelText: t('password_field'),
                        filled: true,
                        fillColor: const Color(0xFF21262D),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(passwordVisible ? Icons.visibility_off : Icons.visibility, color: _colors.subtextColor),
                          onPressed: () {
                            setDialogState(() => passwordVisible = !passwordVisible);
                          },
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(t('cancel'), style: TextStyle(color: _colors.subtextColor)),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      _showSnackBar('Name is required');
                      return;
                    }
                    setState(() {
                      entry.name = name;
                      entry.account = accountController.text.trim();
                      entry.password = passwordController.text.trim();
                      entry.notes = notesController.text.trim();
                    });
                    await _savePasswords();
                    Navigator.pop(dialogContext);
                  },
                  child: Text(t('save'), style: TextStyle(color: _colors.primaryColor)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteDialog(List<PasswordEntry> entries) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _colors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('confirm_delete'),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _colors.textColor),
        ),
        content: Text(
          entries.length > 1 ? 'Delete ${entries.length} items?' : t('delete_message'),
          style: TextStyle(fontSize: 15, color: _colors.subtextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t('cancel'), style: TextStyle(color: _colors.subtextColor)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() {
                for (final entry in entries) {
                  _passwords.remove(entry);
                }
              });
              await _savePasswords();
            },
            child: Text(t('delete'), style: TextStyle(color: _colors.dangerColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetailDialog(PasswordEntry entry) async {
    bool passwordVisible = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
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
                  Flexible(
                    child: Text(
                      entry.name,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _colors.textColor),
                      softWrap: true,
                      maxLines: 3,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: _colors.dangerColor),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _showDeleteDialog([entry]);
                    },
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow(t('account'), entry.account),
                  const SizedBox(height: 16),
                  _detailRowWithToggle(t('password'), entry.password, passwordVisible, (visible) {
                    setDialogState(() => passwordVisible = visible);
                  }),
                  if (entry.notes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _detailRow(t('notes'), entry.notes),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(t('close'), style: TextStyle(color: _colors.subtextColor)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _showEditDialog(entry);
                  },
                  child: Text(t('edit'), style: TextStyle(color: _colors.primaryColor)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: _colors.subtextColor)),
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
        Flexible(
          child: Text(
            value.isEmpty ? '-' : value,
            style: TextStyle(fontSize: 15, color: _colors.textColor),
            softWrap: true,
            maxLines: 10,
          ),
        ),
      ],
    );
  }

  Widget _detailRowWithToggle(String label, String value, bool isVisible, Function(bool) onToggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: _colors.subtextColor)),
            const Spacer(),
            IconButton(
              icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility, size: 18, color: _colors.subtextColor),
              onPressed: () => onToggle(!isVisible),
            ),
            IconButton(
              icon: Icon(Icons.copy, size: 18, color: _colors.subtextColor),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                _showSnackBar('$label ${t('copied')}');
              },
            ),
          ],
        ),
        Flexible(
          child: Text(
            value.isEmpty ? '-' : (isVisible ? value : '••••••••'),
            style: TextStyle(fontSize: 15, color: _colors.textColor),
            softWrap: true,
            maxLines: 10,
          ),
        ),
      ],
    );
  }

  Future<void> _showSettingsDialog() async {
    String tempTheme = _themeSetting;
    String tempLang = _langSetting;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = tempTheme == 'system'
                ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
                : (tempTheme == 'dark' || _colorThemes.containsKey(tempTheme));
            final textColor = isDark ? _colors.textColor : const Color(0xFF212121);

            return AlertDialog(
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
                        value: tempTheme,
                        dropdownColor: _colors.cardColor,
                        items: [
                          DropdownMenuItem(value: 'system', child: Text(t('follow_system'), style: TextStyle(color: textColor))),
                          DropdownMenuItem(value: 'dark', child: Text(t('dark'), style: TextStyle(color: textColor))),
                          DropdownMenuItem(value: 'light', child: Text(t('light'), style: TextStyle(color: textColor))),
                          ..._colorThemes.entries.map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value['name'] ?? e.key, style: TextStyle(color: textColor)),
                          )),
                        ],
                        onChanged: (value) async {
                          if (value != null) {
                            tempTheme = value;
                            _themeSetting = value;
                            _updateThemeMode();
                            _setupColors();
                            setDialogState(() {});
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
                        value: tempLang,
                        dropdownColor: _colors.cardColor,
                        items: _languages.entries.map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value['name'] ?? e.key, style: TextStyle(color: textColor)),
                        )).toList(),
                        onChanged: (value) async {
                          if (value != null) {
                            tempLang = value;
                            _langSetting = value;
                            setDialogState(() {});
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _exportData,
                    child: Text(t('export'), style: TextStyle(color: _colors.primaryColor)),
                  ),
                  TextButton(
                    onPressed: _importData,
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
            );
          },
        );
      },
    );
  }

  Future<void> _exportData() async {
    Navigator.pop(context);

    if (_passwords.isEmpty) {
      _showSnackBar(t('no_passwords'));
      return;
    }

    try {
      final jsonContent = await _storage.exportData(_passwords, _groups);
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
        _showSnackBar(t('export_success'));
      }
    } catch (e) {
      _showSnackBar('${t('export_failed')}: $e');
    }
  }

  Future<void> _importData() async {
    Navigator.pop(context);

    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: t('select_file'),
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final content = utf8.decode(result.files.single.bytes!);
        final imported = await _storage.importData(content);

        if (imported.passwords.isEmpty) {
          _showSnackBar(t('import_failed'));
          return;
        }

        setState(() {
          _passwords.addAll(imported.passwords);
          for (final g in imported.groups) {
            if (!_groups.any((existing) => existing.id == g.id)) {
              _groups.add(g);
            }
          }
        });
        await _savePasswords();
        await _storage.saveGroups(_groups);
        _showSnackBar('${t('import_success')}: ${imported.passwords.length} passwords, ${imported.groups.length} groups');
      }
    } catch (e) {
      _showSnackBar('${t('import_failed')}: $e');
    }
  }

  Future<void> _showImportFromGroupDialog(String targetGroupId) async {
    final otherGroups = _groups.where((g) => g.id != targetGroupId).toList();
    if (otherGroups.isEmpty) {
      _showSnackBar('No other groups available');
      return;
    }

    String? selectedGroupId;
    List<PasswordEntry> sourcePasswords = [];
    List<bool> selectedStates = [];

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _colors.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                t('select_import_mode'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _colors.textColor),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select source group:', style: TextStyle(fontSize: 14, color: _colors.subtextColor)),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: selectedGroupId,
                      isExpanded: true,
                      dropdownColor: _colors.cardColor,
                      hint: Text('Select group', style: TextStyle(color: _colors.subtextColor)),
                      items: otherGroups.map((g) => DropdownMenuItem(
                        value: g.id,
                        child: Text(g.name, style: TextStyle(color: _colors.textColor)),
                      )).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedGroupId = value;
                          sourcePasswords = _getPasswordsByGroup(value ?? '');
                          selectedStates = List.filled(sourcePasswords.length, false);
                        });
                      },
                    ),
                    if (sourcePasswords.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text('Select passwords:', style: TextStyle(fontSize: 14, color: _colors.subtextColor)),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                final allSelected = selectedStates.every((s) => s);
                                for (int i = 0; i < selectedStates.length; i++) {
                                  selectedStates[i] = !allSelected;
                                }
                              });
                            },
                            child: Text(
                              selectedStates.every((s) => s) ? 'Deselect All' : 'Select All',
                              style: TextStyle(fontSize: 12, color: _colors.primaryColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: sourcePasswords.length,
                          itemBuilder: (context, index) {
                            final p = sourcePasswords[index];
                            return CheckboxListTile(
                              value: selectedStates[index],
                              title: Text(p.name, style: TextStyle(color: _colors.textColor)),
                              onChanged: (checked) {
                                setDialogState(() {
                                  selectedStates[index] = checked ?? false;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(t('cancel'), style: TextStyle(color: _colors.subtextColor)),
                ),
                ElevatedButton(
                  onPressed: selectedGroupId != null && selectedStates.any((s) => s)
                      ? () async {
                          setState(() {
                            for (int i = 0; i < selectedStates.length; i++) {
                              if (selectedStates[i]) {
                                sourcePasswords[i].groupId = targetGroupId;
                              }
                            }
                          });
                          await _savePasswords();
                          Navigator.pop(dialogContext);
                          _showSnackBar('Imported ${selectedStates.where((s) => s).length} passwords');
                        }
                      : null,
                  style: ElevatedButton.styleFrom(backgroundColor: _colors.primaryColor),
                  child: Text(t('confirm')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showMoveDialog(List<PasswordEntry> entries, {VoidCallback? onMoved}) async {
    String? selectedGroupId;
    bool createNew = false;
    final newGroupNameController = TextEditingController();
    String newGroupColor = groupColors[0];

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _colors.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Move passwords',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _colors.textColor),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        value: createNew,
                        title: Text('Create new group', style: TextStyle(color: _colors.textColor)),
                        onChanged: (v) => setDialogState(() => createNew = v ?? false),
                      ),
                      if (createNew) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: newGroupNameController,
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
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: groupColors.map((color) {
                            final isSelected = color == newGroupColor;
                            return GestureDetector(
                              onTap: () => setDialogState(() => newGroupColor = color),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                                  shape: BoxShape.circle,
                                  border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        DropdownButton<String>(
                          value: selectedGroupId,
                          isExpanded: true,
                          dropdownColor: _colors.cardColor,
                          hint: Text('Select target group', style: TextStyle(color: _colors.subtextColor)),
                          items: _groups.map((g) => DropdownMenuItem(
                            value: g.id,
                            child: Text(g.name, style: TextStyle(color: _colors.textColor)),
                          )).toList(),
                          onChanged: (value) => setDialogState(() => selectedGroupId = value),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(t('cancel'), style: TextStyle(color: _colors.subtextColor)),
                ),
                ElevatedButton(
                  onPressed: (createNew && newGroupNameController.text.trim().isNotEmpty) ||
                          (!createNew && selectedGroupId != null)
                      ? () async {
                          String targetGroupId;
                          if (createNew) {
                            final newGroup = PasswordGroup(
                              name: newGroupNameController.text.trim(),
                              color: newGroupColor,
                            );
                            _groups.add(newGroup);
                            await _storage.saveGroups(_groups);
                            targetGroupId = newGroup.id;
                          } else {
                            targetGroupId = selectedGroupId!;
                          }
                          setState(() {
                            for (final entry in entries) {
                              entry.groupId = targetGroupId;
                            }
                          });
                          await _savePasswords();
                          Navigator.pop(dialogContext);
                          onMoved?.call();
                          _showSnackBar('Moved ${entries.length} passwords');
                        }
                      : null,
                  style: ElevatedButton.styleFrom(backgroundColor: _colors.primaryColor),
                  child: Text(t('confirm')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGroupsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 50, bottom: 12),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearch,
            style: TextStyle(color: _colors.textColor, fontSize: 15),
            decoration: InputDecoration(
              hintText: t('search_hint'),
              hintStyle: TextStyle(color: _colors.subtextColor, fontSize: 15),
              prefixIcon: Icon(Icons.search, color: _colors.subtextColor, size: 22),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: _colors.subtextColor, size: 22),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: _colors.cardColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (_searchQuery.isNotEmpty)
          Expanded(child: _buildSearchResults())
        else
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: _groups.length + 1,
              itemBuilder: (context, index) {
                if (index == _groups.length) {
                  return _buildAddGroupCard();
                }
                return _buildGroupCard(_groups[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSearchResults() {
    final results = _getFilteredPasswords();
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: _colors.subtextColor),
            const SizedBox(height: 8),
            Text(
              t('no_passwords'),
              style: TextStyle(fontSize: 18, color: _colors.subtextColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final p = results[index];
        final group = _groups.firstWhere(
          (g) => g.id == p.groupId,
          orElse: () => _groups.first,
        );
        return GestureDetector(
          onTap: () => _showDetailDialog(p),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _colors.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
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
                      const SizedBox(height: 4),
                      Text(
                        p.account.isEmpty ? 'No account' : p.account,
                        style: TextStyle(fontSize: 13, color: _colors.subtextColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(int.parse(group.color.replaceFirst('#', '0xFF'))).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    group.name,
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(int.parse(group.color.replaceFirst('#', '0xFF'))),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupCard(PasswordGroup group) {
    final count = _getGroupPasswordCount(group.id);
    final groupColor = Color(int.parse(group.color.replaceFirst('#', '0xFF')));

    return GestureDetector(
      onTap: () => _navigateToGroupDetail(group),
      onLongPress: group.id != 'default' ? () => _showGroupOptionsDialog(group) : null,
      child: Container(
        decoration: BoxDecoration(
          color: _colors.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: groupColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(Icons.folder, color: groupColor, size: 28),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              group.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _colors.textColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                color: _colors.subtextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddGroupCard() {
    return GestureDetector(
      onTap: _showAddGroupDialog,
      child: Container(
        decoration: BoxDecoration(
          color: _colors.cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _colors.subtextColor, width: 2, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: _colors.subtextColor, size: 40),
            const SizedBox(height: 8),
            Text(
              t('add_password'),
              style: TextStyle(
                fontSize: 12,
                color: _colors.subtextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToGroupDetail(PasswordGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailPage(
          group: group,
          allPasswords: _passwords,
          allGroups: _groups,
          colors: _colors,
          t: t,
          onAdd: () => _showAddDialog(group.id),
          onImport: () => _showImportFromGroupDialog(group.id),
          onEdit: _showEditDialog,
          onDelete: _showDeleteDialog,
          onDetail: _showDetailDialog,
          onMove: (entries) => _showMoveDialog(entries, onMoved: () {
            setState(() {});
          }),
          onRefresh: () {
            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _colors.bgColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _colors.bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(
              index: _currentTab,
              children: [
                _buildGroupsPage(),
                _buildBankCardsPage(),
              ],
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: _colors.cardColor,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDockItem(Icons.settings, -1),
                      _buildDockItem(Icons.lock, 0),
                      _buildDockItem(Icons.credit_card, 1),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockItem(IconData icon, int index) {
    final isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () {
        if (index == -1) {
          _showSettingsDialog();
        } else {
          setState(() => _currentTab = index);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _colors.primaryColor.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: isSelected ? _colors.primaryColor : _colors.subtextColor,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildBankCardsPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card, size: 64, color: _colors.subtextColor),
          const SizedBox(height: 16),
          Text('Bank Cards (Coming Soon)', style: TextStyle(fontSize: 18, color: _colors.subtextColor)),
        ],
      ),
    );
  }
}

class GroupDetailPage extends StatefulWidget {
  final PasswordGroup group;
  final List<PasswordEntry> allPasswords;
  final List<PasswordGroup> allGroups;
  final AppColors colors;
  final String Function(String) t;
  final VoidCallback onAdd;
  final VoidCallback onImport;
  final Function(PasswordEntry) onEdit;
  final Function(List<PasswordEntry>) onDelete;
  final Function(PasswordEntry) onDetail;
  final Function(List<PasswordEntry>) onMove;
  final VoidCallback onRefresh;

  const GroupDetailPage({
    super.key,
    required this.group,
    required this.allPasswords,
    required this.allGroups,
    required this.colors,
    required this.t,
    required this.onAdd,
    required this.onImport,
    required this.onEdit,
    required this.onDelete,
    required this.onDetail,
    required this.onMove,
    required this.onRefresh,
  });

  List<PasswordEntry> get passwords => allPasswords.where((p) => p.groupId == group.id).toList();

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> with WidgetsBindingObserver {
  bool _isSelectionMode = false;
  List<bool> _selectedStates = [];
  List<PasswordEntry> _currentPasswords = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentPasswords = widget.passwords;
    _selectedStates = List.filled(_currentPasswords.length, false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(GroupDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.passwords != widget.passwords) {
      _currentPasswords = widget.passwords;
      _selectedStates = List.filled(_currentPasswords.length, false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _currentPasswords = widget.passwords;
        _selectedStates = List.filled(_currentPasswords.length, false);
      });
    }
  }

  void _updateSelectionStates() {
    final newStates = List.filled(_currentPasswords.length, false);
    for (int i = 0; i < _selectedStates.length && i < newStates.length; i++) {
      newStates[i] = _selectedStates[i];
    }
    _selectedStates = newStates;
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedStates.where((s) => s).length;

    return Scaffold(
      backgroundColor: widget.colors.bgColor,
      appBar: AppBar(
        backgroundColor: widget.colors.bgColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.colors.textColor),
          onPressed: () {
            widget.onRefresh();
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.group.name,
          style: TextStyle(color: widget.colors.textColor),
        ),
        actions: [
          if (_isSelectionMode && selectedCount > 0) ...[
            IconButton(
              icon: Icon(Icons.drive_file_move, color: widget.colors.primaryColor),
              onPressed: () {
                final selectedPasswords = <PasswordEntry>[];
                for (int i = 0; i < _selectedStates.length; i++) {
                  if (_selectedStates[i]) {
                    selectedPasswords.add(widget.passwords[i]);
                  }
                }
                widget.onMove(selectedPasswords);
                setState(() {
                  _currentPasswords = widget.passwords;
                  _isSelectionMode = false;
                  _selectedStates = List.filled(_currentPasswords.length, false);
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: widget.colors.dangerColor),
              onPressed: () {
                final selectedPasswords = <PasswordEntry>[];
                for (int i = 0; i < _selectedStates.length; i++) {
                  if (_selectedStates[i]) {
                    selectedPasswords.add(widget.passwords[i]);
                  }
                }
                widget.onDelete(selectedPasswords);
                setState(() {
                  _currentPasswords = widget.passwords;
                  _isSelectionMode = false;
                  _selectedStates = List.filled(_currentPasswords.length, false);
                });
              },
            ),
          ],
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.close : Icons.checklist, color: widget.colors.subtextColor),
            onPressed: () {
              setState(() {
                _isSelectionMode = !_isSelectionMode;
                if (!_isSelectionMode) {
                  _updateSelectionStates();
                }
              });
            },
          ),
        ],
      ),
      body: _currentPasswords.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.key, size: 64, color: widget.colors.subtextColor),
                  const SizedBox(height: 8),
                  Text(
                    widget.t('no_passwords'),
                    style: TextStyle(fontSize: 18, color: widget.colors.subtextColor),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (_isSelectionMode)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          '$selectedCount selected',
                          style: TextStyle(color: widget.colors.subtextColor),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              final allSelected = _selectedStates.every((s) => s);
                              for (int i = 0; i < _selectedStates.length; i++) {
                                _selectedStates[i] = !allSelected;
                              }
                            });
                          },
                          child: Text(
                            _selectedStates.every((s) => s) ? 'Deselect All' : 'Select All',
                            style: TextStyle(fontSize: 12, color: widget.colors.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _currentPasswords.length,
                    itemBuilder: (context, index) {
                      final p = _currentPasswords[index];
                      final isSelected = _selectedStates[index];
                      return _buildPasswordCard(p, index, isSelected);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: _isSelectionMode
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'import',
                  onPressed: widget.onImport,
                  backgroundColor: widget.colors.accentColor,
                  child: const Icon(Icons.file_copy, color: Colors.white),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'add',
                  onPressed: widget.onAdd,
                  backgroundColor: widget.colors.primaryColor,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
    );
  }

  Widget _buildPasswordCard(PasswordEntry p, int index, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            _selectedStates[index] = !_selectedStates[index];
          });
        } else {
          widget.onDetail(p);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
            _selectedStates[index] = true;
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected
              ? widget.colors.primaryColor.withValues(alpha: 0.2)
              : widget.colors.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (_isSelectionMode)
              Checkbox(
                value: isSelected,
                onChanged: (v) {
                  setState(() {
                    _selectedStates[index] = v ?? false;
                  });
                },
              ),
            CircleAvatar(
              backgroundColor: widget.colors.primaryColor,
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
                      color: widget.colors.textColor,
                    ),
                  ),
                  Text(
                    p.account.isEmpty ? 'No account' : p.account,
                    style: TextStyle(fontSize: 13, color: widget.colors.subtextColor),
                  ),
                ],
              ),
            ),
            if (!_isSelectionMode) ...[
              IconButton(
                icon: Icon(Icons.edit, color: widget.colors.subtextColor),
                onPressed: () => widget.onEdit(p),
              ),
            ],
          ],
        ),
      ),
    );
  }
}