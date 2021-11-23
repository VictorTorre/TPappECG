import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class EcgPartialView extends StatefulWidget {
  EcgPartialView({Key? key}) : super(key: key);

  @override
  _EcgPartialView createState() => _EcgPartialView();
}

class _EcgPartialView extends State<EcgPartialView> {
  final Color colorLine = Colors.redAccent;

  final limitCount = 100;
  final points = <FlSpot>[];

  double xValue = 0;
  double step = 0.04;

  late Timer timer;

  List<int> testData = <int>[
    -198,
    -206,
    -203,
    -206,
    -215,
    -206,
    -201,
    -218,
    -218,
    -208,
    -225,
    -240,
    -227,
    -220,
    -215,
    -194,
    -184,
    -194,
    -196,
    -196,
    -191,
    -174,
    -169,
    -184,
    -196,
    -186,
    -152,
    -116,
    -101,
    -128,
    -155,
    -157,
    -150,
    -150,
    -150,
    -157,
    -189,
    -206,
    -186,
    -143,
    -9,
    264,
    417,
    106,
    -375,
    -446,
    -257,
    -225,
    -254,
    -227,
    -225,
    -240,
    -237,
    -249,
    -259,
    -252,
    -252,
    -254,
    -242,
    -225,
    -215,
    -210,
    -208,
    -206,
    -196,
    -184,
    -181,
    -198,
    -203,
    -184,
    -174,
    -172,
    -164
  ];

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      while (points.length > limitCount) {
        points.removeAt(0);
      }
      for (var i = 0; i < testData.length; i++) {
        points.add(FlSpot(xValue, testData[i] / 1000.0));
        xValue += step;
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: points.isNotEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'x: ${xValue.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                SizedBox(
                  width: 300,
                  height: 300,
                  child: LineChart(
                    LineChartData(
                      minY: -1,
                      maxY: 1,
                      minX: points.first.x,
                      maxX: points.last.x,
                      lineTouchData: LineTouchData(enabled: false),
                      clipData: FlClipData.all(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                      lineBarsData: [
                        line(points),
                      ],
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: SideTitles(
                          showTitles: false,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            )
          : Container(),
    );
  }

  LineChartBarData line(List<FlSpot> points) {
    return LineChartBarData(
      spots: points,
      dotData: FlDotData(
        show: false,
      ),
      colors: [colorLine.withOpacity(0), colorLine],
      colorStops: [0.1, 1.0],
      barWidth: 4,
      isCurved: false,
    );
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }
}
