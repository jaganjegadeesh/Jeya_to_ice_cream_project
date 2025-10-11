import 'package:aj_maintain/service/service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:aj_maintain/theme/theme.dart';
import 'package:intl/intl.dart';

class BarChartSample1 extends StatefulWidget {
  BarChartSample1({super.key});

  final Color barBackgroundColor = Colors.black12;
  final Color barColor = AppColors.amber700;
  final Color touchedBarColor = AppColors.greenColor;

  @override
  State<StatefulWidget> createState() => _BarChartSample1State();
}

class _BarChartSample1State extends State<BarChartSample1> {
  int touchedIndex = -1;
  bool isLoading = true;
  List<Map<String, dynamic>> last7DaysData = [];

  final List<String> weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  final ChartService _service = ChartService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    // Fetch last 7 days collections with 0s for missing days
    List<Map<String, dynamic>> data = await _service
        .getLastSevenDaysCollections();

    // Rotate data so last bar is today
    int todayIndex = DateTime.now().weekday - 1; // 0-based
    last7DaysData = List.generate(7, (i) {
      int index = (i + data.length - 7) % 7; // ensures 7 items
      return data[index];
    });

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 50,),
        AspectRatio(
          aspectRatio: 1.25,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : BarChart(mainBarData()),
          ),
        ),
      ],
    );
  }

  BarChartGroupData makeGroupData(
    int x,
    double y, {
    bool isTouched = false,
    Color? barColor,
    double width = 22,
  }) {
    barColor ??= widget.barColor;

    double maxY = last7DaysData.isNotEmpty
        ? last7DaysData
              .map((e) => (e["total_amount"] ?? 0).toDouble())
              .reduce((a, b) => a > b ? a : b)
        : 20;

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y, // <-- don't modify y here for touch
          color: isTouched ? widget.touchedBarColor : barColor,
          width: width,
          borderSide: BorderSide(
            color: isTouched ? widget.touchedBarColor : Colors.transparent,
            width: 1,
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: widget.barBackgroundColor,
          ),
        ),
      ],
    );
  }

  BarChartData mainBarData() {
    final List<BarChartGroupData> groups = [];

    // Rotate weekdays to match today
    int todayIndex = DateTime.now().weekday - 1;
    final rotatedDays = List.generate(7, (i) {
      int dayIndex = (todayIndex - 6 + i) % 7;
      if (dayIndex < 0) dayIndex += 7;
      return weekDays[dayIndex];
    });

    for (int i = 0; i < 7; i++) {
      double amount = last7DaysData[i]["total_amount"]?.toDouble() ?? 0;
      groups.add(makeGroupData(i, amount, isTouched: i == touchedIndex));
    }

    return BarChartData(
      barGroups: groups,
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
      barTouchData: BarTouchData(
        enabled: true,
        handleBuiltInTouches: true, // <-- make sure this is true
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) => const Color.fromARGB(255, 150, 203, 247),
          tooltipPadding: const EdgeInsets.all(8),
          tooltipMargin: 8,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final data = last7DaysData[groupIndex];
            String dateStr = data["date"] ?? "";
            double amount = (data["total_amount"] ?? 0).toDouble();
            String formattedDate = "";
            try {
              formattedDate = DateFormat(
                'dd MMM',
              ).format(DateTime.parse(dateStr));
            } catch (_) {}

            return BarTooltipItem(
              '${rotatedDays[groupIndex]} ($formattedDate)\n₹${amount.toStringAsFixed(2)}',
              const TextStyle(color: Colors.black87, fontSize: 14),
            );
          },
        ),
        touchCallback: (event, response) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                response == null ||
                response.spot == null) {
              touchedIndex = -1;
            } else {
              touchedIndex = response.spot!.touchedBarGroupIndex;
            }
          });
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) =>
                getTitles(value, meta, rotatedDays),
            reservedSize: 38,
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
    );
  }

  Widget getTitles(double value, TitleMeta meta, List<String> rotatedDays) {
    const style = TextStyle(
      color: Colors.black54,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text = rotatedDays[value.toInt()];
    return SideTitleWidget(
      meta: meta,
      space: 12,
      child: Text(text, style: style),
    );
  }
}
