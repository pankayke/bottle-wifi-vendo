import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../utils/constants.dart';
import 'common_widgets.dart';

/// Paginated list view with lazy loading and pull to refresh
class PaginatedListView<T> extends StatefulWidget {
  final Future<List<T>> Function(int page) onLoadMore;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;
  final VoidCallback? onEmptyAction;
  final String? emptyActionLabel;
  final int itemsPerPage;
  final Widget? separator;
  final EdgeInsetsGeometry? padding;

  const PaginatedListView({
    super.key,
    required this.onLoadMore,
    required this.itemBuilder,
    this.emptyTitle = 'No Items Found',
    this.emptyMessage = 'There are no items to display.',
    this.emptyIcon = Icons.inbox_outlined,
    this.onEmptyAction,
    this.emptyActionLabel,
    this.itemsPerPage = 20,
    this.separator,
    this.padding,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );
  final List<T> _items = [];
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await widget.onLoadMore(1);
      setState(() {
        _items.clear();
        _items.addAll(items);
        _currentPage = 1;
        _hasMoreData = items.length >= widget.itemsPerPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    try {
      final items = await widget.onLoadMore(1);
      setState(() {
        _items.clear();
        _items.addAll(items);
        _currentPage = 1;
        _hasMoreData = items.length >= widget.itemsPerPage;
        _errorMessage = null;
      });
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _onLoadMore() async {
    if (!_hasMoreData || _isLoading) {
      _refreshController.loadComplete();
      return;
    }

    try {
      final nextPage = _currentPage + 1;
      final items = await widget.onLoadMore(nextPage);

      setState(() {
        _items.addAll(items);
        _currentPage = nextPage;
        _hasMoreData = items.length >= widget.itemsPerPage;
      });

      _refreshController.loadComplete();
    } catch (e) {
      _refreshController.loadFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading && _items.isEmpty) {
      return const LoadingIndicator(message: 'Loading data...');
    }

    // Error state
    if (_errorMessage != null && _items.isEmpty) {
      return ErrorMessage(message: _errorMessage!, onRetry: _loadInitialData);
    }

    // Empty state
    if (_items.isEmpty) {
      return EmptyState(
        title: widget.emptyTitle,
        message: widget.emptyMessage,
        icon: widget.emptyIcon,
        onAction: widget.onEmptyAction,
        actionLabel: widget.emptyActionLabel,
      );
    }

    // List view with pull to refresh and lazy loading
    return SmartRefresher(
      controller: _refreshController,
      enablePullDown: true,
      enablePullUp: _hasMoreData,
      onRefresh: _onRefresh,
      onLoading: _onLoadMore,
      header: WaterDropMaterialHeader(
        backgroundColor: AppColors.primaryColor,
        color: Colors.white,
      ),
      footer: CustomFooter(
        builder: (context, mode) {
          Widget body;
          if (mode == LoadStatus.idle) {
            body = const Text('Pull up to load more');
          } else if (mode == LoadStatus.loading) {
            body = const SmallLoadingIndicator();
          } else if (mode == LoadStatus.failed) {
            body = const Text('Load Failed! Tap to retry');
          } else if (mode == LoadStatus.canLoading) {
            body = const Text('Release to load more');
          } else {
            body = const Text('No more data');
          }
          return Container(height: 55.0, child: Center(child: body));
        },
      ),
      child: ListView.separated(
        padding:
            widget.padding ?? const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: _items.length,
        separatorBuilder: (context, index) =>
            widget.separator ?? const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }
}

/// Simplified paginated grid view
class PaginatedGridView<T> extends StatefulWidget {
  final Future<List<T>> Function(int page) onLoadMore;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int crossAxisCount;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final String emptyTitle;
  final String emptyMessage;
  final int itemsPerPage;

  const PaginatedGridView({
    super.key,
    required this.onLoadMore,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.mainAxisSpacing = 12,
    this.crossAxisSpacing = 12,
    this.emptyTitle = 'No Items Found',
    this.emptyMessage = 'There are no items to display.',
    this.itemsPerPage = 20,
  });

  @override
  State<PaginatedGridView<T>> createState() => _PaginatedGridViewState<T>();
}

class _PaginatedGridViewState<T> extends State<PaginatedGridView<T>> {
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );
  final List<T> _items = [];
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await widget.onLoadMore(1);
      setState(() {
        _items.clear();
        _items.addAll(items);
        _currentPage = 1;
        _hasMoreData = items.length >= widget.itemsPerPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    try {
      final items = await widget.onLoadMore(1);
      setState(() {
        _items.clear();
        _items.addAll(items);
        _currentPage = 1;
        _hasMoreData = items.length >= widget.itemsPerPage;
        _errorMessage = null;
      });
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
  }

  Future<void> _onLoadMore() async {
    if (!_hasMoreData || _isLoading) {
      _refreshController.loadComplete();
      return;
    }

    try {
      final nextPage = _currentPage + 1;
      final items = await widget.onLoadMore(nextPage);

      setState(() {
        _items.addAll(items);
        _currentPage = nextPage;
        _hasMoreData = items.length >= widget.itemsPerPage;
      });

      _refreshController.loadComplete();
    } catch (e) {
      _refreshController.loadFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _items.isEmpty) {
      return const LoadingIndicator(message: 'Loading data...');
    }

    if (_errorMessage != null && _items.isEmpty) {
      return ErrorMessage(message: _errorMessage!, onRetry: _loadInitialData);
    }

    if (_items.isEmpty) {
      return EmptyState(title: widget.emptyTitle, message: widget.emptyMessage);
    }

    return SmartRefresher(
      controller: _refreshController,
      enablePullDown: true,
      enablePullUp: _hasMoreData,
      onRefresh: _onRefresh,
      onLoading: _onLoadMore,
      header: WaterDropMaterialHeader(
        backgroundColor: AppColors.primaryColor,
        color: Colors.white,
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          childAspectRatio: widget.childAspectRatio,
          mainAxisSpacing: widget.mainAxisSpacing,
          crossAxisSpacing: widget.crossAxisSpacing,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }
}
