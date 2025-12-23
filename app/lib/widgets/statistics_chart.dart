import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StatisticsChart extends StatelessWidget {
  final List<int> data;

  const StatisticsChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final List<int> chartData = data.isNotEmpty ? data : [0, 0, 0, 0];

    double maxDataValue = (chartData.reduce(
      (curr, next) => curr > next ? curr : next,
    )).toDouble();
    double maxY = maxDataValue < 8 ? 10 : maxDataValue * 1.2;
    return AspectRatio(
      aspectRatio: 1.7,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 30, 16, 12),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),

              barTouchData: BarTouchData(
                enabled: false,
                touchTooltipData: BarTouchTooltipData(
                  // 🔥 SỬA Ở ĐÂY: Dùng tooltipBgColor thay cho getTooltipColor
                  tooltipBgColor: Colors.transparent,
                  tooltipPadding: EdgeInsets.zero,
                  tooltipMargin: 5,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      rod.toY.round().toString(),
                      TextStyle(
                        color: _getColor(group.x.toInt()),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ),

              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      const style = TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                        height: 1.2,
                      );
                      String text;
                      switch (value.toInt()) {
                        case 0:
                          text = 'Chờ\nDuyệt';
                          break;
                        case 1:
                          text = 'Đang\nTrồng';
                          break;
                        case 2:
                          text = 'Thu\nHoạch';
                          break;
                        case 3:
                          text = 'Kho\nHàng';
                          break;
                        default:
                          text = '';
                      }
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          text,
                          style: style,
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ),

              barGroups: [
                _makeGroup(0, chartData[0].toDouble(), 0, maxY),
                _makeGroup(1, chartData[1].toDouble(), 1, maxY),
                _makeGroup(2, chartData[2].toDouble(), 2, maxY),
                _makeGroup(3, chartData[3].toDouble(), 3, maxY),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColor(int index) {
    switch (index) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.purple;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  BarChartGroupData _makeGroup(int x, double y, int colorIndex, double maxY) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: _getColor(colorIndex),
          width: 28,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: _getColor(colorIndex).withOpacity(0.08),
          ),
        ),
      ],
      showingTooltipIndicators: [0],
    );
  }
}
