import 'package:flutter/material.dart';
import '../widgets/placeholder_page.dart';
class WorkPage extends StatelessWidget {
  final String slug;
  const WorkPage({super.key, required this.slug});
  @override
  Widget build(BuildContext context) => PlaceholderPage(title: 'Work: $slug');
}