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

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.roles = const [],
    this.avatarUrl,
    this.phone,
    this.organization,
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}';

  bool get isAdmin => roles.contains('ADMIN');
  bool get isManager => roles.contains('MANAGER');

  @override
  List<Object?> get props => [id, email, firstName, lastName, roles];
}
