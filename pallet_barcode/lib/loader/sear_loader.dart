import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pallet_barcode/checker/config.dart';
import 'package:pallet_barcode/checker/scan_mobile.dart';

class SearchBarcodeLoader extends StatefulWidget {
  final String username;

  const SearchBarcodeLoader({super.key, required this.username});

  @override
  State<SearchBarcodeLoader> createState() => _SearchBarcodeState();
}

class _SearchBarcodeState extends State<SearchBarcodeLoader> {
  final TextEditingController barcodeController = TextEditingController();
  Map<String, dynamic>? searchResult;
  bool isLoading = false;

  Future<void> searchBarcode() async {
    String fullInput = barcodeController.text.trim();
    String barcode = fullInput.length > 1
        ? fullInput.substring(0, fullInput.length - 1)
        : '';

    if (barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid barcode.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
      searchResult = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search-barcode-loader?barcode=$barcode'),
      );
      final result = json.decode(response.body);

      if (result['status'] == 'success') {
        setState(() {
          searchResult = {...?result['data'][0]};
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "No data found")),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> submitStatus(bool isCheckin, String location) async {
    try {
      final now = DateTime.now();

      final payload = {
        'slip_no': searchResult?['Slip_No'] ?? '',
        'date':
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
        'time':
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}",
        'check_in': isCheckin ? 'yes' : 'no',
        'check_out': isCheckin ? 'no' : 'yes',
        'location': isCheckin ? location : '-',
        'bar_code': searchResult?['Bar_Code'] ?? '',
        'name': widget.username,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/submit-status-loader'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final result = json.decode(response.body);

      if (result['status'] == 'success') {
        setState(() {
          if (isCheckin) {
            searchResult?['Check_In'] = 'yes';
            searchResult?['Location'] = location;
          } else {
            searchResult?['Check_Out'] = 'yes';
          }
          searchResult?['Name'] = widget.username;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCheckin
                ? "Load in saved successfully"
                : "Load out saved successfully"),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Something went wrong")),
        );
      }
    } catch (e) {
      print('Submit error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error while saving")),
      );
    }
  }

  void showLocationDialog(bool isCheckin) {
    if (!isCheckin) {
      submitStatus(false, '-');
      return;
    }

    final TextEditingController locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Location for Load in"),
        content: TextField(
          controller: locationController,
          decoration: const InputDecoration(
            hintText: "Specify location...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final location = locationController.text.trim();
              if (location.isNotEmpty) {
                Navigator.pop(context);
                submitStatus(true, location);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a location")),
                );
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Widget labeledValue(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "$label:",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value?.toString() ?? '-',
              style: const TextStyle(fontSize: 18, color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    "🔍 Search Barcode",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: barcodeController,
                    decoration: const InputDecoration(
                      hintText: "Enter barcode...",
                      prefixIcon: Icon(Icons.qr_code),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: searchBarcode,
                          icon: const Icon(Icons.search),
                          label: const Text("Search"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BarcodeScannerPage(),
                              ),
                            );

                            if (result != null && result is String) {
                              barcodeController.text = result;
                              searchBarcode();
                            }
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Scan"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (isLoading) const CircularProgressIndicator(),
          if (searchResult != null)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("📦 Barcode Details",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    labeledValue("Slip Number", searchResult?['Slip_No']),
                    labeledValue("Document Number", searchResult?['Document_No']),
                    labeledValue("Formula Name", searchResult?['Formula_Name']),
                    labeledValue("FG Code", searchResult?['Formula_Code']),
                    labeledValue("Lot Number", searchResult?['Lot_No']),
                    labeledValue("Packing M/c", searchResult?['Pack_No']),
                    labeledValue("Pack Type", searchResult?['Pack_Type']),
                    labeledValue("Bag Weight", searchResult?['Bag_Weight']),
                    labeledValue("Total Bag No", searchResult?['Total_Bag_No']),
                    labeledValue("Bar Code", searchResult?['Bar_Code']),
                    labeledValue("Staff Name", searchResult?['Name']),
                    labeledValue("Load in", searchResult?['Check_In'] == 'yes' ? '✅' : '❌'),
                    labeledValue("Load out", searchResult?['Check_Out'] == 'yes' ? '✅' : '❌'),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (searchResult?['Check_In'] != 'yes' &&
                            searchResult?['Check_Out'] != 'yes')
                          ElevatedButton.icon(
                            onPressed: () => showLocationDialog(true),
                            icon: const Icon(Icons.login),
                            label: const Text("Load In"),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                          ),
                        if (searchResult?['Check_In'] == 'yes' &&
                            searchResult?['Check_Out'] != 'yes')
                          ElevatedButton.icon(
                            onPressed: () => showLocationDialog(false),
                            icon: const Icon(Icons.logout),
                            label: const Text("Load Out"),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
