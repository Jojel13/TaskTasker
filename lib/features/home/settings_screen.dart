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
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _routineNameCtrl;
  late TextEditingController _morningCtrl;
  late TextEditingController _afternoonCtrl;
  late TextEditingController _nightCtrl;
  late TextEditingController _tomorrowCtrl;
  
  double _notificationFrequency = 6;
  bool _isBackupLoading = false;
  AppThemeType _selectedTheme = AppThemeType.cyberpunkDark;

  @override
  void initState() {
    super.initState();
    _routineNameCtrl = TextEditingController();
    _morningCtrl = TextEditingController();
    _afternoonCtrl = TextEditingController();
    _nightCtrl = TextEditingController();
    _tomorrowCtrl = TextEditingController();
    
    _loadProfileData();
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

  Widget _buildColorDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);

    return Scaffold(
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
                              color: themeData.surface,
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
                            padding: const EdgeInsets.all(12),
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
                                  )),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    _buildColorDot(themeData.background),
                                    _buildColorDot(themeData.primary),
                                    _buildColorDot(themeData.taskBlue),
                                    _buildColorDot(themeData.taskYellow),
                                    _buildColorDot(themeData.taskRed),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                
                 _buildAccordion(
                  theme: theme,
                  title: 'Notificações (Background)',
                  icon: Icons.notifications_active_outlined,
                  children: [
                    Text(
                      'Frequência de lembretes automáticos:',
                      style: theme.fontStyleBase(TextStyle(color: theme.textSecondary, fontSize: 13)),
                    ),
                    const SizedBox(height: 16),
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
                            onChanged: (val) {
                              setState(() => _notificationFrequency = val);
                            },
                          ),
                        ),
                      ],
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

  Widget _buildAccordion({required AppThemeData theme, required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border.withValues(alpha: 0.5)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
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
