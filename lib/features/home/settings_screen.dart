import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/user_profile.dart';

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
      
      if (profile != null) {
        profile.routineName = _routineNameCtrl.text;
        profile.divisionMorningName = _morningCtrl.text;
        profile.divisionAfternoonName = _afternoonCtrl.text;
        profile.divisionNightName = _nightCtrl.text;
        profile.divisionTomorrowName = _tomorrowCtrl.text;
        
        await isar.writeTxn(() async {
          await isar.userProfiles.put(profile);
        });
        
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
                Text('GERAL', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                const SizedBox(height: 16),
                _buildTextField('Nome da Rotina', _routineNameCtrl),
                
                const SizedBox(height: 32),
                Text('DIVISÕES DO DIA', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                const SizedBox(height: 16),
                _buildTextField('Manhã', _morningCtrl),
                const SizedBox(height: 12),
                _buildTextField('Tarde', _afternoonCtrl),
                const SizedBox(height: 12),
                _buildTextField('Noite', _nightCtrl),
                const SizedBox(height: 12),
                _buildTextField('Para Amanhã', _tomorrowCtrl),
                
                const SizedBox(height: 48),
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
}
