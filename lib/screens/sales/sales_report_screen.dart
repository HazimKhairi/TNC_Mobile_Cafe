import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/cart_item.dart';
import '../../models/drink.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../widgets/linen_background.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2, 1, 1),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBrand,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  // ── Per-date computed metrics ──

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  double _revenueOn(List<Order> orders, DateTime date) => orders
      .where((o) =>
          _sameDay(o.createdAt, date) && o.status == OrderStatus.completed)
      .fold(0.0, (sum, o) => sum + o.totalAmount);

  int _orderCountOn(List<Order> orders, DateTime date) =>
      orders.where((o) => _sameDay(o.createdAt, date)).length;

  /// 7 days ending on [endDate]
  Map<String, double> _weeklySalesEndingOn(
      List<Order> orders, DateTime endDate) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final Map<String, double> sales = {};
    for (int i = 6; i >= 0; i--) {
      final d = endDate.subtract(Duration(days: i));
      final dayName = days[d.weekday - 1];
      sales[dayName] = _revenueOn(orders, d);
    }
    return sales;
  }

  /// Demo dataset used only when there are no real orders yet, so every
  /// section on this report (revenue, orders, avg, top items, weekly chart)
  /// stays consistent with each other.
  List<Order> _demoOrders(DateTime anchor) {
    final drinks = <Drink>[
      Drink(
          id: 'd1',
          name: 'Iced Caramel Latte',
          description: '',
          basePrice: 12,
          categoryId: 'demo',
          imageEmoji: '🥤'),
      Drink(
          id: 'd2',
          name: 'Cappuccino',
          description: '',
          basePrice: 10,
          categoryId: 'demo',
          imageEmoji: '☕'),
      Drink(
          id: 'd3',
          name: 'Matcha Latte',
          description: '',
          basePrice: 13,
          categoryId: 'demo',
          imageEmoji: '🍵'),
      Drink(
          id: 'd4',
          name: 'Chocolate Frappe',
          description: '',
          basePrice: 15,
          categoryId: 'demo',
          imageEmoji: '🍫'),
      Drink(
          id: 'd5',
          name: 'Espresso',
          description: '',
          basePrice: 8,
          categoryId: 'demo',
          imageEmoji: '⚡'),
      Drink(
          id: 'd6',
          name: 'Hazelnut Mocha',
          description: '',
          basePrice: 14,
          categoryId: 'demo',
          imageEmoji: '🌰'),
    ];

    // Orders per day for the 7-day window ending on [anchor] (rising to weekend).
    const dayCounts = [8, 12, 10, 15, 18, 24, 14];
    final orders = <Order>[];
    int seq = 0;
    for (int i = 6; i >= 0; i--) {
      final day = anchor.subtract(Duration(days: i));
      final count = dayCounts[6 - i];
      for (int k = 0; k < count; k++) {
        final drinkA = drinks[seq % drinks.length];
        final drinkB = drinks[(seq + 2) % drinks.length];
        final items = <CartItem>[
          CartItem(
            id: drinkA.id,
            drink: drinkA,
            selectedSize: DrinkSize(label: 'Regular', priceAdd: 0),
            quantity: 1 + (seq % 2),
          ),
          if (k % 3 == 0)
            CartItem(
              id: drinkB.id,
              drink: drinkB,
              selectedSize: DrinkSize(label: 'Large', priceAdd: 2),
              quantity: 1,
            ),
        ];
        orders.add(Order(
          id: 'demo-$seq',
          items: items,
          totalAmount: items.fold(0.0, (s, it) => s + it.totalPrice),
          createdAt: DateTime(day.year, day.month, day.day, 9 + (k % 10)),
          status: OrderStatus.completed,
          orderNumber: 1000 + seq,
          paymentStatus: PaymentStatus.approved,
        ));
        seq++;
      }
    }
    return orders;
  }

  /// Top 5 selling items for orders on [date]
  Map<String, int> _topItemsOn(List<Order> orders, DateTime date) {
    final Map<String, int> counts = {};
    for (final o in orders.where((o) =>
        _sameDay(o.createdAt, date) && o.status == OrderStatus.completed)) {
      for (final item in o.items) {
        counts[item.drink.name] =
            (counts[item.drink.name] ?? 0) + item.quantity;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(5));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LinenBackground(
        child: SafeArea(
          child: Consumer<OrderProvider>(
            builder: (context, orderProvider, _) {
              final orders = orderProvider.orders.isEmpty
                  ? _demoOrders(_selectedDate)
                  : orderProvider.orders;
              final weeklySales = _weeklySalesEndingOn(orders, _selectedDate);
              final topItems = _topItemsOn(orders, _selectedDate);
              final revenue = _revenueOn(orders, _selectedDate);
              final orderCount = _orderCountOn(orders, _selectedDate);

              final completedOnDate = orders
                  .where((o) =>
                      _sameDay(o.createdAt, _selectedDate) &&
                      o.status == OrderStatus.completed)
                  .toList();
              final avgOrder = completedOnDate.isEmpty
                  ? 0.0
                  : completedOnDate.fold<double>(
                          0, (s, o) => s + o.totalAmount) /
                      completedOnDate.length;

              final dateLabel = DateFormat('MMM d, yyyy').format(_selectedDate);
              final revenueLabel =
                  _isToday ? "Today's Revenue" : 'Revenue';
              final ordersLabel =
                  _isToday ? "Today's Orders" : 'Orders';

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        if (Navigator.of(context).canPop())
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 36,
                              height: 36,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            'Sales Report',
                            style: GoogleFonts.spectral(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        // Tap-to-pick date chip
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.primaryBrand
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    size: 14,
                                    color: AppColors.primaryBrand),
                                const SizedBox(width: 6),
                                Text(
                                  dateLabel,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down_rounded,
                                    size: 18,
                                    color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Quick reset to today
                    if (!_isToday)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              final now = DateTime.now();
                              setState(() {
                                _selectedDate = DateTime(
                                    now.year, now.month, now.day);
                              });
                            },
                            icon: const Icon(Icons.refresh_rounded,
                                size: 16,
                                color: AppColors.primaryBrand),
                            label: Text(
                              'Back to today',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryBrand,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Summary Cards Row 1
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: revenueLabel,
                            value: 'RM${revenue.toStringAsFixed(0)}',
                            icon: Icons.trending_up_rounded,
                            iconColor: AppColors.success,
                            iconBgColor:
                                AppColors.success.withValues(alpha: 0.1),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _SummaryCard(
                            title: ordersLabel,
                            value: '$orderCount',
                            icon: Icons.receipt_long_rounded,
                            iconColor: AppColors.accentGreen,
                            iconBgColor:
                                AppColors.accentGreen.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Total Orders (all time)',
                            value: '${orders.length}',
                            icon: Icons.shopping_bag_outlined,
                            iconColor: AppColors.warning,
                            iconBgColor:
                                AppColors.warning.withValues(alpha: 0.1),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Avg. Order',
                            value: 'RM${avgOrder.toStringAsFixed(0)}',
                            icon: Icons.analytics_outlined,
                            iconColor: AppColors.primaryBrand,
                            iconBgColor:
                                AppColors.primaryBrand.withValues(alpha: 0.1),
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
                            color: AppColors.divider.withValues(alpha: 0.4),
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
                            _isToday
                                ? 'Last 7 days revenue'
                                : '7 days ending $dateLabel',
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text('📊',
                                            style: TextStyle(fontSize: 32)),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No sales data for this range',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : BarChart(
                                    BarChartData(
                                      alignment:
                                          BarChartAlignment.spaceAround,
                                      maxY: weeklySales.values
                                              .reduce((a, b) => a > b ? a : b) *
                                          1.3,
                                      barTouchData: BarTouchData(
                                        touchTooltipData:
                                            BarTouchTooltipData(
                                          getTooltipItem: (group, groupIndex,
                                              rod, rodIndex) {
                                            final day = weeklySales.keys
                                                .elementAt(group.x.toInt());
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
                                        topTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                                showTitles: false)),
                                        rightTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                                showTitles: false)),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 50,
                                            getTitlesWidget: (value, meta) {
                                              String label;
                                              if (value >= 1000) {
                                                label =
                                                    'RM${(value / 1000).toStringAsFixed(1)}k';
                                              } else {
                                                label =
                                                    'RM${value.toStringAsFixed(0)}';
                                              }
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.only(
                                                        right: 8),
                                                child: Text(
                                                  label,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    color: AppColors
                                                        .textSecondary,
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
                                              if (idx >= 0 &&
                                                  idx < weeklySales.length) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8),
                                                  child: Text(
                                                    weeklySales.keys
                                                        .elementAt(idx),
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                );
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                        ),
                                      ),
                                      borderData:
                                          FlBorderData(show: false),
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        horizontalInterval: (weeklySales
                                                    .values
                                                    .reduce((a, b) =>
                                                        a > b ? a : b) /
                                                4)
                                            .clamp(1, double.infinity),
                                        getDrawingHorizontalLine: (value) =>
                                            FlLine(
                                          color: AppColors.divider,
                                          strokeWidth: 1,
                                        ),
                                      ),
                                      barGroups: weeklySales.entries
                                          .toList()
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        return BarChartGroupData(
                                          x: entry.key,
                                          barRods: [
                                            BarChartRodData(
                                              toY: entry.value.value,
                                              color:
                                                  AppColors.primaryBrand,
                                              width: 20,
                                              borderRadius:
                                                  const BorderRadius
                                                      .vertical(
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

                    // Top Selling Items (for selected date)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.divider.withValues(alpha: 0.4),
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
                          const SizedBox(height: 4),
                          Text(
                            _isToday ? 'Today' : 'On $dateLabel',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (topItems.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'No sales data for this date',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...topItems.entries
                                .toList()
                                .asMap()
                                .entries
                                .map((entry) {
                              final rank = entry.key + 1;
                              final name = entry.value.key;
                              final count = entry.value.value;
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: entry.key < topItems.length - 1
                                      ? 12
                                      : 0,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: rank <= 3
                                            ? AppColors.primaryBrand
                                                .withValues(alpha: 0.1)
                                            : AppColors.background,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$rank',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: rank <= 3
                                                ? AppColors.primaryBrand
                                                : AppColors.textSecondary,
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
                  ],
                ),
              );
            },
          ),
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
