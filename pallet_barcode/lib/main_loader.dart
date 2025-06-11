import 'package:flutter/material.dart';
import 'login_page.dart';
import 'loader/pie_chart_load.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'checker/config.dart';
import 'loader/sear_loader.dart';

class MainLoader extends StatefulWidget {
  final String username;
  final String department;

  const MainLoader({super.key, required this.username, required this.department});

  @override
  State<MainLoader> createState() => _MainLoaderState();
}

class _MainLoaderState extends State<MainLoader> {
  int checkIn = 0;
  int checkOut = 0;
  int notChecked = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLoaderStats();
  }

  Future<void> fetchLoaderStats() async {
    try {
      String url = '$baseUrl/loader-stats';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          setState(() {
            // ✅ ใช้ key ให้ตรงกับ API ที่ส่งมา // ✅ Use the key that matches the API that was sent.
            checkIn = data['data']['checkIn'] ?? 0;
            checkOut = data['data']['checkOut'] ?? 0;
            notChecked = data['data']['notChecked'] ?? 0;
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
          'PALLETBARCODE_LOADER',
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
            isLoading
                ? const CircularProgressIndicator()
                : LoaderStatusChart(
                    checkIn: checkIn,
                    checkOut: checkOut,
                    notChecked: notChecked,
                  ),
            const SizedBox(height: 20),
            Expanded(
              child: SearchBarcodeLoader(username: widget.username),
            ),
          ],
        ),
      ),
    );
  }
}
