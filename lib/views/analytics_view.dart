import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../controllers/analytics_controller.dart';
import '../controllers/wallet_controller.dart';
import '../views/wallet_page.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final AnalyticsController controller = AnalyticsController();

  String selectedMode = "Month"; // Month or Year
  int _selectedIndex = 2;

  double smartInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 100;

    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    // Round maxY to a clean value
    double cleanMax = (maxY / 100).ceil() * 100;

    // Ideal intervals: 5 grid lines
    double interval = cleanMax / 5;

    // Keep clean numbers (100, 200, 500, 1000, 2000…)
    if (interval < 100) interval = 50;
    if (interval < 50) interval = 20;

    return interval;
  }


  LineChartData monthChartData() {
    final data = controller.getMonthlyData();
    if (data.isEmpty) {
      return LineChartData(
        lineBarsData: [],
        titlesData: FlTitlesData(show: false),
      );
    }



    final spots = data.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    return LineChartData(
      minX: spots.first.x,
      maxX: spots.last.x,
      minY: 0,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        horizontalInterval: 500, // adjust for months
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          );
        },
      ),

      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 3,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          color: Colors.red,
        ),
      ],
    );
  }
  LineChartData yearChartData() {
    final data = controller.getYearlyData();
    String formatNumber(double value) {
      if (value >= 1000) {
        return "${(value / 1000).toStringAsFixed(1)}k";
      }
      return value.toInt().toString();
    }

    double calculateInterval(List<FlSpot> spots) {
      if (spots.isEmpty) return 1000;

      double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

      if (maxY <= 1000) return 200;
      if (maxY <= 5000) return 1000;
      if (maxY <= 10000) return 2000;
      return maxY / 5;
    }


    if (data.isEmpty) {
      return LineChartData(
        lineBarsData: [],
        titlesData: FlTitlesData(show: false),
      );
    }


    final spots = data.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    const monthNames = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];

    return LineChartData(
      minX: 1,
      maxX: 12,
      minY: 0,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        horizontalInterval: calculateInterval(spots),
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (index < 1 || index > 12) return const SizedBox();
              return Text(monthNames[index - 1], style: const TextStyle(fontSize: 10));
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: calculateInterval(spots),
            reservedSize: 40, // prevents overlap
            getTitlesWidget: (value, meta) {
              return Text(
                formatNumber(value),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),

      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          barWidth: 3,
          dotData: const FlDotData(show: true),

          gradient: const LinearGradient(
            colors: [
              Colors.red,
              Colors.orange,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),

          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.red.withOpacity(0.25),
                Colors.orange.withOpacity(0.05),
              ],
            ),
          ),
        ),
      ],

    );
  }


  @override
  void initState() {
    super.initState();

    /// WAIT for widget to mount before accessing Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final walletCtrl = context.read<WalletController>();

    // Load wallet balance from WalletController
    controller.setWallet(walletCtrl.walletBalance);

    // Load transactions for analytics
    controller.setTransactions(walletCtrl.transactions);

    setState(() {});
  }

  // --------------------------- NAV HANDLER ---------------------------

  void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WalletPage()),
      );
    } else if (index == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Calculator page not yet implemented")),
      );
    } else if (index == 2) {
      // already here
    } else if (index == 3) {
      // Exit or logout
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.black54,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Calculator',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.exit_to_app),
            label: 'Exit',
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 12),

              _buildTotalSpentContainer(),
              const SizedBox(height: 12),

              _buildToggleBar(),
              const SizedBox(height: 12),

              _buildLineGraphSection(),
              const SizedBox(height: 12),

              _buildPieChartSection(),
              const SizedBox(height: 12),

              _buildWalletSection(),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------- UI SECTIONS ---------------------------

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const WalletPage()),
              );
            },
            child: const Icon(Icons.arrow_back_ios_new, size: 28),
          ),

          const Text(
            "Total Spent Analysis",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          Image.asset('assets/logo.png', height: 35),
        ],
      ),
    );
  }

  Widget _buildTotalSpentContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.shopping_bag, color: Colors.red.shade400, size: 38),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Expense (This Month)",
                  style: TextStyle(fontSize: 14, color: Colors.red)),
              Text(
                "₱${controller.thisMonthExpense.toStringAsFixed(2)}",
                style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildToggleBar() {
    return Row(
      children: [
        const SizedBox(width: 20),
        _toggleOption("Month"),
        const SizedBox(width: 10),
        _toggleOption("Year"),
      ],
    );
  }

  Widget _toggleOption(String label) {
    bool selected = selectedMode == label;

    return GestureDetector(
      onTap: () => setState(() => selectedMode = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.grey.shade700 : Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLineGraphSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Last Month:", style: TextStyle(fontSize: 12)),
                  Text(
                    "₱${controller.lastMonthExpense.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              ColoredBox(
                color: controller.percentIncrease >= 0
                    ? Colors.red
                    : Colors.green,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: Text(
                    "${controller.percentIncrease.toStringAsFixed(2)}%",
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("This Month:", style: TextStyle(fontSize: 12)),
                  Text(
                    "₱${controller.thisMonthExpense.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
              child: LineChart(
                selectedMode == "Month"
                    ? monthChartData()
                    : yearChartData(),
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),

      child: Row(
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text("Pie")),
          ),
          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    CircleAvatar(radius: 6, backgroundColor: Colors.red),
                    SizedBox(width: 8),
                    Text("Online Shopping", style: TextStyle(fontSize: 14)),
                  ],
                ),
                SizedBox(height: 12),
                Text("Total Highest Spent:", style: TextStyle(fontSize: 14)),
                SizedBox(height: 5),
                ColoredBox(
                  color: Color(0xffffd5d5),
                  child: Padding(
                    padding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      "Online Shopping",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
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

  Widget _buildWalletSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Wallet", style: TextStyle(fontSize: 18)),
            Text(
              "₱${controller.walletAmount.toStringAsFixed(2)}",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
