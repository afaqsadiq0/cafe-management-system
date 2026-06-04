import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/pdf_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedRange = 'This Week';
  final List<String> _ranges = ['Today', 'This Week', 'This Month', 'This Year'];

  // Mock data generator based on range
  Map<String, dynamic> _getDataForRange(String range) {
    switch (range) {
      case 'Today':
        return {
          'revenue': 'PKR 12.5K',
          'orders': '24',
          'avg': 'PKR 520',
          'chartData': [8.0, 12.0, 10.0, 15.0, 9.0, 11.0, 14.0],
          'topItems': [
            {'rank': 1, 'name': 'Caramel Macchiato', 'revenue': 'PKR 4,200'},
            {'rank': 2, 'name': 'Garlic Naan', 'revenue': 'PKR 1,500'},
            {'rank': 3, 'name': 'Nachos', 'revenue': 'PKR 1,200'},
          ]
        };
      case 'This Month':
        return {
          'revenue': 'PKR 340K',
          'orders': '580',
          'avg': 'PKR 585',
          'chartData': [12.0, 15.0, 18.0, 14.0, 19.0, 16.0, 20.0],
          'topItems': [
            {'rank': 1, 'name': 'Caramel Macchiato', 'revenue': 'PKR 120,000'},
            {'rank': 2, 'name': 'Hazelnut Latte', 'revenue': 'PKR 45,000'},
            {'rank': 3, 'name': 'Cold Brew', 'revenue': 'PKR 38,000'},
          ]
        };
      case 'This Year':
        return {
          'revenue': 'PKR 4.2M',
          'orders': '7,200',
          'avg': 'PKR 610',
          'chartData': [15.0, 18.0, 16.0, 19.0, 17.0, 20.0, 18.0],
          'topItems': [
            {'rank': 1, 'name': 'Caramel Macchiato', 'revenue': 'PKR 1.2M'},
            {'rank': 2, 'name': 'Hazelnut Latte', 'revenue': 'PKR 500K'},
            {'rank': 3, 'name': 'BBQ Steak', 'revenue': 'PKR 450K'},
          ]
        };
      default: // This Week
        return {
          'revenue': 'PKR 85K',
          'orders': '142',
          'avg': 'PKR 600',
          'chartData': [5.0, 10.0, 18.0, 15.0, 9.0, 12.0, 16.0],
          'topItems': [
            {'rank': 1, 'name': 'Caramel Macchiato', 'revenue': 'PKR 42,000'},
            {'rank': 2, 'name': 'Hazelnut Latte', 'revenue': 'PKR 15,000'},
            {'rank': 3, 'name': 'Iced Coffee', 'revenue': 'PKR 12,000'},
          ]
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _getDataForRange(_selectedRange);

    return Scaffold(
      appBar: AppBar(
        title: Text('Business Intelligence', style: GoogleFonts.ebGaramond()),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.accentColor),
            onPressed: () {
              PdfService.generateAndShareAnalyticsReport(
                revenue: data['revenue'],
                orders: data['orders'],
                avgOrder: data['avg'],
                topItems: data['topItems'],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateSelector(),
            const SizedBox(height: 32),
            
            // Premium Stats Bento Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildBentoStat('Revenue', data['revenue'], Icons.payments_rounded, Colors.green),
                _buildBentoStat('Orders', data['orders'], Icons.shopping_bag_rounded, Colors.blue),
                _buildBentoStat('Avg Ticket', data['avg'], Icons.analytics_rounded, Colors.orange),
                _buildBentoStat('Growth', '+15.4%', Icons.trending_up_rounded, Colors.teal),
              ],
            ),
            
            const SizedBox(height: 40),
            Text('Revenue Performance', style: GoogleFonts.ebGaramond(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildRevenueChart(data['chartData']),
            
            const SizedBox(height: 40),
            Text('Category Distribution', style: GoogleFonts.ebGaramond(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildCategoryPieChart(),
            
            const SizedBox(height: 40),
            Text('Premium Best Sellers', style: GoogleFonts.ebGaramond(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildBestSellersTable(data['topItems']),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: GoogleFonts.ebGaramond(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              ),
              Text(label, style: GoogleFonts.hankenGrotesk(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant.withOpacity(0.6))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _ranges.map((range) {
          final isSelected = range == _selectedRange;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(range),
              selected: isSelected,
              selectedColor: AppTheme.secondaryColor,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.primaryColor),
              onSelected: (selected) {
                if (selected) setState(() => _selectedRange = range);
              },
            ),
          );
        }).toList(),
      ),
    );
  }


  Widget _buildRevenueChart(List<double> values) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 25,
          barGroups: List.generate(values.length, (i) => _makeGroupData(i, values[i])),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const labels = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7'];
                  return Text(labels[value.toInt() % labels.length], style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppTheme.secondaryColor,
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildCategoryPieChart() {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(color: Colors.brown, value: 40, title: 'Coffee', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 10)),
            PieChartSectionData(color: Colors.orange, value: 25, title: 'Food', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 10)),
            PieChartSectionData(color: Colors.amber, value: 20, title: 'Snacks', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 10)),
            PieChartSectionData(color: Colors.blue, value: 15, title: 'Drinks', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildBestSellersTable(List<dynamic> items) {
    return AnimationLimiter(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 600),
              child: SlideAnimation(
                verticalOffset: 50.0,
                curve: Curves.easeOutBack,
                child: FadeInAnimation(
                  child: ScaleAnimation(
                    scale: 0.8,
                    child: InkWell(
                      onTap: () {
                        // Show detail dialog with animation
                        showDialog(
                          context: context,
                          builder: (context) => ScaleTransition(
                            scale: CurvedAnimation(
                              parent: ModalRoute.of(context)!.animation!,
                              curve: Curves.easeOutBack,
                            ),
                            child: AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppTheme.accentColor,
                                    child: Text('${item['rank']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item['name'],
                                      style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Revenue: ${item['revenue']}', style: GoogleFonts.hankenGrotesk(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text('Category: Premium Item', style: GoogleFonts.hankenGrotesk(color: Colors.grey[600])),
                                  const SizedBox(height: 8),
                                  Text('Status: Best Seller 🏆', style: GoogleFonts.hankenGrotesk(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('CLOSE', style: GoogleFonts.hankenGrotesk(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: Hero(
                          tag: 'rank_${item['rank']}',
                          child: CircleAvatar(
                            backgroundColor: AppTheme.accentColor,
                            child: Text('${item['rank']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        title: Text(
                          item['name'],
                          style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Text('Recent sales', style: GoogleFonts.hankenGrotesk(color: Colors.grey[600], fontSize: 12)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              item['revenue'],
                              style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
                            ),
                            const Icon(Icons.trending_up, color: Colors.green, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

