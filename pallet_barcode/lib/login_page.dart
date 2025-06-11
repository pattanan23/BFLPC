import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'main_pack.dart';
import 'main_check.dart';
import 'main_qc.dart';
import 'main_admin.dart';
import 'main_warehouse.dart';
import 'config.dart';
import 'main_loader.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedUsername;
  final List<String> _usernames = [
    'wanna',
    'fg01',
    'checker',
    'QC',
    'Pattanui',
    'pat'
  ];

  String? _selectedDepartment;
  final List<String> _departments = [
    'Admin',
    'Packing',
    'Checker',
    'Warehouse',
    'Quality Control',
    'Loader'
  ];

  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _tryConnectLoop();
  }

  void _tryConnectLoop() async {
    while (!_connected && mounted) {
      await _checkDatabaseConnection();
      if (!_connected) {
        await Future.delayed(const Duration(seconds: 3));
      }
    }
  }

  Future<void> _checkDatabaseConnection() async {
    String url = "$baseUrl/ping";
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200 && mounted) {
        setState(() => _connected = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Connected to the database successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _showConnectionError();
      }
    } catch (_) {
      _showConnectionError();
    }
  }

  void _showConnectionError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Unable to connect to the database. Retrying...'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _login() async {
    final username = _selectedUsername;
    final password = _passwordController.text.trim();
    final department = _selectedDepartment;

    if (username == null || password.isEmpty || department == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verifying credentials...'),
        duration: Duration(seconds: 3),
      ),
    );

    String url = "$baseUrl/login";
    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'department': department,
        }),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['status'] == 'success') {
          final user = data['user'];
          final dept = user['Department'].toString().trim();
          Widget target;

          switch (dept) {
            case 'Packing':
              target = MainPack(username: user['Username'], department: dept);
              break;
            case 'Checker':
              target = MainChecker(username: user['Username'], department: dept);
              break;
            case 'Warehouse':
              target = MainWarehouse(username: user['Username'], department: dept);
              break;
            case 'Quality Control':
              target = MainQC(username: user['Username'], department: dept);
              break;
            case 'Loader':
              target = MainLoader(username: user['Username'], department: dept);
              break;
            default:
              target = MainAdmin(username: user['Username'], department: dept);
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => target),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Invalid credentials')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Unable to connect to the server')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2C2C2C), Color(0xFFBDBDBD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    image: const DecorationImage(
                      image: AssetImage('assets/images/logoBFL.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                _buildDropdown(
                  'Department',
                  _departments,
                  _selectedDepartment,
                  (v) => setState(() => _selectedDepartment = v),
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  'Username',
                  _usernames,
                  _selectedUsername,
                  (v) => setState(() => _selectedUsername = v),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 500,
                  height: 60,
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: _inputDecoration('Password'),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E3E3E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value,
      void Function(String?) onChanged) {
    return SizedBox(
      width: 500,
      height: 60,
      child: DropdownButtonFormField<String>(
        decoration: _inputDecoration(label),
        value: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withOpacity(0.8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
