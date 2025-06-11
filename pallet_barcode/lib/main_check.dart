import 'package:flutter/material.dart';
import 'login_page.dart';
import 'checker/search_barcode.dart';
import 'pie_chart.dart'; // import ApprovalChart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'checker/config.dart';

class MainChecker extends StatefulWidget {
  final String username;
  final String department;

  const MainChecker({super.key, required this.username, required this.department});

  @override
  State<MainChecker> createState() => _MainCheckerState();
}

class _MainCheckerState extends State<MainChecker> {
  int accepted = 0;
  int pending = 0;
  int rejected = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchApprovalStats();
  }

  Future<void> fetchApprovalStats() async {
    try {
      String url = "$baseUrl/approval-stats";  // เปลี่ยนตาม API จริง // Change according to the actual API.
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          setState(() {
            accepted = data['data']['accepted'] ?? 0;
            pending = data['data']['pending'] ?? 0;
            rejected = data['data']['rejected'] ?? 0;
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        throw Exception('Data loading failed.');
      }
    } catch (e) {
      print("Error fetching stats: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Image.asset('assets/images/logoBFL.png'),
            ),
          ),
        ),
        title: const Text(
          'PALLETBARCODE_CHECKER',
          style: TextStyle(fontSize: 20, color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.redAccent,
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Show PieChart or Progress Indicator while loading data.
            isLoading
                ? const CircularProgressIndicator()
                : ApprovalChart(
                    accepted: accepted,
                    pending: pending,
                    rejected: rejected,
                  ),
            const SizedBox(height: 20),
            Expanded(
              child: SearchBarcode(username: widget.username),
            ),
          ],
        ),
      ),
    );
  }
}
