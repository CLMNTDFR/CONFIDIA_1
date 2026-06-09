import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'email_model.dart';

enum AccountSyncStatus { connected, syncing, error }

class ConnectedAccountModel extends Equatable {
  final String id;
  final MailProvider provider;
  final String email;
  final AccountSyncStatus status;
  final DateTime lastSync;
  final String dataVolume;
  final int documentsImported;
  final int emailsSynced;

  const ConnectedAccountModel({
    required this.id,
    required this.provider,
    required this.email,
    required this.status,
    required this.lastSync,
    required this.dataVolume,
    required this.documentsImported,
    required this.emailsSynced,
  });

  @override
  List<Object?> get props => [id, provider, email];
}

class StorageServiceModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool connected;
  final String storageUsed;
  final String storageTotal;
  final DateTime lastSync;

  const StorageServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.connected,
    required this.storageUsed,
    required this.storageTotal,
    required this.lastSync,
  });

  double get usageRatio {
    final used = double.tryParse(storageUsed.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final total = double.tryParse(storageTotal.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 1;
    return (used / total).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [id, connected];
}
