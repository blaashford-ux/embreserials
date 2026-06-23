// lib/widgets/auth_modal.dart
//
// Adapted from the main Embre AuthModal — same behaviour, same Supabase project.
// Web: awaits OAuth and closes on completion.
// Mobile: launches OAuth browser and closes the modal immediately;
//         auth state change listener handles the rest.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AuthModal extends StatefulWidget {
  const AuthModal({super.key});

  /// Helper: show the auth modal as a dialog.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const AuthModal(),
    );
  }

  @override
  State<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends State<AuthModal> {
  final _authService = AuthService();
  final _formKey     = GlobalKey<FormState>();

  bool _isLogin   = true;
  bool _isLoading = false;

  final _emailController       = TextEditingController();
  final _passwordController    = TextEditingController();
  final _usernameController    = TextEditingController();
  final _displayNameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await _authService.signIn(
          email:    _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await _authService.signUp(
          email:       _emailController.text.trim(),
          password:    _passwordController.text,
          username:    _usernameController.text.trim(),
          displayName: _displayNameController.text.trim(),
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
        _showSnack(_isLogin ? 'Signed in' : 'Account created');
      }
    } on AuthException catch (e) {
      if (mounted) _showSnack(e.message);
    } catch (e) {
      if (mounted) _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _oauth(Future<void> Function() call) async {
    if (kIsWeb) {
      setState(() => _isLoading = true);
      try {
        await call();
        if (mounted) Navigator.of(context).pop();
      } on AuthException catch (e) {
        if (mounted) _showSnack(e.message);
      } catch (e) {
        if (mounted) _showSnack('Error: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // Mobile: launch external browser, close modal, auth state fires later
      try {
        await call();
      } catch (e) {
        if (mounted) _showSnack('Could not open sign-in: $e');
        return;
      }
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isLogin ? 'Sign In' : 'Create Account',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                if (!_isLogin) ...[
                  _field(_usernameController,    'Username',     validator: _req),
                  const SizedBox(height: 16),
                  _field(_displayNameController, 'Display Name', validator: _req),
                  const SizedBox(height: 16),
                ],

                _field(
                  _emailController, 'Email',
                  type: TextInputType.emailAddress,
                  validator: (v) =>
                      v!.isEmpty || !v.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                _field(
                  _passwordController, 'Password',
                  obscure: true,
                  validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isLogin ? 'Sign In' : 'Sign Up'),
                ),
                const SizedBox(height: 16),

                _divider(context),
                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: () => _oauth(_authService.signInWithGoogle),
                  icon: const Icon(Icons.login),
                  label: const Text('Continue with Google'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _oauth(_authService.signInWithDiscord),
                  icon: const Icon(Icons.chat),
                  label: const Text('Continue with Discord'),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin
                      ? 'Need an account? Sign Up'
                      : 'Already have an account? Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType type = TextInputType.text,
    bool obscure = false,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: type,
        obscureText: obscure,
        validator: validator,
        enabled: !_isLoading,
      );

  String? _req(String? v) => v!.isEmpty ? 'Required' : null;

  Widget _divider(BuildContext context) => Row(children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('OR', style: Theme.of(context).textTheme.bodySmall),
        ),
        const Expanded(child: Divider()),
      ]);
}
