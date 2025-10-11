import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class CaseChartsPage extends StatefulWidget {
  final bool isDarkTheme;

  const CaseChartsPage({super.key, required this.isDarkTheme});

  @override
  State<CaseChartsPage> createState() => _CaseChartsPageState();
}

class _CaseChartsPageState extends State<CaseChartsPage> with SingleTickerProviderStateMixin {
  Map<String, int> victimCounts = {};
  Map<String, int> abuserCounts = {};
  Map<String, int> locationCounts = {};
  Map<String, int> caseTypeCounts = {};
  int totalCases = 0;
  bool isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Modern theme colors
  Color get _backgroundColor => widget.isDarkTheme ? const Color(0xFF0F1419) : const Color(0xFFF8FAFC);
  Color get _cardColor => widget.isDarkTheme ? const Color(0xFF1C2128) : Colors.white;
  Color get _textColor => widget.isDarkTheme ? Colors.white : Colors.black87;
  Color get _secondaryTextColor => widget.isDarkTheme ? Colors.grey[400]! : Colors.grey[600]!;
  Color get _accentColor => const Color(0xFF6366F1);
  Color get _chartBackgroundColor => widget.isDarkTheme ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9);
  
  final List<Color> chartColors = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFFEC4899), // Pink
    const Color(0xFF10B981), // Green
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFF3B82F6), // Blue
    const Color(0xFFEF4444), // Red
    const Color(0xFF14B8A6), // Teal
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection("cases").get();

      final Map<String, int> vCounts = {};
      final Map<String, int> aCounts = {};
      final Map<String, int> lCounts = {};
      final Map<String, int> cCounts = {};

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

        // Case Type
        final caseType = (data['abuseType'] ?? data['caseType'] ?? "Other").toString();
        cCounts[caseType] = (cCounts[caseType] ?? 0) + 1;
      }

      setState(() {
        victimCounts = vCounts.isEmpty ? {"No Data": 1} : vCounts;
        abuserCounts = aCounts.isEmpty ? {"No Data": 1} : aCounts;
        locationCounts = lCounts.isEmpty ? {"No Data": 1} : lCounts;
        caseTypeCounts = cCounts.isEmpty ? {"No Data": 1} : cCounts;
        totalCases = snapshot.docs.length;
        isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      debugPrint("Error loading cases: $e");
      setState(() {
        victimCounts = {"Error": 1};
        abuserCounts = {"Error": 1};
        locationCounts = {"Error": 1};
        caseTypeCounts = {"Error": 1};
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.analytics, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Case Analytics',
              style: TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _accentColor),
                  const SizedBox(height: 16),
                  Text(
                    'Loading analytics...',
                    style: TextStyle(color: _secondaryTextColor),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: _accentColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Cards
                      _buildSummaryCards(),
                      const SizedBox(height: 24),

                      // Victim Gender Distribution
                      _buildChartCard(
                        title: "Victim Gender Distribution",
                        icon: Icons.people_outline,
                        child: SizedBox(
                          height: 280,
                          child: _buildPieChart(victimCounts),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Abuser Gender Distribution
                      _buildChartCard(
                        title: "Abuser Gender Distribution",
                        icon: Icons.person_outline,
                        child: SizedBox(
                          height: 280,
                          child: _buildPieChart(abuserCounts),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Case Types
                      _buildChartCard(
                        title: "Cases by Type",
                        icon: Icons.category_outlined,
                        child: SizedBox(
                          height: 320,
                          child: _buildBarChart(caseTypeCounts),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Location Distribution
                      _buildChartCard(
                        title: "Cases by Location",
                        icon: Icons.location_on_outlined,
                        child: SizedBox(
                          height: 320,
                          child: _buildBarChart(locationCounts),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Legend
                      _buildLegendCard(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: "Total Cases",
            value: totalCases.toString(),
            icon: Icons.folder_outlined,
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: "Locations",
            value: locationCounts.length.toString(),
            icon: Icons.location_on_outlined,
            gradient: const LinearGradient(
              colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: "Types",
            value: caseTypeCounts.length.toString(),
            icon: Icons.category_outlined,
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF34D399)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: _textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> counts) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: counts.entries.map((entry) {
                final index = counts.keys.toList().indexOf(entry.key);
                final percent = total == 0 ? 0.0 : (entry.value / total) * 100;
                return PieChartSectionData(
                  color: chartColors[index % chartColors.length],
                  value: entry.value.toDouble(),
                  title: "${percent.toStringAsFixed(1)}%",
                  radius: 70,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
              sectionsSpace: 3,
              centerSpaceRadius: 50,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: counts.entries.map((entry) {
              final index = counts.keys.toList().indexOf(entry.key);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: chartColors[index % chartColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${entry.value} cases',
                            style: TextStyle(
                              color: _secondaryTextColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(Map<String, int> counts) {
    if (counts.isEmpty) return const SizedBox();

    final maxY = (counts.values.reduce((a, b) => a > b ? a : b)).toDouble() + 2;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: counts.length * 80.0 < 300 ? 300 : counts.length * 80.0,
        child: Padding(
          padding: const EdgeInsets.only(right: 16, top: 16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => _cardColor,
                  tooltipBorder: BorderSide(
                    color: widget.isDarkTheme
                        ? Colors.grey[700]!
                        : Colors.grey[300]!,
                  ),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${counts.values.elementAt(groupIndex)}',
                      TextStyle(
                        color: _textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 100,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final index = value.toInt();
                      if (index < counts.keys.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: RotatedBox(
                            quarterTurns: 1,
                            child: Text(
                              counts.keys.elementAt(index),
                              style: TextStyle(
                                fontSize: 12,
                                color: _textColor,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: widget.isDarkTheme
                        ? Colors.grey[800]!
                        : Colors.grey[200]!,
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: counts.entries.map((entry) {
                final index = counts.keys.toList().indexOf(entry.key);
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.toDouble(),
                      gradient: LinearGradient(
                        colors: [
                          chartColors[index % chartColors.length],
                          chartColors[index % chartColors.length].withOpacity(0.7),
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: 32,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY,
                        color: _chartBackgroundColor,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: _accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Analytics Info',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This page provides statistical analysis of all reported cases. Data is updated in real-time and can be refreshed by pulling down.',
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.tips_and_updates, color: _accentColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap on chart elements for detailed information',
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}