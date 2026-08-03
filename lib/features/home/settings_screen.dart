import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clipboard/clipboard.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/theme_config.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/enums.dart';
import '../../core/services/notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final GlobalKey<FormState> _formKey;
  
  late TextEditingController _routineNameCtrl;
  late TextEditingController _morningCtrl;
  late TextEditingController _afternoonCtrl;
  late TextEditingController _nightCtrl;
  late TextEditingController _tomorrowCtrl;
  
  double _notificationFrequency = 6;
  bool _isBackupLoading = false;
  AppThemeType _selectedTheme = AppThemeType.cyberpunkDark;
  bool _notifEnabled = true;
  bool _alarmSoundEnabled = true;
  bool _useBrightnessOverride = false;
  bool _brightnessOverride = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _routineNameCtrl = TextEditingController();
    _morningCtrl = TextEditingController();
    _afternoonCtrl = TextEditingController();
    _nightCtrl = TextEditingController();
    _tomorrowCtrl = TextEditingController();

    // AVISO-04: usar addPostFrameCallback para garantir que o userProfileProvider
    // j\u00e1 emitiu um valor antes de popular os campos de texto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadProfileData();
    });
  }
  
  void _loadProfileData() {
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile != null) {
      _routineNameCtrl.text = profile.routineName;
      _morningCtrl.text = profile.divisionMorningName;
      _afternoonCtrl.text = profile.divisionAfternoonName;
      _nightCtrl.text = profile.divisionNightName;
      _tomorrowCtrl.text = profile.divisionTomorrowName;
      _notificationFrequency = profile.notificationFrequencyHours.toDouble();
      _selectedTheme = profile.appTheme;
      _notifEnabled = profile.notifEnabled;
      _alarmSoundEnabled = profile.alarmSoundEnabled;
      _useBrightnessOverride = profile.useBrightnessOverride;
      _brightnessOverride = profile.brightnessOverride;
    }
  }

  @override
  void dispose() {
    _routineNameCtrl.dispose();
    _morningCtrl.dispose();
    _afternoonCtrl.dispose();
    _nightCtrl.dispose();
    _tomorrowCtrl.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final isar = ref.read(isarProvider);
      final profile = await isar.userProfiles.get(1);

      if (profile == null) {
        if (mounted) {
          final theme = ref.read(currentThemeProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: perfil não encontrado. Reinicie o app.', style: theme.fontStyleBase(const TextStyle(color: Colors.white))),
              backgroundColor: theme.taskRed,
            ),
          );
        }
        return;
      }
      profile.routineName = _routineNameCtrl.text;
      profile.divisionMorningName = _morningCtrl.text;
      profile.divisionAfternoonName = _afternoonCtrl.text;
      profile.divisionNightName = _nightCtrl.text;
      profile.divisionTomorrowName = _tomorrowCtrl.text;
      profile.notificationFrequencyHours = _notificationFrequency.toInt();
      profile.appTheme = _selectedTheme;
      profile.notifEnabled = _notifEnabled;
      profile.alarmSoundEnabled = _alarmSoundEnabled;
      profile.useBrightnessOverride = _useBrightnessOverride;
      profile.brightnessOverride = _brightnessOverride;
      await isar.writeTxn(() async {
        await isar.userProfiles.put(profile);
      });

      NotificationService.instance.updatePeriodicChecks(_notificationFrequency.toInt());

      if (mounted) {
        final theme = ref.read(currentThemeProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Configurações salvas com sucesso!', style: theme.fontStyleBase(const TextStyle(color: Colors.white))),
            backgroundColor: theme.primary,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _testNotification() async {
    final theme = ref.read(currentThemeProvider);
    await NotificationService.instance.showTestNotification(
      id: 999,
      title: '⏰ Teste de Notificação',
      body: 'Este é um teste de notificação pelo canal de Lembretes de Rotina.',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notificação de teste enviada!', style: theme.fontStyleBase(const TextStyle(color: Colors.white))),
          backgroundColor: theme.accent,
        ),
      );
    }
  }

  void _exportBackupFile() async {
    setState(() => _isBackupLoading = true);
    final success = await ref.read(backupServiceProvider).shareBackupFile();
    setState(() => _isBackupLoading = false);

    if (mounted) {
      final theme = ref.read(currentThemeProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Backup compartilhado com sucesso!'
              : 'Exportação concluída ou cancelada.',
              style: theme.fontStyleBase(const TextStyle(color: Colors.white))),
          backgroundColor: success ? theme.accent : theme.taskRed,
        ),
      );
    }
  }

  void _importBackupFile() async {
    final theme = ref.read(currentThemeProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text('Confirmar Importação', style: theme.fontStyleBase(TextStyle(color: theme.taskRed))),
        content: Text(
          'A importação substituirá permanentemente todos os seus dados atuais (rotinas, tarefas, níveis e XP) pelos dados do backup. Deseja continuar?',
          style: theme.fontStyleBase(TextStyle(color: theme.textPrimary)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: theme.fontStyleBase(TextStyle(color: theme.textMuted))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Importar', style: theme.fontStyleBase(TextStyle(color: theme.taskRed))),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isBackupLoading = true);
    final success = await ref.read(backupServiceProvider).importBackupFromFile();
    setState(() => _isBackupLoading = false);

    if (mounted) {
      if (success) {
        ref.invalidate(userProfileProvider);
        ref.invalidate(allRoutinesProvider);
        ref.invalidate(todayRoutineProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup importado com sucesso! Recarregando...', style: theme.fontStyleBase(const TextStyle(color: Colors.white))),
            backgroundColor: theme.accent,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao importar backup. Verifique o arquivo selecionado.', style: theme.fontStyleBase(const TextStyle(color: Colors.white))),
            backgroundColor: theme.taskRed,
          ),
        );
      }
    }
  }

  void _exportBackupClipboard() async {
    final theme = ref.read(currentThemeProvider);
    try {
      final data = await ref.read(backupServiceProvider).exportBackupData();
      await FlutterClipboard.copy(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código JSON de backup copiado!', style: theme.fontStyleBase(const TextStyle(color: Colors.white))),
            backgroundColor: theme.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar para a área de transferência.', style: theme.fontStyleBase(const TextStyle(color: Colors.white))),
            backgroundColor: theme.taskRed,
          ),
        );
      }
    }
  }

  void _importBackupClipboard() async {
    final theme = ref.read(currentThemeProvider);
    final textCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text('Importar Código de Backup', style: theme.fontStyleBase(TextStyle(color: theme.accent))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cole o código JSON de backup abaixo. Isso substituirá todos os seus dados atuais.',
              style: theme.fontStyleBase(TextStyle(color: theme.textPrimary, fontSize: 13)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              maxLines: 5,
              style: theme.fontStyleBase(TextStyle(color: theme.textPrimary, fontSize: 12)),
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.background,
                hintText: 'Cole o JSON aqui...',
                hintStyle: theme.fontStyleBase(TextStyle(color: theme.textMuted)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: theme.fontStyleBase(TextStyle(color: theme.textMuted))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Restaurar', style: theme.fontStyleBase(TextStyle(color: theme.accent))),
          ),
        ],
      ),
    );

    final jsonText = textCtrl.text.trim();
    textCtrl.dispose();

    if (confirm != true || jsonText.isEmpty) return;

    setState(() => _isBackupLoading = true);
    try {
      await ref.read(backupServiceProvider).importBackupData(jsonText);
      ref.invalidate(userProfileProvider);
      ref.invalidate(allRoutinesProvider);
      ref.invalidate(todayRoutineProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup restaurado com sucesso!', style: theme.fontStyleBase(const TextStyle(color: Colors.white))),
            backgroundColor: theme.accent,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao decodificar JSON. Formato inválido.', style: theme.fontStyleBase(const TextStyle(color: Colors.white))),
            backgroundColor: theme.taskRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBackupLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
      child: Scaffold(
        key: ValueKey(theme.type),
        backgroundColor: theme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Configurações', style: theme.fontStyleBase(AppTextStyles.titleMedium).copyWith(color: theme.textPrimary)),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.primary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                _buildAccordion(
                  theme: theme,
                  title: 'Personalização de Nomes',
                  icon: Icons.edit_note_rounded,
                  children: [
                    _buildTextField(theme, 'Nome da Rotina', _routineNameCtrl),
                    const SizedBox(height: 16),
                    Text('DIVISÕES DO DIA', style: theme.fontStyleBase(AppTextStyles.labelSmall).copyWith(color: theme.primary)),
                    const SizedBox(height: 12),
                    _buildTextField(theme, 'Manhã', _morningCtrl),
                    const SizedBox(height: 12),
                    _buildTextField(theme, 'Tarde', _afternoonCtrl),
                    const SizedBox(height: 12),
                    _buildTextField(theme, 'Noite', _nightCtrl),
                    const SizedBox(height: 12),
                    _buildTextField(theme, 'Para Amanhã', _tomorrowCtrl),
                  ],
                ),
                
                const SizedBox(height: 16),

                _buildAccordion(
                  theme: theme,
                  title: 'Temas e Estilos',
                  icon: Icons.palette_outlined,
                  initiallyExpanded: true,
                  children: [
                    Text(
                      'Escolha uma das 12 estéticas exclusivas:',
                      style: theme.fontStyleBase(TextStyle(color: theme.textSecondary, fontSize: 13)),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.8,
                      ),
                      itemCount: AppThemeType.values.length,
                      itemBuilder: (context, index) {
                        final themeType = AppThemeType.values[index];
                        final themeData = AppThemeData.fromType(themeType);
                        final isSelected = _selectedTheme == themeType;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedTheme = themeType);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? themeData.primary
                                    : themeData.border.withValues(alpha: 0.5),
                                width: isSelected ? 2.0 : 1.0,
                              ),
                              boxShadow: (isSelected && themeData.useGlowBorder)
                                  ? themeData.glowShadow(themeData.primary, intensity: 0.3)
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [themeData.background, themeData.surface, themeData.primary],
                                    stops: const [0.0, 0.5, 1.0],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      themeData.name,
                                      style: themeData.fontStyleBase(TextStyle(
                                        color: themeData.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4),
                                        ],
                                      )),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'ESTÉTICA',
                                          style: themeData.fontStyleMono(TextStyle(
                                            color: themeData.textPrimary.withValues(alpha: 0.5),
                                            fontSize: 8,
                                            letterSpacing: 0.5,
                                          )),
                                        ),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: themeData.secondary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Divider(color: theme.divider, height: 1),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Forçar Luminosidade Manual', style: theme.fontStyleBase(TextStyle(color: theme.textPrimary, fontSize: 14))),
                      subtitle: Text('Ignorar o modo padrão (claro/escuro) do tema selecionado', style: theme.fontStyleBase(TextStyle(color: theme.textSecondary, fontSize: 11))),
                      value: _useBrightnessOverride,
                      activeThumbColor: theme.primary,
                      onChanged: (val) {
                        setState(() => _useBrightnessOverride = val);
                      },
                    ),
                    if (_useBrightnessOverride) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Forçar Modo Escuro', style: theme.fontStyleBase(TextStyle(color: theme.textPrimary, fontSize: 14))),
                        subtitle: Text('Ativar para forçar modo escuro, desativar para modo claro', style: theme.fontStyleBase(TextStyle(color: theme.textSecondary, fontSize: 11))),
                        value: _brightnessOverride,
                        activeThumbColor: theme.primary,
                        secondary: Icon(
                          _brightnessOverride ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: theme.primary,
                        ),
                        onChanged: (val) {
                          setState(() => _brightnessOverride = val);
                        },
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),
                
                 _buildAccordion(
                  theme: theme,
                  title: 'Notificações (Background)',
                  icon: Icons.notifications_active_outlined,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Notificações Diárias', style: theme.fontStyleBase(TextStyle(color: theme.textPrimary, fontSize: 14))),
                      subtitle: Text('Lembretes periódicos sobre suas tarefas do dia', style: theme.fontStyleBase(TextStyle(color: theme.textSecondary, fontSize: 11))),
                      value: _notifEnabled,
                      activeThumbColor: theme.primary,
                      onChanged: (val) {
                        setState(() => _notifEnabled = val);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Som do Alarme de Task', style: theme.fontStyleBase(TextStyle(color: theme.textPrimary, fontSize: 14))),
                      subtitle: Text('Tocar som personalizado para alarmes de tarefas', style: theme.fontStyleBase(TextStyle(color: theme.textSecondary, fontSize: 11))),
                      value: _alarmSoundEnabled,
                      activeThumbColor: theme.primary,
                      onChanged: (val) {
                        setState(() => _alarmSoundEnabled = val);
                      },
                    ),
                    const Divider(height: 24),
                    Text(
                      'Frequência de lembretes automáticos:',
                      style: theme.fontStyleBase(TextStyle(color: theme.textSecondary, fontSize: 13)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('A cada ${_notificationFrequency.toInt()}h', 
                          style: theme.fontStyleMono(TextStyle(color: theme.primary, fontWeight: FontWeight.bold, fontSize: 16))),
                        Expanded(
                          child: Slider(
                            value: _notificationFrequency,
                            min: 1,
                            max: 24,
                            divisions: 23,
                            activeColor: theme.primary,
                            inactiveColor: theme.surface,
                            onChanged: _notifEnabled ? (val) {
                              setState(() => _notificationFrequency = val);
                            } : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.accent,
                          side: BorderSide(color: theme.accent, width: 1.0),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.notifications_active_rounded, size: 18),
                        label: Text('Testar Notificação', style: theme.fontStyleBase(const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        onPressed: _testNotification,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                _buildAccordion(
                  theme: theme,
                  title: 'Backup e Restauração',
                  icon: Icons.backup_rounded,
                  children: [
                    if (_isBackupLoading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(color: theme.primary),
                        ),
                      )
                    else ...[
                      Text(
                        'Salve seus dados para recuperá-los em caso de formatação ou troca de aparelho. Fotos físicas não são salvas no backup de texto.',
                        style: theme.fontStyleBase(TextStyle(color: theme.textSecondary, fontSize: 13)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.surface,
                                foregroundColor: theme.primary,
                                side: BorderSide(color: theme.primary, width: 1.0),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.share_rounded, size: 18),
                              label: Text('Exportar Arquivo', style: theme.fontStyleBase(const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              onPressed: _exportBackupFile,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.surface,
                                foregroundColor: theme.accent,
                                side: BorderSide(color: theme.accent, width: 1.0),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.file_open_rounded, size: 18),
                              label: Text('Importar Arquivo', style: theme.fontStyleBase(const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              onPressed: _importBackupFile,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.textSecondary,
                                side: BorderSide(color: theme.border, width: 1.0),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: Text('Copiar JSON', style: theme.fontStyleBase(const TextStyle(fontSize: 11))),
                              onPressed: _exportBackupClipboard,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.textSecondary,
                                side: BorderSide(color: theme.border, width: 1.0),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.paste_rounded, size: 16),
                              label: Text('Colar JSON', style: theme.fontStyleBase(const TextStyle(fontSize: 11))),
                              onPressed: _importBackupClipboard,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.borderRadius > 12 ? 12 : theme.borderRadius)),
                    ),
                    onPressed: _saveSettings,
                    child: Text('Salvar Alterações', style: theme.fontStyleBase(const TextStyle(fontWeight: FontWeight.bold))),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Zona de Perigo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.taskRed.withValues(alpha: 0.1),
                    border: Border.all(color: theme.taskRed.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(theme.borderRadius > 12 ? 12 : theme.borderRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: theme.taskRed),
                          const SizedBox(width: 8),
                          Text('Zona de Perigo', style: theme.fontStyleBase(TextStyle(color: theme.taskRed, fontWeight: FontWeight.bold, fontSize: 16))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Isso apagará permanentemente todas as rotinas e tarefas passadas. Apenas a rotina de hoje será mantida.',
                        style: theme.fontStyleBase(TextStyle(color: theme.textSecondary, fontSize: 13)),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.taskRed,
                            side: BorderSide(color: theme.taskRed),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _confirmDeleteHistory,
                          child: Text('Apagar Histórico Antigo', style: theme.fontStyleBase(const TextStyle(fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  void _confirmDeleteHistory() async {
    final theme = ref.read(currentThemeProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text('Tem certeza?', style: theme.fontStyleBase(TextStyle(color: theme.taskRed))),
        content: Text('Esta ação é irreversível e todas as fotos de rotinas passadas serão perdidas.', style: theme.fontStyleBase(TextStyle(color: theme.textPrimary))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: theme.fontStyleBase(TextStyle(color: theme.textMuted)))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Apagar', style: theme.fontStyleBase(TextStyle(color: theme.taskRed)))),
        ],
      )
    );
    
    if (confirm != true) return;
    
    final routineService = ref.read(routineServiceProvider);
    await routineService.deleteAllPastRoutines();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Histórico limpo com sucesso!', style: theme.fontStyleBase(const TextStyle(color: Colors.white)))));
    }
  }

  Widget _buildTextField(AppThemeData theme, String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: theme.fontStyleBase(TextStyle(color: theme.textPrimary)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.fontStyleBase(TextStyle(color: theme.textMuted)),
        filled: true,
        fillColor: theme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primary),
        ),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Campo obrigatório';
        }
        return null;
      },
    );
  }

  Widget _buildAccordion({
    required AppThemeData theme,
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border.withValues(alpha: 0.5)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: Icon(icon, color: theme.primary, size: 24),
          title: Text(title, style: theme.fontStyleBase(TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold))),
          iconColor: theme.primary,
          collapsedIconColor: theme.textSecondary,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: children,
        ),
      ),
    );
  }
}
