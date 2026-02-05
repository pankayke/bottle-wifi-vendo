import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bottle_provider.dart';
import '../utils/constants.dart';
import '../widgets/bottle_log_card.dart';

/// Bottle history screen showing all bottle logs
class BottleHistoryScreen extends StatefulWidget {
  const BottleHistoryScreen({super.key});

  @override
  State<BottleHistoryScreen> createState() => _BottleHistoryScreenState();
}

class _BottleHistoryScreenState extends State<BottleHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final bottleProvider = context.read<BottleProvider>();
    await bottleProvider.fetchBottleHistory(refresh: true);
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final bottleProvider = context.read<BottleProvider>();
      if (!bottleProvider.isLoading && bottleProvider.hasMorePages) {
        bottleProvider.fetchBottleHistory();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Bottle History'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<BottleProvider>(
        builder: (context, bottleProvider, child) {
          if (bottleProvider.bottleLogs.isEmpty && bottleProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (bottleProvider.bottleLogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.recycling,
                    size: 80,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No bottle history yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Report your first bottle to get started!',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: Column(
              children: [
                // Statistics summary
                if (bottleProvider.statistics != null)
                  Container(
                    color: AppColors.cardBackground,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: 'Total',
                          value: bottleProvider.statistics!.totalBottles
                              .toString(),
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
                  ),

                // Bottle list
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    itemCount:
                        bottleProvider.bottleLogs.length +
                        (bottleProvider.hasMorePages ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == bottleProvider.bottleLogs.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final bottleLog = bottleProvider.bottleLogs[index];
                      return BottleLogCard(bottleLog: bottleLog);
                    },
                  ),
                ),
              ],
            ),
          );
        },
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
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
