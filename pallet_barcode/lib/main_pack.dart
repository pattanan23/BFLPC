import 'package:flutter/material.dart';
import 'pack/bar.dart';
import 'pack/data_pack.dart';
import 'pie_chart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'pack/pallet_slip_page.dart';
import 'config.dart';

class MainPack extends StatefulWidget {
  final String username;
  final String department;

  const MainPack({super.key, required this.username, required this.department});

  @override
  State<MainPack> createState() => _MainPackState();
}

//เซ็ตติ้งการแสดงผลของกราฟ //Setting the display of the graph
class _MainPackState extends State<MainPack> {
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
      String url = "$baseUrl/approval-stats";
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
        }
      } else {
        throw Exception('Data loading failed');
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
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                final RenderBox overlay =
                    Overlay.of(context).context.findRenderObject() as RenderBox;
                final Offset position =
                    overlay.localToGlobal(const Offset(0, kToolbarHeight));
                showCustomMenu(context, position);
              },
            ),
            const SizedBox(width: 20),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                final RenderBox overlay =
                    Overlay.of(context).context.findRenderObject() as RenderBox;
                final Offset position =
                    overlay.localToGlobal(const Offset(0, kToolbarHeight));
                showEditSubMenu(context, position);
              },
            ),
            const SizedBox(width: 20),
            IconButton(
              icon: const Icon(Icons.table_chart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PalletSlipPage()),
                );
              },
            ),
            const Spacer(),
            Text('Welcome ${widget.username}'),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            isLoading
                ? const CircularProgressIndicator()
                : ApprovalChart(
                    accepted: accepted,
                    pending: pending,
                    rejected: rejected,
                  ),
            const SizedBox(height: 20),
            Expanded(child: DataFormPage(username: widget.username)),
          ],
        ),
      ),
    );
  }
}
