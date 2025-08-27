import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/app_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text(
                'Impostazioni',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppTheme.white,
              surfaceTintColor: AppTheme.white,
              foregroundColor: AppTheme.black,
              elevation: 0,
              automaticallyImplyLeading: false,
              floating: true,
              snap: true,
              pinned: false,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Sezione Profilo
                  _buildProfileSection(context),

                  const SizedBox(height: 24),

                  // Sezione Badge
                  _buildBadgesSection(context),

                  const SizedBox(height: 24),

                  // Sezione Impostazioni
                  _buildSettingsSection(context),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userMetadata = user?.userMetadata;
    final fullName = userMetadata?['full_name'] as String?;
    final email = user?.email ?? '';
    final isEmailConfirmed = user?.emailConfirmedAt != null;

    return Card(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          color: AppTheme.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: fullName != null && fullName.isNotEmpty
                        ? Text(
                            fullName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          )
                        : email.isNotEmpty
                            ? Text(
                                email[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              )
                            : const Icon(
                                UniconsLine.user,
                                size: 40,
                                color: AppTheme.primaryColor,
                              ),
                  ),
                ),

                const SizedBox(width: 16),

                // Informazioni utente
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName ?? email.split('@')[0],
                        style: AppTheme.textLargeBold,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: AppTheme.textMedium.copyWith(
                          color: AppTheme.grey600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isEmailConfirmed
                              ? AppTheme.successColor.withValues(alpha: 0.1)
                              : AppTheme.warningColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isEmailConfirmed 
                              ? 'Email verificata'
                              : 'Email non verificata',
                          style: AppTheme.textSmall.copyWith(
                            color: isEmailConfirmed
                                ? AppTheme.successColor
                                : AppTheme.warningColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Pulsante modifica
                IconButton(
                  onPressed: () {
                    // Non fare nulla quando viene cliccato
                  },
                  icon: const Icon(
                    UniconsLine.edit_alt,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
  }

  Widget _buildBadgesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('I Tuoi Badge', style: AppTheme.headline3),
        const SizedBox(height: 16),

        Card(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          color: AppTheme.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Griglia badge
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _badges.length,
                  itemBuilder: (context, index) {
                    return _buildBadgeItem(_badges[index]);
                  },
                ),

                const SizedBox(height: 16),

                // Progress indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.grey50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progressi',
                            style: AppTheme.textMediumBold,
                          ),
                          Text(
                            '${_earnedBadges.length}/${_badges.length}',
                            style: AppTheme.textMedium.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _earnedBadges.length / _badges.length,
                        backgroundColor: AppTheme.grey200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeItem(Badge badge) {
    final isEarned = _earnedBadges.contains(badge.id);

    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color:
                isEarned
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : AppTheme.grey200,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isEarned ? AppTheme.primaryColor : AppTheme.grey300,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              badge.emoji,
              style: TextStyle(
                fontSize: 24,
                color: isEarned ? null : AppTheme.grey600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          badge.name,
          style: AppTheme.textSmall.copyWith(
            color: isEarned ? AppTheme.black87 : AppTheme.grey600,
            fontWeight: isEarned ? FontWeight.w500 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Altro', style: AppTheme.headline3),
        const SizedBox(height: 16),

        Card(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          color: AppTheme.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.cardBorder),
          ),
          child: Column(
            children: [
              _buildSettingItem(
                icon: UniconsLine.sign_out_alt,
                title: 'Esci',
                textColor: AppTheme.red,
                onTap: () => _showLogoutDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppTheme.grey700),
      title: Text(title, style: AppTheme.textMedium.copyWith(color: textColor)),
      trailing: const Icon(UniconsLine.angle_right, color: AppTheme.grey600),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            backgroundColor: AppTheme.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.cardBorder),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            children: [
              const Text(
                'Sei sicuro di voler uscire dal tuo account?',
                style: TextStyle(fontSize: 14, color: AppTheme.black),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      textStyle: const TextStyle(
                        fontFamily: AppConstants.fontFamily,
                        fontSize: 14,
                      ),
                    ),
                    child: const Text('Annulla'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);

                      final authController = context.read<AuthController>();
                      final appController = context.read<AppController>();

                      await authController.signOut();
                      appController.setAuthenticated(false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: AppTheme.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontFamily: AppConstants.fontFamily,
                        fontSize: 14,
                      ),
                    ),
                    child: const Text('Esci'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
    );
  }
}

// Modelli per i badge
class Badge {
  final String id;
  final String name;
  final String emoji;
  final String description;

  const Badge({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
  });
}

// Badge disponibili (simulati)
const List<Badge> _badges = [
  Badge(
    id: 'first_save',
    name: 'Primo Salvataggio',
    emoji: '🌱',
    description: 'Hai salvato il tuo primo alimento',
  ),
  Badge(
    id: 'waste_warrior',
    name: 'Guerriero Anti-spreco',
    emoji: '⚔️',
    description: 'Hai evitato 10 sprechi alimentari',
  ),
  Badge(
    id: 'shopping_master',
    name: 'Maestro della Spesa',
    emoji: '🛒',
    description: 'Hai completato 20 liste della spesa',
  ),
  Badge(
    id: 'inventory_king',
    name: 'Re dell\'Inventario',
    emoji: '👑',
    description: 'Hai gestito 100 prodotti',
  ),
  Badge(
    id: 'eco_hero',
    name: 'Eroe Ecologico',
    emoji: '🦸',
    description: 'Hai salvato 50 kg di cibo',
  ),
  Badge(
    id: 'streak_champion',
    name: 'Campione di Costanza',
    emoji: '🔥',
    description: 'Hai usato l\'app per 30 giorni consecutivi',
  ),
];

// Badge ottenuti dall'utente (simulati - dovrebbero venire dal backend)
const List<String> _earnedBadges = [
  'first_save',
  'waste_warrior',
  'shopping_master',
];
