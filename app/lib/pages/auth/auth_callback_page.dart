import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Handles Supabase OAuth callback on web.
/// Supabase parses the token from the URL automatically;
/// this page just redirects home once auth state updates.
class AuthCallbackPage extends StatefulWidget {
  const AuthCallbackPage({super.key});
  @override
  State<AuthCallbackPage> createState() => _State();
}

class _State extends State<AuthCallbackPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/');
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}