import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Article extends StatelessWidget {
  String createdAt;
  String storyTitle;
  String author;

  Article({
    super.key,
    required this.createdAt,
    required this.storyTitle,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    final datetime = DateTime.parse(createdAt);
    final date = DateFormat('d MMM yyyy').format(datetime);
    final time = DateFormat('hh:ss').format(datetime);

    return Center(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(storyTitle),
              subtitle: Text("Author : " + author),
              trailing: Text(date + " at " + time),
            ),
          ],
        ),
      ),
    );
  }
}
