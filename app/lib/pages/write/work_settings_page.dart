import 'package:flutter/material.dart';
import '../../widgets/placeholder_page.dart';
class WorkSettingsPage extends StatelessWidget {
  final String workId;
  const WorkSettingsPage({super.key, required this.workId});
  @override
  Widget build(BuildContext context) =>
      PlaceholderPage(title: 'Work Settings -- $workId');
}