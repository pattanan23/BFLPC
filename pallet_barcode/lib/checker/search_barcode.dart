import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pallet_barcode/checker/config.dart';
import 'package:pallet_barcode/checker/scan_mobile.dart';

class SearchBarcode extends StatefulWidget {
  final String username;

  const SearchBarcode({super.key, required this.username});

  @override
  State<SearchBarcode> createState() => _SearchBarcodeState();
}

class _SearchBarcodeState extends State<SearchBarcode> {
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
        const SnackBar(content: Text("Please enter a valid barcode")),
      );
      return;
    }

    setState(() {
      isLoading = true;
      searchResult = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search-barcode?barcode=$barcode'),
      );

      final result = json.decode(response.body);

      if (result['status'] == 'success') {
        setState(() {
          searchResult = {
            ...?result['data'][0],
          };
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No data found")),
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

  Future<void> submitStatus(bool isApproved, [String? comment]) async {
    try {
      final now = DateTime.now();

      final payload = {
        'slip_no': searchResult?['Slip_No'] ?? '',
        'bar_code': searchResult?['Bar_Code'] ?? '',
        'date':
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
        'time':
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}",
        'comment': isApproved ? '' : (comment ?? ''),
        'approved': isApproved ? 'yes' : 'no',
        'rejected': isApproved ? 'no' : 'yes',
        'name': widget.username,
        'update_existing': true,
      };

      print('Sending payload to API: ${jsonEncode(payload)}');

      final response = await http.post(
        Uri.parse('$baseUrl/submit-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final result = json.decode(response.body);

      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isApproved
                  ? "Approval saved successfully"
                  : "Rejection saved successfully")),
        );
        setState(() {
          searchResult = null;
          barcodeController.clear();
        });
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

  void showRejectDialog() {
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Please specify the reason for rejection"),
        content: TextField(
          controller: commentController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Enter reason here...",
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
              String comment = commentController.text.trim();
              if (comment.isNotEmpty) {
                Navigator.pop(context);
                submitStatus(false, comment);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a reason")),
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
    Widget valueWidget;

    if (label == "Status") {
      valueWidget = value == "Approved"
          ? const Text('Approved',
              style: TextStyle(color: Colors.green, fontSize: 20))
          : value == "Rejected"
              ? const Text('Rejected',
                  style: TextStyle(color: Colors.red, fontSize: 20))
              : const Text("-");
    } else {
      valueWidget = Text(
        value?.toString() ?? '-',
        style: const TextStyle(
            color: Color.fromARGB(255, 60, 122, 229), fontSize: 20),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ",
              style: const TextStyle(fontSize: 18, color: Colors.black87)),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade300, blurRadius: 8)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        "Search Barcode",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: barcodeController,
                    decoration: const InputDecoration(
                      hintText: "Enter barcode here...",
                      border: OutlineInputBorder(),
                      isDense: true,
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 60, 122, 229),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BarcodeScannerPage(),
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
                  )
                ],
              ),
            ),
            if (isLoading) const Center(child: CircularProgressIndicator()),
            if (searchResult != null) ...[
              const Text("📦 Barcode Details",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 10),
              Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      labeledValue("Slip Number", searchResult?['Slip_No']),
                      labeledValue(
                          "Document Number", searchResult?['Document_No']),
                      labeledValue(
                          "Formula Name", searchResult?['Formula_Name']),
                      labeledValue("FG Code", searchResult?['Formula_Code']),
                      labeledValue("Lot Number", searchResult?['Lot_No']),
                      labeledValue("Packing M/c", searchResult?['Pack_No']),
                      labeledValue("Pack Type", searchResult?['Pack_Type']),
                      labeledValue("Bag Weight", searchResult?['Bag_Weight']),
                      labeledValue(
                          "Total Bag No", searchResult?['Total_Bag_No']),
                      labeledValue("Bar Code", searchResult?['Bar_Code']),
                      labeledValue("Staff Name", searchResult?['Name']),
                      labeledValue(
                          "Status",
                          searchResult?['Approved'] == 'yes'
                              ? 'Approved'
                              : searchResult?['Rejected'] == 'yes'
                                  ? 'Rejected'
                                  : '-'),
                      if (searchResult?['Rejected'] == 'yes')
                        labeledValue("Comment", searchResult?['Comment']),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (searchResult?['Approved'] == 'yes') ...[
                ElevatedButton.icon(
                  onPressed: showRejectDialog,
                  icon: const Icon(Icons.close),
                  label: const Text("Change to Rejected"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ] else if (searchResult?['Rejected'] == 'yes') ...[
                ElevatedButton.icon(
                  onPressed: () => submitStatus(true),
                  icon: const Icon(Icons.check),
                  label: const Text("Change to Approved"),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => submitStatus(true),
                        icon: const Icon(Icons.check),
                        label: const Text("Approve"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: showRejectDialog,
                        icon: const Icon(Icons.close),
                        label: const Text("Reject"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                      ),
                    ),
                  ],
                ),
              ]
            ],
          ],
        ),
      ),
    );
  }
}
