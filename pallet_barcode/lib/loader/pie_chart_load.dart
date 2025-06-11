import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

class LoaderStatusChart extends StatelessWidget {
  final int checkIn;
  final int checkOut;
  final int notChecked;

  const LoaderStatusChart({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.notChecked,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        buildDonut("Load_In", checkIn, checkOut + notChecked, Colors.green),
        buildDonut("Load_Out", checkOut, checkIn + notChecked, Colors.blue),
        buildDonut("Not loaded yet", notChecked, checkIn + checkOut, Colors.orange),
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
            showLegends: false,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
