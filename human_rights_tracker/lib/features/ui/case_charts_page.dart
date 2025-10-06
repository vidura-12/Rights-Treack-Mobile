import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class CaseChartsPage extends StatefulWidget {
  const CaseChartsPage({super.key});

  @override
  State<CaseChartsPage> createState() => _CaseChartsPageState();
}

class _CaseChartsPageState extends State<CaseChartsPage> {
  Map<String, int> victimCounts = {};
  Map<String, int> abuserCounts = {};
  Map<String, int> locationCounts = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection("cases").get();

      final Map<String, int> vCounts = {};
      final Map<String, int> aCounts = {};
      final Map<String, int> lCounts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Victim Gender
        final victim = (data['victimGender'] ?? "Unknown").toString();
        vCounts[victim] = (vCounts[victim] ?? 0) + 1;

        // Abuser Gender
        final abuser = (data['abuserGender'] ?? "Unknown").toString();
        aCounts[abuser] = (aCounts[abuser] ?? 0) + 1;

        // Location
        final location = (data['location'] ?? "Unknown").toString();
        lCounts[location] = (lCounts[location] ?? 0) + 1;
      }

      setState(() {
        victimCounts = vCounts.isEmpty ? {"No Data": 1} : vCounts;
        abuserCounts = aCounts.isEmpty ? {"No Data": 1} : aCounts;
        locationCounts = lCounts.isEmpty ? {"No Data": 1} : lCounts;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading cases: $e");
      setState(() {
        victimCounts = {"Error": 1};
        abuserCounts = {"Error": 1};
        locationCounts = {"Error": 1};
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Case Charts Summary"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Victim Gender Distribution"),
            SizedBox(height: 250, child: _buildPieChart(victimCounts)),
            const SizedBox(height: 24),
            _buildSectionTitle("Abuser Gender Distribution"),
            SizedBox(height: 250, child: _buildPieChart(abuserCounts)),
            const SizedBox(height: 24),
            _buildSectionTitle("Cases by Location"),
            SizedBox(
              height: 350,
              child: _buildBarChart(locationCounts),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple,
      ),
    );
  }

  // Modern Pie Chart
  Widget _buildPieChart(Map<String, int> counts) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final colors = [Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.red];

    return PieChart(
      PieChartData(
        sections: counts.entries.map((entry) {
          final index = counts.keys.toList().indexOf(entry.key);
          final percent = total == 0 ? 0.0 : (entry.value / total) * 100;
          return PieChartSectionData(
            color: colors[index % colors.length],
            value: entry.value.toDouble(),
            title: "${entry.key}\n${percent.toStringAsFixed(1)}%",
            radius: 80,
            titleStyle: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
            badgeWidget: null,
          );
        }).toList(),
        sectionsSpace: 4,
        centerSpaceRadius: 0,
      ),
    );
  }

  // Modern Bar Chart (scrollable if many locations)
  Widget _buildBarChart(Map<String, int> counts) {
    final colors = [Colors.deepPurple, Colors.orange, Colors.blue, Colors.green, Colors.red];
    final maxY = (counts.values.isNotEmpty ? counts.values.reduce((a, b) => a > b ? a : b) : 1).toDouble() + 1;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: counts.length * 70.0,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 35),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final index = value.toInt();
                    if (index < counts.keys.length) {
                      return RotatedBox(
                        quarterTurns: 1,
                        child: Text(
                          counts.keys.elementAt(index),
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: counts.entries.map((entry) {
              final index = counts.keys.toList().indexOf(entry.key);
              return BarChartGroupData(x: index, barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  color: colors[index % colors.length],
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                  backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxY, color: Colors.grey[200]!),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
