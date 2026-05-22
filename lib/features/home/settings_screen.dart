import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clipboard/clipboard.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/user_profile.dart';
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

      // A11: feedback explicito se perfil nao existir
      if (profile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro: perfil não encontrado. Reinicie o app.'),
              backgroundColor: AppColors.taskRed,
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

      await isar.writeTxn(() async {
        await isar.userProfiles.put(profile);
      });

      // Atualiza o Workmanager com a nova frequência
      NotificationService.instance.updatePeriodicChecks(_notificationFrequency.toInt());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurações salvas com sucesso!'),
            backgroundColor: AppColors.primary,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Backup compartilhado com sucesso!'
              : 'Exportação concluída ou cancelada.'),
          backgroundColor: success ? AppColors.accent : AppColors.taskRed,
        ),
      );
    }
  }

  void _importBackupFile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Confirmar Importação', style: TextStyle(color: AppColors.taskRed)),
        content: const Text(
          'A importação substituirá permanentemente todos os seus dados atuais (rotinas, tarefas, níveis e XP) pelos dados do backup. Deseja continuar?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Importar', style: TextStyle(color: AppColors.taskRed)),
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
          const SnackBar(
            content: Text('Backup importado com sucesso! Recarregando...'),
            backgroundColor: AppColors.accent,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao importar backup. Verifique o arquivo selecionado.'),
            backgroundColor: AppColors.taskRed,
          ),
        );
      }
    }
  }

  void _exportBackupClipboard() async {
    try {
      final data = await ref.read(backupServiceProvider).exportBackupData();
      await FlutterClipboard.copy(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código JSON de backup copiado!'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao exportar para a área de transferência.'),
            backgroundColor: AppColors.taskRed,
          ),
        );
      }
    }
  }

  void _importBackupClipboard() async {
    final textCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Importar Código de Backup', style: TextStyle(color: AppColors.accent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cole o código JSON de backup abaixo. Isso substituirá todos os seus dados atuais.',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              maxLines: 5,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.background,
                hintText: 'Cole o JSON aqui...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurar', style: TextStyle(color: AppColors.accent)),
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
          const SnackBar(
            content: Text('Backup restaurado com sucesso!'),
            backgroundColor: AppColors.accent,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao decodificar JSON. Formato inválido.'),
            backgroundColor: AppColors.taskRed,
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Configurações', style: AppTextStyles.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
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
                  title: 'Personalização de Nomes',
                  icon: Icons.edit_note_rounded,
                  children: [
                    _buildTextField('Nome da Rotina', _routineNameCtrl),
                    const SizedBox(height: 16),
                    Text('DIVISÕES DO DIA', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                    const SizedBox(height: 12),
                    _buildTextField('Manhã', _morningCtrl),
                    const SizedBox(height: 12),
                    _buildTextField('Tarde', _afternoonCtrl),
                    const SizedBox(height: 12),
                    _buildTextField('Noite', _nightCtrl),
                    const SizedBox(height: 12),
                    _buildTextField('Para Amanhã', _tomorrowCtrl),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                 _buildAccordion(
                  title: 'Notificações (Background)',
                  icon: Icons.notifications_active_outlined,
                  children: [
                    const Text(
                      'Frequência de lembretes automáticos:',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('A cada ${_notificationFrequency.toInt()}h', 
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                        Expanded(
                          child: Slider(
                            value: _notificationFrequency,
                            min: 1,
                            max: 24,
                            divisions: 23,
                            activeColor: AppColors.primary,
                            inactiveColor: AppColors.surface,
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
                  title: 'Backup e Restauração',
                  icon: Icons.backup_rounded,
                  children: [
                    if (_isBackupLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      )
                    else ...[
                      const Text(
                        'Salve seus dados para recuperá-los em caso de formatação ou troca de aparelho. Fotos físicas não são salvas no backup de texto.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surface,
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary, width: 1.0),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.share_rounded, size: 18),
                              label: const Text('Exportar Arquivo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              onPressed: _exportBackupFile,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surface,
                                foregroundColor: AppColors.accent,
                                side: const BorderSide(color: AppColors.accent, width: 1.0),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.file_open_rounded, size: 18),
                              label: const Text('Importar Arquivo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                                foregroundColor: AppColors.textSecondary,
                                side: const BorderSide(color: AppColors.border, width: 1.0),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: const Text('Copiar JSON', style: TextStyle(fontSize: 11)),
                              onPressed: _exportBackupClipboard,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side: const BorderSide(color: AppColors.border, width: 1.0),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.paste_rounded, size: 16),
                              label: const Text('Colar JSON', style: TextStyle(fontSize: 11)),
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
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _saveSettings,
                    child: const Text('Salvar Alterações', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Zona de Perigo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.taskRed.withValues(alpha: 0.1),
                    border: Border.all(color: AppColors.taskRed.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppColors.taskRed),
                          SizedBox(width: 8),
                          Text('Zona de Perigo', style: TextStyle(color: AppColors.taskRed, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Isso apagará permanentemente todas as rotinas e tarefas passadas. Apenas a rotina de hoje será mantida.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.taskRed,
                            side: const BorderSide(color: AppColors.taskRed),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _confirmDeleteHistory,
                          child: const Text('Apagar Histórico Antigo', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Tem certeza?', style: TextStyle(color: AppColors.taskRed)),
        content: const Text('Esta ação é irreversível e todas as fotos de rotinas passadas serão perdidas.', style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar', style: TextStyle(color: AppColors.taskRed))),
        ],
      )
    );
    
    if (confirm != true) return;
    
    final routineService = ref.read(routineServiceProvider);
    await routineService.deleteAllPastRoutines();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Histórico limpo com sucesso!')));
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
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
          borderSide: const BorderSide(color: AppColors.primary),
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

  Widget _buildAccordion({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: Icon(icon, color: AppColors.primary, size: 24),
          title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textSecondary,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: children,
        ),
      ),
    );
  }
}
