import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

class ApprovalChart extends StatelessWidget {
  final int accepted;
  final int pending;
  final int rejected;

  const ApprovalChart({
    super.key,
    required this.accepted,
    required this.pending,
    required this.rejected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        buildDonut("Pending", pending, accepted + rejected, Colors.orange),
        buildDonut("Accepted", accepted, pending + rejected, Colors.blue),
        buildDonut("Rejected", rejected, accepted + pending, Colors.red),
      ],
    );
  }

  Widget buildDonut(String label, int count, int others, Color color) {
    double total = count + others.toDouble();
    if (total == 0) total = 1; // ป้องกันหาร 0 // Prevent division by 0
    return Column(
      children: [
        PieChart(
            dataMap: {
              label: count.toDouble(),
              "Other": others.toDouble(),
            },
            chartType: ChartType.ring,
            colorList: [color, Colors.grey.shade300],
            totalValue: total,
            chartRadius: 70,
            ringStrokeWidth: 15,
            centerText: count.toString(),
            chartValuesOptions:
                const ChartValuesOptions(showChartValues: false),
            legendOptions: const LegendOptions(
              showLegends: false, // ปิด legends // close legends  
            )),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
