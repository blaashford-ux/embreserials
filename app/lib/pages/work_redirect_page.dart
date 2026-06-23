// lib/pages/work_redirect_page.dart
//
// Notifications store work_id (uuid), but routes use slug. This page
// resolves the slug and redirects, so notification taps don't need
// their own duplicate route shape.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/serials_db.dart';

class WorkRedirectPage extends StatefulWidget {
  final String workId;
  const WorkRedirectPage({super.key, required this.workId});

  @override
  State<WorkRedirectPage> createState() => _WorkRedirectPageState();
}

class _WorkRedirectPageState extends State<WorkRedirectPage> {
  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final res = await SerialsDb.db
        .from('works')
        .select('slug')
        .eq('id', widget.workId)
        .maybeSingle();

    if (!mounted) return;
    if (res == null) {
      context.go('/');
    } else {
      context.go('/work/${res['slug']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
