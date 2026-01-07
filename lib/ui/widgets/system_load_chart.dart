/// System Load Chart Widget
///
/// Curved line chart showing CPU and RAM usage over time using fl_chart.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/system_theme.dart';
import 'glass_container.dart';

/// Mock data generator for system metrics
class SystemMetrics {
  final double cpu;
  final double ram;
  final DateTime timestamp;

  SystemMetrics({
    required this.cpu,
    required this.ram,
    required this.timestamp,
  });

  /// Generate realistic-looking mock data
  static List<SystemMetrics> generateMockData({int count = 20}) {
    final random = Random(42);
    final now = DateTime.now();
    final List<SystemMetrics> data = [];

    double baseCpu = 25 + random.nextDouble() * 20;
    double baseRam = 45 + random.nextDouble() * 15;

    for (int i = 0; i < count; i++) {
      // Add some realistic variation
      baseCpu += (random.nextDouble() - 0.5) * 15;
      baseRam += (random.nextDouble() - 0.5) * 8;

      // Add occasional spikes
      if (random.nextDouble() > 0.85) {
        baseCpu += 20 + random.nextDouble() * 20;
      }

      // Clamp values
      baseCpu = baseCpu.clamp(5, 95);
      baseRam = baseRam.clamp(30, 85);

      data.add(SystemMetrics(
        cpu: baseCpu,
        ram: baseRam,
        timestamp: now.subtract(Duration(seconds: (count - i) * 5)),
      ));
    }

    return data;
  }
}

class SystemLoadChart extends StatefulWidget {
  final ThemeProvider? themeProvider;

  const SystemLoadChart({super.key, this.themeProvider});

  @override
  State<SystemLoadChart> createState() => _SystemLoadChartState();
}

class _SystemLoadChartState extends State<SystemLoadChart> {
  late List<SystemMetrics> _metrics;

  @override
  void initState() {
    super.initState();
    _metrics = SystemMetrics.generateMockData();
  }

  @override
  Widget build(BuildContext context) {
    final tp = widget.themeProvider;
    final currentCpu = _metrics.last.cpu;
    final currentRam = _metrics.last.ram;

    return GlassContainer(
      backgroundColor: tp?.colors.glassBackground,
      borderColor: tp?.colors.glassBorder,
      padding: SystemSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.activity,
                    color: tp?.colors.accent ?? SystemColors.neonGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SYSTEM LOAD',
                    style: SystemTextStyles.monoSmall.copyWith(
                      color: tp?.colors.textMuted ?? SystemColors.textMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: SystemColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'DEMO',
                  style: SystemTextStyles.monoSmall.copyWith(
                    color: SystemColors.warning,
                    letterSpacing: 1,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Current values
          Row(
            children: [
              _MetricBadge(
                label: 'CPU',
                value: '${currentCpu.toStringAsFixed(1)}%',
                color: SystemColors.chartCpu,
              ),
              const SizedBox(width: 12),
              _MetricBadge(
                label: 'RAM',
                value: '${currentRam.toStringAsFixed(1)}%',
                color: SystemColors.chartRam,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: tp?.colors.chartGrid ?? SystemColors.chartGrid,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 50,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: SystemTextStyles.monoSmall.copyWith(
                            color: tp?.colors.textMuted ?? SystemColors.textMuted,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (_metrics.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  // CPU line
                  _buildLine(
                    spots: _metrics.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.cpu);
                    }).toList(),
                    color: SystemColors.chartCpu,
                  ),
                  // RAM line
                  _buildLine(
                    spots: _metrics.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.ram);
                    }).toList(),
                    color: SystemColors.chartRam,
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final label = spot.barIndex == 0 ? 'CPU' : 'RAM';
                        return LineTooltipItem(
                          '$label: ${spot.y.toStringAsFixed(1)}%',
                          SystemTextStyles.monoSmall.copyWith(
                            color: spot.bar.color,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLine({
    required List<FlSpot> spots,
    required Color color,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.0),
          ],
        ),
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: SystemRadius.borderSm,
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: SystemTextStyles.monoSmall.copyWith(
              color: SystemColors.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: SystemTextStyles.monoMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
