import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bottle_log.dart';
import '../providers/bottle_provider.dart';
import '../utils/constants.dart';
import '../widgets/bottle_log_card.dart';
import '../widgets/common_widgets.dart';
import '../widgets/paginated_list_view.dart';

/// Improved Bottle history screen with lazy loading
class ImprovedBottleHistoryScreen extends StatelessWidget {
  const ImprovedBottleHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Bottle History'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Statistics summary
          Consumer<BottleProvider>(
            builder: (context, bottleProvider, child) {
              if (bottleProvider.statistics == null) {
                return const SizedBox.shrink();
              }

              return CustomCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Total',
                      value: bottleProvider.statistics!.totalBottles.toString(),
                      color: AppColors.primaryColor,
                    ),
                    _StatItem(
                      label: 'Verified',
                      value: bottleProvider.statistics!.verifiedBottles
                          .toString(),
                      color: AppColors.successColor,
                    ),
                    _StatItem(
                      label: 'Pending',
                      value: bottleProvider.statistics!.pendingBottles
                          .toString(),
                      color: AppColors.warningColor,
                    ),
                    _StatItem(
                      label: 'Credits',
                      value: bottleProvider.statistics!.totalCreditsEarned
                          .toString(),
                      color: AppColors.accentColor,
                    ),
                  ],
                ),
              );
            },
          ),

          // Paginated list
          Expanded(
            child: Consumer<BottleProvider>(
              builder: (context, bottleProvider, child) {
                return PaginatedListView<BottleLog>(
                  onLoadMore: (page) async {
                    final response = await bottleProvider.fetchBottleHistory(
                      page: page,
                      refresh: page == 1,
                    );
                    return response;
                  },
                  itemBuilder: (context, bottleLog, index) {
                    return BottleLogCard(bottleLog: bottleLog);
                  },
                  emptyTitle: 'No Bottle History',
                  emptyMessage: 'Report your first bottle to get started!',
                  emptyIcon: Icons.recycling,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
