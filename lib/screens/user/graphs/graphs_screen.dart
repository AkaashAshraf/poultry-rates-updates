import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/city_model.dart';
import '../../../models/rate_model.dart';
import '../../../providers/cities_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/empty_state.dart';

class GraphsScreen extends StatefulWidget {
  const GraphsScreen({super.key});

  @override
  State<GraphsScreen> createState() => _GraphsScreenState();
}

class _GraphsScreenState extends State<GraphsScreen> {
  RateCategory _category = RateCategory.chicken;
  String? _cityId;

  @override
  Widget build(BuildContext context) {
    final cities = context.watch<CitiesProvider>().activeCities;
    final firestore = context.read<FirestoreService>();
    final languageCode = context.locale.languageCode;

    if (_cityId == null && cities.isNotEmpty) {
      _cityId = cities.first.id;
    }

    return Scaffold(
      appBar: AppBar(title: Text('graphs.title'.tr())),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RateCategory.values
                  .map((c) => ChoiceChip(
                        avatar: Icon(c.icon, size: 16, color: _category == c ? Colors.white : c.color),
                        label: Text(c.labelKey.tr()),
                        selected: _category == c,
                        selectedColor: c.color,
                        labelStyle: TextStyle(color: _category == c ? Colors.white : null),
                        onSelected: (_) => setState(() => _category = c),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (cities.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                initialValue: _cityId,
                decoration: InputDecoration(
                  labelText: 'common.city'.tr(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: cities
                    .map((CityModel c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.localizedName(languageCode)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _cityId = value),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _cityId == null
                ? const EmptyState(icon: Icons.show_chart, titleKey: 'graphs.noCity')
                : StreamBuilder<List<RateModel>>(
                    stream: firestore.watchRateHistory(category: _category, cityId: _cityId!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final history = snapshot.data!;
                      if (history.length < 2) {
                        return const EmptyState(
                          icon: Icons.show_chart,
                          titleKey: 'graphs.notEnoughData',
                          subtitleKey: 'graphs.notEnoughDataSubtitle',
                        );
                      }
                      return _TrendChart(history: history, category: _category, languageCode: languageCode);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<RateModel> history;
  final RateCategory category;
  final String languageCode;

  const _TrendChart({required this.history, required this.category, required this.languageCode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spots = <FlSpot>[
      for (int i = 0; i < history.length; i++) FlSpot(i.toDouble(), history[i].price),
    ];
    final prices = history.map((r) => r.price).toList();
    final minY = prices.reduce((a, b) => a < b ? a : b);
    final maxY = prices.reduce((a, b) => a > b ? a : b);
    final padding = ((maxY - minY) * 0.2).clamp(1, double.infinity);
    final latest = history.last;
    final first = history.first;
    final change = latest.price - first.price;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. ${AppFormatters.price(latest.price)}',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      change >= 0 ? Icons.trending_up : Icons.trending_down,
                      size: 18,
                      color: change >= 0 ? Colors.red : Colors.green,
                    ),
                    Text(
                      '${change >= 0 ? '+' : ''}${AppFormatters.price(change)}',
                      style: TextStyle(
                        color: change >= 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            latest.unit,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: (minY - padding).toDouble(),
                maxY: (maxY + padding).toDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: ((maxY - minY) / 3).clamp(1, double.infinity).toDouble(),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: (history.length / 4).clamp(1, double.infinity).toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= history.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            AppFormatters.date(history[index].date, languageCode).split(',').first,
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: category.color,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          category.color.withValues(alpha: 0.22),
                          category.color.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => theme.colorScheme.primary,
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              'Rs. ${AppFormatters.price(s.y)}',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
