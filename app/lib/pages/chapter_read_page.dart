import 'package:flutter/material.dart';
import '../widgets/placeholder_page.dart';
class ChapterReadPage extends StatelessWidget {
  final String slug;
  final int    chapterNum;
  const ChapterReadPage({super.key, required this.slug, required this.chapterNum});
  @override
  Widget build(BuildContext context) =>
      PlaceholderPage(title: '$slug -- Chapter $chapterNum');
}