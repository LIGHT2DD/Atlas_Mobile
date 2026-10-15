import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'coordinator_repository.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

final auditLogsFutureProvider = FutureProvider.autoDispose<List<AuditLogItem>>((ref) async {
  final repo = ref.watch(coordinatorRepositoryProvider);
  return repo.getAuditLogs();
});

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  final _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(auditLogsFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Institutional Audit Logs'),
        actions: [
          IconButton(
            icon: const Icon(TablerIcons.rotate_clockwise),
            onPressed: () => ref.refresh(auditLogsFutureProvider),
          ),
        ],
      ),
      drawer: const AtlasDrawer(),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by user, action, or entity...',
                prefixIcon: const Icon(TablerIcons.search),
                suffixIcon: _filterQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(TablerIcons.x),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _filterQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                setState(() => _filterQuery = val.trim().toLowerCase());
              },
            ),
          ),

          // Log List
          Expanded(
            child: logsAsync.when(
              loading: () => const LoadingIndicator(message: 'Loading security audit trail...'),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.refresh(auditLogsFutureProvider),
              ),
              data: (logs) {
                final filtered = logs.where((l) {
                  if (_filterQuery.isEmpty) return true;
                  return l.userName.toLowerCase().contains(_filterQuery) ||
                      l.action.toLowerCase().contains(_filterQuery) ||
                      l.resourceType.toLowerCase().contains(_filterQuery) ||
                      (l.details?.toLowerCase().contains(_filterQuery) ?? false);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: EmptyState(
                        icon: TablerIcons.shield_check,
                        title: 'No Matching Logs',
                        subtitle: 'No system actions matched your search criteria.',
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(auditLogsFutureProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final log = filtered[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.infoBg,
                          child: Icon(
                            _getActionIcon(log.action),
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              log.action.toUpperCase(),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            if (log.createdAt != null)
                              Text(
                                log.createdAt!,
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              'By: ${log.userName} • Resource: ${log.resourceType}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            if (log.details != null && log.details!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                log.details!,
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(String action) {
    final a = action.toLowerCase();
    if (a.contains('login') || a.contains('auth')) return TablerIcons.login;
    if (a.contains('create')) return TablerIcons.circle_plus;
    if (a.contains('delete') || a.contains('leave')) return TablerIcons.trash;
    if (a.contains('submit')) return TablerIcons.upload;
    if (a.contains('grade') || a.contains('publish')) return TablerIcons.award;
    return TablerIcons.history;
  }
}
