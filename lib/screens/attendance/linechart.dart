import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DailyEarnings extends StatelessWidget {
  static Map<int, String> monthMap = const {
    0: 'JAN',
    1: 'FEB',
    2: 'MAR',
    3: 'APR',
    4: 'MAY',
    5: 'JUN',
    6: 'JUL',
    7: 'AUG',
    8: 'SEP',
    9: 'OCT',
    10: 'NOV',
    11: 'DEC',
  };

  static Map<int, String> moneyMap = const {
    0: '',
    1: '10k',
    2: '20k',
    3: '30k',
    4: '40k',
    5: '50k',
    6: '60k',
  };

  List<Color> gradientColors = const [
    Color.fromARGB(255, 5, 122, 189),
    Color(0xff02d39a),
  ];

  DailyEarnings({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Card(
        // color: Constants.purpleLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 3,
        child: Stack(
          children: <Widget>[
            AspectRatio(
              aspectRatio: 1.5,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(18),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                      right: 18.0, left: 12.0, top: 24, bottom: 12),
                  child: LineChart(
                    mainData(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData mainData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color.fromARGB(100, 100, 100, 100),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: const Color.fromARGB(100, 100, 100, 100),
            strokeWidth: 1,
          );
        },
      ),
      /*
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          getTextStyles: (_, value) => const TextStyle(
              color: Color(0xff68737d),
              fontWeight: FontWeight.bold,
              fontSize: 16),
          getTitles: (value) {
            String? month = monthMap[value.toInt()];
            if (month == null) {
              return '';
            }
            return month;
          },
          margin: 8,
        ),
        leftTitles: SideTitles(
          showTitles: true,
          getTextStyles: (_, value) => const TextStyle(
            color: Color(0xff67727d),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          getTitles: (value) {
            String? money = moneyMap[value.toInt()];
            if (money == null) {
              return '';
            }
            return money;
          },
          reservedSize: 28,
          margin: 12,
        ),
      ),
      */
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d), width: 1),
      ),
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: 6,
      lineBarsData: [
        LineChartBarData(
          spots: [
            FlSpot(0, 3),
            FlSpot(2.6, 2),
            FlSpot(4.9, 5),
            FlSpot(6.8, 3.1),
            FlSpot(8, 4),
            FlSpot(9.5, 3),
            FlSpot(11, 4),
          ],
          isCurved: true,
          //colors: gradientColors,
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            //colors:gradientColors.map((color) => color.withOpacity(0.2)).toList(),
          ),
        ),
      ],
    );
  }
}
