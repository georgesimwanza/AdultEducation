import 'package:sqflite/sqflite.dart';

/// The signed-in user's details, stored locally so pages can load them
/// instantly (and offline).
///
/// Save as: lib/service/user_profile_service.dart
class UserProfile {
  final int? serverId;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? role; // e.g. USER / ADMIN
  final int? institutionId;
  final int? programmeId;

  /// false = edited on this device and not yet pushed to the server.
  final bool synced;

  const UserProfile({
    this.serverId,
    required this.email,
    this.firstName = '',
    this.lastName = '',
    this.phone,
    this.role,
    this.institutionId,
    this.programmeId,
    this.synced = true,
  });

  String get fullName => '$firstName $lastName'.trim();

  bool get isAdmin => (role ?? '').toUpperCase().contains('ADMIN');

  /// Up to two initials: from the name if we have one, else from the email.
  String get initials {
    final name = fullName;
    if (name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.length == 1) return parts.first[0].toUpperCase();
      return (parts.first[0] + parts.last[0]).toUpperCase();
    }
    final local = email.split('@').first;
    final parts =
    local.split(RegExp(r'[._\-\s]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  UserProfile copyWith({
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    bool? synced,
  }) {
    return UserProfile(
      serverId: serverId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      role: role,
      institutionId: institutionId,
      programmeId: programmeId,
      synced: synced ?? this.synced,
    );
  }

  /// Tolerant of different key spellings and nested objects, so a small
  /// difference in the backend response doesn't break the sync.
  factory UserProfile.fromServerJson(Map<String, dynamic> j) {
    int? asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');
    dynamic pick(List<String> keys) {
      for (final k in keys) {
        if (j[k] != null) return j[k];
      }
      return null;
    }

    final institution = j['institution'];
    final programme = j['programme'];

    return UserProfile(
      serverId: asInt(j['id']),
      email: (pick(['email']) ?? '').toString(),
      firstName: (pick(['firstName', 'first_name']) ?? '').toString(),
      lastName: (pick(['lastName', 'last_name']) ?? '').toString(),
      phone: pick(['phone', 'phoneNumber', 'phone_number'])?.toString(),
      role: pick(['role'])?.toString(),
      institutionId: asInt(j['institutionId']) ??
          (institution is Map ? asInt(institution['id']) : null),
      programmeId: asInt(j['programmeId']) ??
          (programme is Map ? asInt(programme['id']) : null),
      synced: true,
    );
  }

  Map<String, Object?> toMap() => {
    'localId': 1, // only one user is ever stored on a device
    'serverId': serverId,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'role': role,
    'institutionId': institutionId,
    'programmeId': programmeId,
    'synced': synced ? 1 : 0,
    'updatedAt': DateTime.now().millisecondsSinceEpoch,
  };

  factory UserProfile.fromMap(Map<String, Object?> m) => UserProfile(
    serverId: m['serverId'] as int?,
    email: (m['email'] as String?) ?? '',
    firstName: (m['firstName'] as String?) ?? '',
    lastName: (m['lastName'] as String?) ?? '',
    phone: m['phone'] as String?,
    role: m['role'] as String?,
    institutionId: m['institutionId'] as int?,
    programmeId: m['programmeId'] as int?,
    synced: (m['synced'] as int? ?? 1) == 1,
  );
}

/// Reads and writes the signed-in user's details in the local database.
class UserProfileService {
  final Database? db;
  const UserProfileService({required this.db});

  static const String table = 'user_profile';

  /// SQL used by SyncService when it creates the table.
  static const String createSql = '''
    CREATE TABLE IF NOT EXISTS user_profile (
      localId INTEGER PRIMARY KEY,
      serverId INTEGER,
      email TEXT,
      firstName TEXT,
      lastName TEXT,
      phone TEXT,
      role TEXT,
      institutionId INTEGER,
      programmeId INTEGER,
      synced INTEGER DEFAULT 1,
      updatedAt INTEGER
    )
  ''';

  /// The stored profile, or null if none has been saved yet.
  Future<UserProfile?> getCurrent() async {
    final d = db;
    if (d == null) return null;
    try {
      final rows = await d.query(table, where: 'localId = 1', limit: 1);
      if (rows.isEmpty) return null;
      return UserProfile.fromMap(rows.first);
    } catch (_) {
      return null; // table missing on an old DB, etc.
    }
  }

  /// Save an edit made on this device. Marks it as not yet synced.
  Future<void> saveLocalEdit(UserProfile profile) async {
    final d = db;
    if (d == null) return;
    await d.insert(
      table,
      profile.copyWith(synced: false).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Save what the server returned. Never overwrites a local edit that
  /// hasn't been pushed to the server yet.
  Future<void> saveFromServer(UserProfile profile) async {
    final d = db;
    if (d == null) return;
    final existing = await getCurrent();
    if (existing != null && !existing.synced) return;
    await d.insert(
      table,
      profile.copyWith(synced: true).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Store just the email (used as a fallback when the server can't be
  /// reached), so pages still have something to show.
  Future<void> seedIfEmpty(String email) async {
    if (email.isEmpty) return;
    if (await getCurrent() != null) return;
    await db?.insert(
      table,
      UserProfile(email: email).toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Remove the stored profile (call on logout).
  Future<void> clear() async {
    await db?.delete(table);
  }
}