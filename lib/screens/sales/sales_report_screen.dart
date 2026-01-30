import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/order_provider.dart';

class SalesReportScreen extends StatelessWidget {
  const SalesReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<OrderProvider>(
          builder: (context, orderProvider, _) {
            final weeklySales = orderProvider.weeklySales;
            final topItems = orderProvider.topSellingItems;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sales Report',
                        style: GoogleFonts.spectral(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.accentBlue),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('MMM d, yyyy').format(DateTime.now()),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Summary Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: "Today's Revenue",
                          value: 'RM${orderProvider.todayRevenue.toStringAsFixed(0)}',
                          icon: Icons.trending_up_rounded,
                          iconColor: AppColors.success,
                          iconBgColor: AppColors.success.withValues(alpha: 0.1),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SummaryCard(
                          title: "Today's Orders",
                          value: '${orderProvider.todayOrderCount}',
                          icon: Icons.receipt_long_rounded,
                          iconColor: AppColors.accentBlue,
                          iconBgColor: AppColors.accentBlue.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Total Orders',
                          value: '${orderProvider.orders.length}',
                          icon: Icons.shopping_bag_outlined,
                          iconColor: AppColors.warning,
                          iconBgColor: AppColors.warning.withValues(alpha: 0.1),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Avg. Order',
                          value: orderProvider.orders.isNotEmpty
                              ? 'RM${(orderProvider.orders.where((o) => o.status.name == 'completed').fold<double>(0, (s, o) => s + o.totalAmount) / (orderProvider.orders.where((o) => o.status.name == 'completed').length.clamp(1, 999))).toStringAsFixed(0)}'
                              : 'RM0',
                          icon: Icons.analytics_outlined,
                          iconColor: AppColors.primaryBrand,
                          iconBgColor: AppColors.primaryBrand.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Weekly Sales Chart
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Sales',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Last 7 days revenue',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 200,
                          child: weeklySales.values.every((v) => v == 0)
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('📊', style: TextStyle(fontSize: 32)),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No sales data yet',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Generate sample data below',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: weeklySales.values.reduce((a, b) => a > b ? a : b) * 1.3,
                                    barTouchData: BarTouchData(
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                          final day = weeklySales.keys.elementAt(group.x.toInt());
                                          return BarTooltipItem(
                                            '$day\nRM${rod.toY.toStringAsFixed(0)}',
                                            GoogleFonts.inter(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 42,
                                          getTitlesWidget: (value, meta) {
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 8),
                                              child: Text(
                                                'RM${(value / 1000).toStringAsFixed(1)}k',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final idx = value.toInt();
                                            if (idx >= 0 && idx < weeklySales.length) {
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Text(
                                                  weeklySales.keys.elementAt(idx),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    color: AppColors.textSecondary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: weeklySales.values.reduce((a, b) => a > b ? a : b) / 4,
                                      getDrawingHorizontalLine: (value) => FlLine(
                                        color: AppColors.divider,
                                        strokeWidth: 1,
                                      ),
                                    ),
                                    barGroups: weeklySales.entries.toList().asMap().entries.map((entry) {
                                      return BarChartGroupData(
                                        x: entry.key,
                                        barRods: [
                                          BarChartRodData(
                                            toY: entry.value.value,
                                            color: AppColors.accentBlue,
                                            width: 20,
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(6),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Top Selling Items
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top Selling Items',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (topItems.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'No sales data yet',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        else
                          ...topItems.entries.toList().asMap().entries.map((entry) {
                            final rank = entry.key + 1;
                            final name = entry.value.key;
                            final count = entry.value.value;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: entry.key < topItems.length - 1 ? 12 : 0,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: rank <= 3
                                          ? AppColors.accentBlue.withValues(alpha: 0.1)
                                          : AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$rank',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: rank <= 3 ? AppColors.accentBlue : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$count sold',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Generate Sample Data Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<OrderProvider>().generateSampleData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  'Sample data generated!',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(
                        'Generate Sample Sales Data',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentBlue,
                        side: BorderSide(color: AppColors.accentBlue.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
