import 'package:flutter/material.dart';

class MainWarehouse extends StatelessWidget {
  final String username;
  final String department;

  const MainWarehouse ({super.key, required this.username, required this.department});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('HOME')),
      body: Center(
        child: Text(
          'Welcome $username From the department $department',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
