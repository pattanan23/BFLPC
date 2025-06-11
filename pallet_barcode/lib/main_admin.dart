import 'package:flutter/material.dart';

class MainAdmin extends StatelessWidget {
  final String username;
  final String department;

  const MainAdmin ({super.key, required this.username, required this.department});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('หน้าหลัก')),
      body: Center(
        child: Text(
          'welcome $username From the department $department',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
