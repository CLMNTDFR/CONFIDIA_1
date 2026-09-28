import 'dart:io';

import 'package:flutter/foundation.dart';

bool get _savesToDownloads => defaultTargetPlatform == TargetPlatform.macOS;

bool get blobActionsSupported => _savesToDownloads;

void downloadBytes(List<int> bytes, String filename, String mimeType) {
  if (!_savesToDownloads) return;
  final home = Platform.environment['HOME'];
  if (home == null || home.isEmpty) return;
  final downloads = Directory('$home/Downloads');
  if (!downloads.existsSync()) return;
  final safe = filename.replaceAll(RegExp(r'[/\\]'), '_');
  File('${downloads.path}/$safe').writeAsBytesSync(bytes);
}

void openBytes(List<int> bytes, String filename, String mimeType) {}
