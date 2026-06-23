// lib/widgets/age_gate_modal.dart
//
// Called before showing explicit-rated content.
// If not signed in  → prompts to sign in first.
// If signed in      → asks for 18+ confirmation, writes to public.users.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import 'auth_modal.dart';

class AgeGateModal extends ConsumerStatefulWidget {
  const AgeGateModal({super.key});

  /// Returns true if the user now has access (confirmed or already confirmed).
  /// Call this before rendering any explicit content.
  static Future<bool> check(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);

    // Not signed in — show auth first
    if (user == null) {
      await AuthModal.show(context);
      // After sign-in, re-check
      final newUser = ref.read(currentUserProvider);
      if (newUser == null) return false;
    }

    // Already confirmed?
    final confirmed = await ref.read(ageConfirmedProvider.future);
    if (confirmed) return true;

    // Show age gate
    if (!context.mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AgeGateModal(),
    );
    if (result == true) {
      // Invalidate so ageConfirmedProvider re-fetches
      ref.invalidate(ageConfirmedProvider);
    }
    return result == true;
  }

  @override
  ConsumerState<AgeGateModal> createState() => _AgeGateModalState();
}

class _AgeGateModalState extends ConsumerState<AgeGateModal> {
  bool _isLoading = false;

  Future<void> _confirm() async {
    setState(() => _isLoading = true);
    try {
      await AuthService().confirmAge();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Age Restricted Content'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This work is marked Explicit (18+).',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'By continuing you confirm that you are 18 or older and '
            'consent to viewing adult content.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _confirm,
          child: _isLoading
              ? const SizedBox(
                  height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('I confirm I am 18+'),
        ),
      ],
    );
  }
}
