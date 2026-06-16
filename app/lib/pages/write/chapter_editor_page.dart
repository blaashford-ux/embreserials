import 'package:flutter/material.dart';
import '../../widgets/placeholder_page.dart';
class ChapterEditorPage extends StatelessWidget {
  final String workId;
  final String chapterId;
  const ChapterEditorPage({super.key, required this.workId, required this.chapterId});
  @override
  Widget build(BuildContext context) =>
      PlaceholderPage(title: 'Editor -- $chapterId');
}