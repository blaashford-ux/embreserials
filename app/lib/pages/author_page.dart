import 'package:flutter/material.dart';
import '../widgets/placeholder_page.dart';
class AuthorPage extends StatelessWidget {
  final String username;
  const AuthorPage({super.key, required this.username});
  @override
  Widget build(BuildContext context) =>
      PlaceholderPage(title: 'Author: $username');
}