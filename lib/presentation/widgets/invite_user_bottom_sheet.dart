import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/inventory_model.dart';
import '../../shared/theme/app_theme.dart';
import '../controllers/invitations_controller.dart';

class InviteUserBottomSheet extends StatefulWidget {
  final InventoryModel inventory;

  const InviteUserBottomSheet({super.key, required this.inventory});

  @override
  State<InviteUserBottomSheet> createState() => _InviteUserBottomSheetState();
}

class _InviteUserBottomSheetState extends State<InviteUserBottomSheet> {
  final TextEditingController _emailController = TextEditingController();
  String _selectedRole = 'member';
  bool _isLoading = false;

  final List<Map<String, String>> _roles = [
    {
      'value': 'member',
      'label': 'Membro',
      'description': 'Può vedere e modificare l\'inventario',
    },
    {
      'value': 'admin',
      'label': 'Amministratore',
      'description': 'Può gestire l\'inventario e i membri',
    },
  ];

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Invita utente',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.black,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.chipBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryColor),
                  ),
                  child: Text(
                    widget.inventory.name,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Form content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Email input
                  const Text(
                    'Email dell\'utente',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    cursorColor: AppTheme.primaryColor,
                    decoration: InputDecoration(
                      labelText: 'Inserisci email',
                      labelStyle: const TextStyle(
                        color: AppTheme.unselectedText,
                        fontSize: 14,
                      ),
                      floatingLabelStyle: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: AppTheme.unselectedText,
                      ),
                      filled: true,
                      fillColor: AppTheme.chipBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.cardBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.cardBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Role selection
                  const Text(
                    'Ruolo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.black,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ..._roles.map(
                    (role) => _RoleOption(
                      value: role['value']!,
                      label: role['label']!,
                      description: role['description']!,
                      isSelected: _selectedRole == role['value'],
                      onSelected: (value) {
                        setState(() {
                          _selectedRole = value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Send button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendInvitation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: AppTheme.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Invia invito',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.chipBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'L\'invito scadrà automaticamente dopo 7 giorni se non viene accettato.',
                            style: const TextStyle(
                              color: AppTheme.grey,
                              fontSize: 12,
                            ),
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
      ),
    );
  }

  void _sendInvitation() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError('Inserisci un\'email valida');
      return;
    }

    if (!_isValidEmail(email)) {
      _showError('Formato email non valido');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final controller = context.read<InvitationsController>();

    final result = await controller.inviteUser(
      inventoryId: widget.inventory.id,
      email: email,
      role: _selectedRole,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (result['success'] == true) {
        final message = result['message'] as String;
        final userExists = result['user_exists'] as bool? ?? false;

        _showSuccess(message, userExists);
        Navigator.of(context).pop();
      } else {
        final errorType = result['error'] as String?;
        final message = result['message'] as String? ?? 'Errore sconosciuto';

        _showErrorByType(errorType, message);
      }
    }
  }

  void _showSuccess(String message, bool userExists) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              userExists ? Icons.check_circle : Icons.info,
              color: AppTheme.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppTheme.white),
              ),
            ),
          ],
        ),
        backgroundColor: userExists ? AppTheme.primaryColor : AppTheme.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: userExists ? 3 : 5),
      ),
    );
  }

  void _showErrorByType(String? errorType, String message) {
    IconData icon;
    Color backgroundColor;

    switch (errorType) {
      case 'ALREADY_SHARED':
        icon = Icons.group;
        backgroundColor = AppTheme.orange;
        break;
      case 'PENDING_INVITATION':
        icon = Icons.pending;
        backgroundColor = AppTheme.orange;
        break;
      case 'PERMISSION_DENIED':
        icon = Icons.lock;
        backgroundColor = AppTheme.errorColor;
        break;
      case 'INVALID_ROLE':
        icon = Icons.error;
        backgroundColor = AppTheme.errorColor;
        break;
      default:
        icon = Icons.error_outline;
        backgroundColor = AppTheme.errorColor;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: AppTheme.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppTheme.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: AppTheme.white)),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}

class _RoleOption extends StatelessWidget {
  final String value;
  final String label;
  final String description;
  final bool isSelected;
  final ValueChanged<String> onSelected;

  const _RoleOption({
    required this.value,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? AppTheme.chipBg : AppTheme.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : AppTheme.cardBorder,
        ),
      ),
      child: InkWell(
        onTap: () => onSelected(value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Radio<String>(
                value: value,
                groupValue: isSelected ? value : null,
                onChanged: (value) {
                  if (value != null) {
                    onSelected(value);
                  }
                },
                activeColor: AppTheme.primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            isSelected ? AppTheme.primaryColor : AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppTheme.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
