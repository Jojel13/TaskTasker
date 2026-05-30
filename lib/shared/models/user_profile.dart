import 'package:isar/isar.dart';
import 'enums.dart';

part 'user_profile.g.dart';

/// Singleton do perfil do usuário (id fixo = 1)
@Collection()
class UserProfile {
  Id id = 1;

  String routineName = 'Minha Rotina';
  int totalXP = 0;
  int currentLevel = 1;
  int streakDays = 0;
  int streakRecord = 0;
  DateTime? lastOpenedDate;
  DateTime? lastRoutineDate; // Data da última rotina criada

  // ─── Nomes customizáveis das divisões ────────────────────────
  String divisionMorningName   = 'Manhã';
  String divisionAfternoonName = 'Tarde';
  String divisionNightName     = 'Noite';
  String divisionTomorrowName  = 'Para Amanhã';

  // ─── Configurações de notificação (minutos antes da divisão) ─
  int notifMorningOffsetMin   = 0; // às 07:00
  int notifAfternoonOffsetMin = 0; // às 13:00
  int notifNightOffsetMin     = 0; // às 19:00
  
  int notificationFrequencyHours = 6; // Frequência do Workmanager

  @enumerated
  AppThemeType appTheme = AppThemeType.cyberpunkDark;

  // ─── Novas Configurações (Notificações & Tema) ───────────────
  bool notifEnabled = true;
  bool alarmSoundEnabled = true;
  bool brightnessOverride = false;
  bool useBrightnessOverride = false;
}
