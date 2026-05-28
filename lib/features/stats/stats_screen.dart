import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_palette.dart';
import 'stats_provider.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int days = 7;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(statsByDaysProvider(days));

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 118),
          children: [
            const _StatsHeader(),
            const SizedBox(height: 16),
            _Segmented(
              selected: days,
              onChanged: (v) => setState(() => days = v),
            ),
            const SizedBox(height: 16),
            statsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Erreur: $e'),
              data: (stats) {
                final waterValues = stats.water;
                final sleepValues = stats.sleep;
                final labels = stats.labels.isNotEmpty ? stats.labels : _labelsFallback(waterValues.length);
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            color: AppPalette.water,
                            icon: LucideIcons.droplets,
                            value: stats.avgWater.toStringAsFixed(stats.avgWater >= 10 ? 0 : 1),
                            label: 'Moy. verres/jour',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            color: AppPalette.sleep,
                            icon: LucideIcons.moon,
                            value: '${stats.avgSleep.toStringAsFixed(stats.avgSleep >= 10 ? 0 : 1)}h',
                            label: 'Moy. sommeil/nuit',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _ChartCard(
                      title: 'Hydratation',
                      color: AppPalette.water,
                      values: waterValues,
                      labels: labels,
                      mode: _ChartMode.area,
                    ),
                    const SizedBox(height: 14),
                    _ChartCard(
                      title: 'Sommeil',
                      color: AppPalette.sleep,
                      values: sleepValues,
                      labels: labels,
                      mode: _ChartMode.bar,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<String> _labelsFallback(int count) {
    if (count <= 0) return const ['Aucun log'];
    const base = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    if (count <= 7) return base.take(count).toList();
    return List.generate(count, (i) => i % 5 == 4 ? 'J${i + 1}' : '');
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppPalette.headerGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFC2DCF0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(LucideIcons.chartColumn, color: AppPalette.water),
          ),
          const SizedBox(width: 12),
          const Text(
            'Statistiques',
            style: TextStyle(fontSize: 42, fontWeight: FontWeight.w700, color: AppPalette.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _Segmented({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget button(int value, String label) {
      final active = selected == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: active ? AppPalette.water : Colors.transparent,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppPalette.textMuted,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(30),
        boxShadow: SoftShadow.card(Colors.grey),
      ),
      child: Row(
        children: [button(7, '7 jours'), button(30, '30 jours')],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String value;
  final String label;

  const _MetricCard({
    required this.color,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: SoftShadow.card(color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w700, color: AppPalette.textPrimary),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: AppPalette.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<int> values;
  final List<String> labels;
  final _ChartMode mode;

  const _ChartCard({
    required this.title,
    required this.color,
    required this.values,
    required this.labels,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b).toDouble();
    final maxY = maxValue <= 0 ? 1.0 : (maxValue * 1.25).clamp(1.0, 24.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: SoftShadow.card(color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                title == 'Hydratation'
                    ? LucideIcons.droplets
                    : LucideIcons.moon,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppPalette.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: mode == _ChartMode.area
                ? LineChart(_areaData(values, labels, color, maxY))
                : BarChart(_barData(values, labels, color, maxY)),
          ),
        ],
      ),
    );
  }

  LineChartData _areaData(
    List<int> values,
    List<String> labels,
    Color color,
    double maxY,
  ) {
    final spots = List.generate(
      values.length,
      (i) => FlSpot(i.toDouble(), values[i].toDouble()),
    );

    return LineChartData(
      minX: -0.35,
      maxX: (values.length - 1).toDouble().clamp(0, double.infinity) + 0.35,
      minY: 0,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (_) => FlLine(
          color: const Color(0xFFDDE2EA),
          strokeWidth: 1,
          dashArray: [3, 3],
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: _titles(labels),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.white,
          tooltipBorder: const BorderSide(color: Color(0xFFDDE2EA)),
          tooltipRoundedRadius: 12,
          getTooltipItems: (items) => items
              .map((item) => LineTooltipItem(
                    '${item.y.toStringAsFixed(item.y % 1 == 0 ? 0 : 1)}',
                    TextStyle(color: color, fontWeight: FontWeight.w700),
                  ))
              .toList(),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          color: color,
          barWidth: 3,
          isCurved: true,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withOpacity(0.22),
                color.withOpacity(0.03),
              ],
            ),
          ),
        ),
      ],
    );
  }

  BarChartData _barData(
    List<int> values,
    List<String> labels,
    Color color,
    double maxY,
  ) {
    final groups = List.generate(values.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: values[i].toDouble(),
            color: color,
            width: values.length > 14 ? 8 : 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    });

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      minY: 0,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (_) => FlLine(
          color: const Color(0xFFDDE2EA),
          strokeWidth: 1,
          dashArray: [3, 3],
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: _titles(labels),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: Colors.white,
          tooltipBorder: const BorderSide(color: Color(0xFFDDE2EA)),
          getTooltipItem: (_, __, rod, ___) => BarTooltipItem(
            '${rod.toY.toStringAsFixed(rod.toY % 1 == 0 ? 0 : 1)}',
            TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      barGroups: groups,
    );
  }

  FlTitlesData _titles(List<String> labels) {
    final isDense = labels.length > 10;
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: 1,
          getTitlesWidget: (value, _) {
            if (value < 0 || value > labels.length - 1) {
              return const SizedBox.shrink();
            }
            if ((value - value.roundToDouble()).abs() > 0.001) {
              return const SizedBox.shrink();
            }
            final i = value.round();
            if (i < 0 || i >= labels.length) return const SizedBox.shrink();
            if (isDense && i % 5 != 0 && i != labels.length - 1) {
              return const SizedBox.shrink();
            }
            final first = i == 0;
            final last = i == labels.length - 1;
            return Transform.translate(
              offset: Offset(first ? 10 : (last ? -10 : 0), 0),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  labels[i],
                  style: const TextStyle(fontSize: 12, color: AppPalette.textMuted),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _ChartMode { area, bar }
