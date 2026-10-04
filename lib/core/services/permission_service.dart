import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';

class PermissionStatusReport {
  final bool notifications;
  final bool exactAlarms;

  const PermissionStatusReport({
    required this.notifications,
    required this.exactAlarms,
  });

  bool get allGranted => notifications && exactAlarms;
}

/// Centraliza a verificação e solicitação de permissões críticas de notificação
/// e alarme no Android/iOS usando apenas flutter_local_notifications (sem pacotes extras).
class PermissionService {
  PermissionService._();

  static AndroidFlutterLocalNotificationsPlugin? get _androidPlugin =>
      NotificationService.instance.plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

  static IOSFlutterLocalNotificationsPlugin? get _iosPlugin =>
      NotificationService.instance.plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

  /// Verifica se notificações em geral estão habilitadas
  static Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      return await _androidPlugin?.areNotificationsEnabled() ?? true;
    }
    return true;
  }

  /// Solicita permissão de notificações (POST_NOTIFICATIONS no Android 13+)
  static Future<bool> requestNotifications() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      return await _androidPlugin?.requestNotificationsPermission() ?? false;
    } else if (Platform.isIOS) {
      return await _iosPlugin?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return true;
  }

  /// Verifica se o agendamento exato de alarmes é permitido
  static Future<bool> canScheduleExactAlarms() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    return await _androidPlugin?.canScheduleExactNotifications() ?? true;
  }

  /// Solicita permissão de alarmes exatos (abre tela do sistema se necessário no Android 12)
  static Future<bool> requestExactAlarms() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    return await _androidPlugin?.requestExactAlarmsPermission() ?? false;
  }

  /// Solicita permissão para alarme em tela cheia (Android 14+)
  static Future<bool> requestFullScreenIntent() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    return await _androidPlugin?.requestFullScreenIntentPermission() ?? false;
  }

  /// Retorna o status de todas as permissões críticas
  static Future<PermissionStatusReport> checkAll() async {
    final notif = await areNotificationsEnabled();
    final exact = await canScheduleExactAlarms();
    return PermissionStatusReport(
      notifications: notif,
      exactAlarms: exact,
    );
  }
}
