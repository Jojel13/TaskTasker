/// Cor da task — define comportamento de propagação e notificação
enum TaskColor { standard, blue, yellow, red }

/// Status atual da task
enum TaskStatus { active, completed, scheduled, archived }

/// Divisão da rotina
enum DivisionType { morning, afternoon, night, tomorrow }

/// Frequência de repetição (tasks azuis)
enum FrequencyType { daily, everyOtherDay, custom }

extension FrequencyTypeExtension on FrequencyType {
  String get label {
    switch (this) {
      case FrequencyType.daily:
        return 'Diário';
      case FrequencyType.everyOtherDay:
        return 'Dias alternados';
      case FrequencyType.custom:
        return 'Personalizado';
    }
  }
}

/// Tema do aplicativo
enum AppThemeType {
  cyberpunkDark,
  light, // Para futura expansão
}
