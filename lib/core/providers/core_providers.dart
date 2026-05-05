import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../database/isar_service.dart';

/// Provider principal do ISAR — usado por todos os outros providers
final isarProvider = Provider<Isar>((ref) {
  return IsarService.instance;
});
