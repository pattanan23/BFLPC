import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';

class DataFormPage extends StatefulWidget {
  final String username;

  const DataFormPage({super.key, required this.username});

  @override
  State<DataFormPage> createState() => _DataFormPageState();
}

class _DataFormPageState extends State<DataFormPage> {
  final TextEditingController fgCodeController = TextEditingController();
  final TextEditingController lotNoController = TextEditingController();
  final TextEditingController packingController = TextEditingController();
  final TextEditingController bagsNoController = TextEditingController();
  final TextEditingController bagsWeightController = TextEditingController();
  final TextEditingController mfgDateController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController staffController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController documentNoController = TextEditingController();
  final TextEditingController formulaNameController = TextEditingController();

  String? selectedPDLine;
  String? selectedType;
  List<String> pdLines = [// List of PD lines
    'Extruder Line 1',
    'Extruder Line 2',
    'Extruder Line 3',
    'Extruder Line 1 & 2',
    'Extruder Line 2 & 3',
    'Extruder Line 1 & 3'
  ];
  List<String> types = ['Finished Goods', 'Repack'];// List of types
  List<String> packingTypes = [
    'Packing 1 - Rovema',// List of packing types
    'Packing 2 - Form Fill',
    'Packing 3 - Rotary Pack',
    'Packing 4 - Statec',
    'Packing 6 - Chronos',
  ];

  DateTime? mfgDate;
  int? selectedMonth;
  String? firstGeneratedBarcode;

  @override
  void initState() {
    super.initState();
    staffController.text = widget.username;
    generateBarcode();
  }

  void generateBarcode() {
    final random = Random();
    String base = '';
    for (int i = 0; i < 12; i++) {
      base += random.nextInt(10).toString();
    }
    barcodeController.text = base;
  }

  Future<int> getLastSlipNo(String pdLine) async {
    final uri = Uri.parse(
        'http://10.0.2.2:5000/last-slip-no?pdline=${Uri.encodeComponent(pdLine)}');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return (jsonResponse['last_slip_no'] ?? 0) as int;
    } else {
      return 0;
    }
  }

  Future<void> submitForm() async {
    String formattedMfgDate =
        DateFormat('yyyy-MM-dd').format(mfgDate ?? DateTime.now());

    String formattedExpiryDate = '';
    try {
      final parsedExpiryDate =
          DateFormat('dd/MM/yyyy').parseStrict(expiryDateController.text);
      formattedExpiryDate = DateFormat('yyyy-MM-dd').format(parsedExpiryDate);
    } catch (_) {
      formattedExpiryDate = '';
    }

    List<int>? expiryMonths = selectedMonth != null ? [selectedMonth!] : null;

    int? saveCount = await showDialog<int>(
      context: context,
      builder: (context) {
        int? selectedCount;
        return AlertDialog(
          title: const Text("Number of recording times"),
          content: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              selectedCount = int.tryParse(value);
            },
            decoration: const InputDecoration(
              hintText: "Please specify the number of times.",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(selectedCount);
              },
              child: const Text("confirm"),
            ),
          ],
        );
      },
    );

    if (saveCount == null || saveCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please specify the number of times you want to record.")),
      );
      return;
    }

    int slipNo = 1;
    if (selectedPDLine != null) {
      slipNo = await getLastSlipNo(selectedPDLine!) + 1;
    }

    for (int i = 0; i < saveCount; i++) {
      generateBarcode();

      if (i == 0) {
        setState(() {
          firstGeneratedBarcode = barcodeController.text;
        });
      }

      final uri = Uri.parse('http://10.0.2.2:5000/submit-form');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "FGCode": fgCodeController.text,
          "LotNo": lotNoController.text,
          "PDLine": selectedPDLine ?? 'Extruder Line 1',// pd line
          "Packing": packingController,// pack no
          "BagsNo": bagsNoController.text,
          "BagsWeight": bagsWeightController.text,
          "Type": selectedType ?? 'Finished Goods',// type
          "MFGDate": formattedMfgDate,
          "Expiry": formattedExpiryDate,
          "ExpiryMonths": expiryMonths,
          "Staff": staffController.text,
          "Barcode": barcodeController.text,
          "SlipNo": slipNo.toString(),
          "DocumentNo": documentNoController.text,
          "FormulaName": formulaNameController.text,
        }),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.statusCode == 200
              ? "✅Data was successfully sent time ${i + 1}"
              : "❌ Failed to send (${response.statusCode})"),
          backgroundColor:
              response.statusCode == 200 ? Colors.green : Colors.red,
        ),
      );

      slipNo++;
    }
  }

  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "📋 Data recording form",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent),
                ),
              ),
              const SizedBox(height: 16),
              buildLabel("Document No"),
              TextField(
                controller: documentNoController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              buildLabel("Formula Name"),
              TextField(
                controller: formulaNameController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),

              buildLabel("FG Code"),
              TextField(
                controller: fgCodeController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              
              buildLabel("Lot No"),
              TextField(
                controller: lotNoController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              buildLabel("PD Line"),
              DropdownButtonFormField(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: pdLines
                    .map((line) =>
                        DropdownMenuItem(value: line, child: Text(line)))
                    .toList(),
                value: selectedPDLine,
                onChanged: (value) => setState(() => selectedPDLine = value),
              ),
              buildLabel("Packing"),
              DropdownButtonFormField(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: packingTypes
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                value: packingController.text.isNotEmpty
                    ? packingController.text
                    : null,
                onChanged: (value) =>
                    setState(() => packingController.text = value ?? ""),
              ),
              buildLabel("Bags No and Weight"),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: bagsNoController,
                      decoration: const InputDecoration(
                          labelText: "Bags No", border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: bagsWeightController,
                      decoration: const InputDecoration(
                          labelText: "Weight (kg)",
                          border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              buildLabel("Type"),
              DropdownButtonFormField(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: types
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                value: selectedType,
                onChanged: (value) => setState(() => selectedType = value),
              ),
              buildLabel("MFG Date (dd/MM/yyyy)"),
              TextField(
                controller: mfgDateController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (value) {
                  try {
                    mfgDate = DateFormat('dd/MM/yyyy').parseStrict(value);
                  } catch (_) {
                    mfgDate = null;
                  }
                },
              ),
              buildLabel("Expiry Date"),
              TextField(
                controller: expiryDateController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                readOnly: true,
              ),
              buildLabel("Product age (months)"),
              Wrap(
                spacing: 10,
                children: [12, 18, 24].map((m) {
                  return FilterChip(
                    label: Text("$m months"),
                    selected: selectedMonth == m,
                    onSelected: (bool selected) {
                      setState(() {
                        selectedMonth = selected ? m : null;
                        if (mfgDate != null && selected) {
                          final expiryDate = DateTime(
                            mfgDate!.year,
                            mfgDate!.month + m,
                            mfgDate!.day,
                          );
                          final formatted =
                              DateFormat('dd/MM/yyyy').format(expiryDate);
                          expiryDateController.text = formatted;
                        } else {
                          expiryDateController.clear();
                        }
                      });
                    },
                    selectedColor: Colors.blueAccent.withOpacity(0.3),
                  );
                }).toList(),
              ),
              buildLabel("Staff"),    
              TextField(
                controller: staffController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                readOnly: true,
              ),
              buildLabel("Barcode (Auto-Gen)"),
              TextField(
                controller: barcodeController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              buildLabel("Show Barcode"),
              Center(
                child: Column(
                  children: [
                    BarcodeWidget(
                      barcode: Barcode.ean13(),
                      data: barcodeController.text.padLeft(12, '0'),
                      width: 200,
                      height: 80,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: submitForm,
                  icon: const Icon(Icons.save),
                  label: const Text("Submit"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
