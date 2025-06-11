import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';


class EditFormPage extends StatefulWidget {
  final String username;
  final Map<String, dynamic>? initialData;

  const EditFormPage({
    super.key,
    required this.username,
    this.initialData,
  });

  @override
  State<EditFormPage> createState() => _EditFormPageState();
}

class _EditFormPageState extends State<EditFormPage> {
  final TextEditingController documentNoController = TextEditingController();
  final TextEditingController formulaNameController = TextEditingController();
  final TextEditingController fgCodeController = TextEditingController();
  final TextEditingController lotNoController = TextEditingController();
  final TextEditingController packingController = TextEditingController();
  final TextEditingController bagsNoController = TextEditingController();
  final TextEditingController bagsWeightController = TextEditingController();
  final TextEditingController mfgDateController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController staffController = TextEditingController();

  String? selectedPDLine;
  String? selectedType;
  int? selectedMonth;
  DateTime? mfgDate;
  

  List<String> pdLines = [
    'Extruder Line 1',
    'Extruder Line 2',
    'Extruder Line 3',
    'Extruder Line 1 & 2',
    'Extruder Line 2 & 3',
    'Extruder Line 1 & 3'
  ];
  List<String> types = ['Finished Goods', 'Repack'];
  List<String> packingTypes = [
    'Packing 1 - Rovema',
    'Packing 2 - Form Fill',
    'Packing 3 - Rotary Pack',
    'Packing 4 - Statec',
    'Packing 6 - Chronos',
  ];

  @override
  void initState() {
    super.initState();
    staffController.text = widget.username;
    final data = widget.initialData;

    if (data != null) {
      documentNoController.text = data['documentNo'] ?? '';
      formulaNameController.text = data['formulaName'] ?? '';
      fgCodeController.text = data['fgCode'] ?? '';
      lotNoController.text = data['lotNo'] ?? '';
      selectedPDLine = data['pdLine'];
      if (selectedPDLine != null && !pdLines.contains(selectedPDLine)) {
        selectedPDLine = null;
      }
      packingController.text = data['packing'] ;
      bagsNoController.text = data['bagsNo'] ?? '';
      bagsWeightController.text = data['bagsWeight'] ?? '';
      selectedType = data['type'];
      mfgDateController.text = data['mfgDate'] ?? '';
      expiryDateController.text = data['expiryDate'] ?? '';
      selectedMonth = data['expiryMonths'];
      barcodeController.text = data['barcode'] ?? '';

      try {
        mfgDate = DateFormat('yyyy-MM-dd').parseStrict(data['mfgDate']);
      } catch (_) {}
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
    return Scaffold(
      appBar: AppBar(title: const Text('Edit information')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildLabel("Document No"),
                TextField(controller: documentNoController, decoration: const InputDecoration(border: OutlineInputBorder())),
                buildLabel("Formula Name"),
                TextField(controller: formulaNameController, decoration: const InputDecoration(border: OutlineInputBorder())),
                buildLabel("FG Code"),
                TextField(controller: fgCodeController, decoration: const InputDecoration(border: OutlineInputBorder())),
                buildLabel("Lot No"),
                TextField(controller: lotNoController, decoration: const InputDecoration(border: OutlineInputBorder())),
                buildLabel("PD Line"),
                DropdownButtonFormField(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: pdLines.toSet().map((line) =>
                      DropdownMenuItem(value: line, child: Text(line))).toList(),
                  value: pdLines.contains(selectedPDLine) ? selectedPDLine : null,
                  onChanged: (value) => setState(() => selectedPDLine = value),
                ),
                buildLabel("Packing"),
                DropdownButtonFormField(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: packingTypes.map((type) =>
                      DropdownMenuItem(value: type, child: Text(type))).toList(),
                  value: packingTypes.contains(packingController.text) ? packingController.text : null,
                  onChanged: (value) => setState(() => packingController.text = value ?? ""),
                ),
                buildLabel("Number of bags and weight"),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: bagsNoController,
                        decoration: const InputDecoration(labelText: "Bags No", border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: bagsWeightController,
                        decoration: const InputDecoration(labelText: "Weight (kg)", border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                buildLabel("Type"),
                DropdownButtonFormField(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: types.map((type) =>
                      DropdownMenuItem(value: type, child: Text(type))).toList(),
                  value: types.contains(selectedType) ? selectedType : null,
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
                            expiryDateController.text = DateFormat('dd/MM/yyyy').format(expiryDate);
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
                TextField(controller: staffController, decoration: const InputDecoration(border: OutlineInputBorder()), readOnly: true),
                buildLabel("Barcode"),
                TextField(controller: barcodeController, decoration: const InputDecoration(border: OutlineInputBorder()), readOnly: true),
                const SizedBox(height: 16),
                buildLabel("Show Barcode"),
                Center(
                  child: BarcodeWidget(
                    barcode: Barcode.code128(),
                    data: barcodeController.text,
                    width: 200,
                    height: 80,
                  ),
                ),

              const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text("Save"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    onPressed: () {
                      // TODO: ใส่ logic การบันทึกข้อมูลตรงนี้  // TODO: Enter the logic for saving data here
                      // เช่น แสดง dialog หรือ print ข้อมูลทั้งหมด  // Such as displaying a dialog box or printing all data
                      final data = {
                        'documentNo': documentNoController.text,
                        'formulaName': formulaNameController.text,
                        'fgCode': fgCodeController.text,
                        'lotNo': lotNoController.text,
                        'pdLine': selectedPDLine,
                        'packing': packingController.text,
                        'bagsNo': bagsNoController.text,
                        'bagsWeight': bagsWeightController.text,
                        'type': selectedType,
                        'mfgDate': mfgDateController.text,
                        'expiryDate': expiryDateController.text,
                        'expiryMonths': selectedMonth,
                        'barcode': barcodeController.text,
                        'staff': staffController.text,
                      };

                      // ตัวอย่าง: แสดง dialog
                      // Example: Show dialog box
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Confirm recording"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("turn off"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                ],
            ),
          ),
        ),
      ),
    );
  }
}