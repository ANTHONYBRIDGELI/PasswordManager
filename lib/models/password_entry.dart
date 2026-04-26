class PasswordEntry {
  final double id;
  String name;
  String account;
  String password;
  String notes;
  final String createdAt;

  PasswordEntry({
    double? id,
    required this.name,
    this.account = "",
    this.password = "",
    this.notes = "",
    String? createdAt,
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
    );
  }

  PasswordEntry copyWith({
    double? id,
    String? name,
    String? account,
    String? password,
    String? notes,
    String? createdAt,
  }) {
    return PasswordEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      account: account ?? this.account,
      password: password ?? this.password,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}