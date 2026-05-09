class PasswordGroup {
  final String id;
  String name;
  String color;
  final String createdAt;

  PasswordGroup({
    String? id,
    required this.name,
    this.color = '#58A6FF',
    String? createdAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toDict() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'created_at': createdAt,
    };
  }

  factory PasswordGroup.fromDict(Map<String, dynamic> d) {
    return PasswordGroup(
      id: d['id']?.toString(),
      name: d['name'] as String? ?? '',
      color: d['color'] as String? ?? '#58A6FF',
      createdAt: d['created_at'] as String?,
    );
  }

  PasswordGroup copyWith({
    String? id,
    String? name,
    String? color,
    String? createdAt,
  }) {
    return PasswordGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PasswordEntry {
  final double id;
  String name;
  String account;
  String password;
  String notes;
  final String createdAt;
  String groupId;

  PasswordEntry({
    double? id,
    required this.name,
    this.account = "",
    this.password = "",
    this.notes = "",
    String? createdAt,
    this.groupId = '',
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch / 1000.0,
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toDict() {
    return {
      'id': id,
      'name': name,
      'account': account,
      'password': password,
      'notes': notes,
      'created_at': createdAt,
      'group_id': groupId,
    };
  }

  factory PasswordEntry.fromDict(Map<String, dynamic> d) {
    return PasswordEntry(
      id: (d['id'] as num?)?.toDouble(),
      name: d['name'] as String? ?? '',
      account: d['account'] as String? ?? '',
      password: d['password'] as String? ?? '',
      notes: d['notes'] as String? ?? '',
      createdAt: d['created_at'] as String?,
      groupId: d['group_id']?.toString() ?? '',
    );
  }

  PasswordEntry copyWith({
    double? id,
    String? name,
    String? account,
    String? password,
    String? notes,
    String? createdAt,
    String? groupId,
  }) {
    return PasswordEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      account: account ?? this.account,
      password: password ?? this.password,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      groupId: groupId ?? this.groupId,
    );
  }
}