import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'edit.dart'; // อย่าลืม import //Don't forget to import

Future<List<Map<String, dynamic>>> fetchPalletSlipData() async {
  List<Map<String, dynamic>> palletSlipData = [];

  try {
    final response = await http.get(Uri.parse('http://10.0.2.2:5000/palletslip')); // 🔁 แก้เป็น IP ถ้ารันบนมือถือ // 🔁 Change to IP if using on mobile.
    if (response.statusCode == 200) {
      palletSlipData = List<Map<String, dynamic>>.from(json.decode(response.body)['data']);
    } else {
      print('Failed to load data');
    }
  } catch (e) {
    print('Error fetching data: $e');
  }

  return palletSlipData;
}

class PalletSlipPage extends StatefulWidget {
  const PalletSlipPage({super.key});

  @override
  State<PalletSlipPage> createState() => _PalletSlipPageState();
}

class _PalletSlipPageState extends State<PalletSlipPage> {
  List<Map<String, dynamic>> palletSlipData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    palletSlipData = await fetchPalletSlipData();
    setState(() {
      isLoading = false;
    });
  }

  void navigateToEditPage(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFormPage(
          username: 'admin',
          initialData: {
            'documentNo': item['Document_No'],
            'formulaName': item['Formula_Name'],
            'fgCode': item['Formula_Code'],
            'lotNo': item['Lot_No'],
            'pdLine': item['PD_Line'],
            'packing': item['Pack_No'] ?? 'Packing 1 - Auto',
            'bagsNo': item['Total_Bag_No'].toString(),
            'bagsWeight': item['TotalWeight'].toString(),
            'type': 'Finished Goods',
            'mfgDate': item['MFG_Date']?.toString().substring(0, 10) ?? '',
            'expiryDate': item['Expiry_Date']?.toString().substring(0, 10) ?? '',
            'expiryMonths': 12,
            'barcode': item['Bar_Code'] ?? '',
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pallet Slip Data')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : palletSlipData.isEmpty
              ? const Center(child: Text('No information found'))
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 1200),
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Slip No')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Document No')),
                          DataColumn(label: Text('Pack No')),
                          DataColumn(label: Text('Formula Code')),
                          DataColumn(label: Text('Formula Name')),
                          DataColumn(label: Text('PD Line')),
                          DataColumn(label: Text('Lot No')),
                          DataColumn(label: Text('Pack No')),
                          DataColumn(label: Text('Bag Weight')),
                          DataColumn(label: Text('Total Bags')),
                          DataColumn(label: Text('Total Weight')),
                          DataColumn(label: Text('MFG Date')),
                          DataColumn(label: Text('Expiry Date')),
                          DataColumn(label: Text('Staff')),
                          DataColumn(label: Text('Barcode')),
                        ],
                        rows: palletSlipData.map((item) {
                          return DataRow(cells: [
                            DataCell(GestureDetector(
                              onTap: () => navigateToEditPage(item),
                              child: Text('${item['Slip_No']}'),
                            )),
                            DataCell(Text(item['Date']?.toString().substring(0, 10) ?? '')),
                            DataCell(Text('${item['Document_No'] ?? ''}')),
                            DataCell(Text('${item['Pack_No'] ?? ''}')),
                            DataCell(Text('${item['Formula_Code'] ?? ''}')),
                            DataCell(Text('${item['Formula_Name'] ?? ''}')),
                            DataCell(Text('${item['PD_Line'] ?? ''}')),
                            DataCell(Text('${item['Lot_No'] ?? ''}')),
                            DataCell(Text('${item['Pack_Type'] ?? ''}')),
                            DataCell(Text('${item['Bag_Weight'] ?? ''}')),
                            DataCell(Text('${item['Total_Bag_No'] ?? ''}')),
                            DataCell(Text('${item['TotalWeight'] ?? ''}')),
                            DataCell(Text(item['MFG_Date']?.toString().substring(0, 10) ?? '')),
                            DataCell(Text(item['Expiry_Date']?.toString().substring(0, 10) ?? '')),
                            DataCell(Text('${item['Staff_Name'] ?? ''}')),
                            DataCell(Text('${item['Bar_Code'] ?? ''}')),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
    );
  }
}
