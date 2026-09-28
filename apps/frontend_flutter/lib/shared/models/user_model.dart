import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final List<String> roles;
  final String? avatarUrl;
  final String? phone;
  final String? organization;
  final String locale;
  final String timezone;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.roles = const [],
    this.avatarUrl,
    this.phone,
    this.organization,
    this.locale = 'fr_FR',
    this.timezone = 'Europe/Paris',
  });

  String get fullName => '$firstName $lastName';

  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}';

  bool get isAdmin => roles.contains('ADMIN');
  bool get isManager => roles.contains('MANAGER');

  /// Human-readable label for the UI (avoids showing raw "USER").
  String get roleLabel {
    if (isAdmin) return 'Administrateur';
    if (isManager) return 'Manager';
    return 'Membre';
  }

  static String normalizeLocale(String raw) {
    final compact = raw.replaceAll('-', '_');
    final lower = compact.toLowerCase();
    if (lower.startsWith('fr')) return 'fr_FR';
    if (lower.startsWith('en')) return 'en_US';
    return compact;
  }

  String get localeLabel => switch (normalizeLocale(locale)) {
        'en_US' => 'English (US)',
        'fr_FR' => 'Français',
        _ => locale,
      };

  String get timezoneLabel => timezone.replaceAll('_', ' ');

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    List<String>? roles,
    String? avatarUrl,
    String? phone,
    String? organization,
    String? locale,
    String? timezone,
    bool clearPhone = false,
    bool clearOrganization = false,
    bool clearAvatarUrl = false,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      roles: roles ?? this.roles,
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
      phone: clearPhone ? null : (phone ?? this.phone),
      organization: clearOrganization ? null : (organization ?? this.organization),
      locale: locale ?? this.locale,
      timezone: timezone ?? this.timezone,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String? ?? json['sub'] as String? ?? '',
        email: json['email'] as String? ?? '',
        firstName: json['first_name'] as String? ?? json['given_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? json['family_name'] as String? ?? '',
        roles: List<String>.from(json['roles'] as List? ?? const []),
        avatarUrl: json['avatar_url'] as String?,
        phone: json['phone'] as String?,
        organization: json['organization'] as String?,
        locale: normalizeLocale(json['locale'] as String? ?? 'fr_FR'),
        timezone: json['timezone'] as String? ?? 'Europe/Paris',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'roles': roles,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (phone != null) 'phone': phone,
        if (organization != null) 'organization': organization,
        'locale': locale.replaceAll('_', '-'),
        'timezone': timezone,
      };

  /// Body for PUT /users/me. `phone: null` clears the phone.
  Map<String, dynamic> toProfileUpdateJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'organization': organization,
        'locale': locale.replaceAll('_', '-'),
        'timezone': timezone,
      };

  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        roles,
        avatarUrl,
        phone,
        organization,
        locale,
        timezone,
      ];
}
