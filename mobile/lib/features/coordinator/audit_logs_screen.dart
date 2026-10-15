import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../widgets/neumorphic/neumorphic.dart';
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
    final neuTheme = context.neuTheme;
    final logsAsync = ref.watch(auditLogsFutureProvider);

    return Scaffold(
      backgroundColor: neuTheme.baseColor,
      appBar: NeuAppBar(
        title: 'Institutional Audit Logs',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: NeuIconButton(
              icon: TablerIcons.rotate_clockwise,
              tooltip: 'Refresh Logs',
              onPressed: () => ref.refresh(auditLogsFutureProvider),
            ),
          ),
        ],
      ),
      drawer: const AtlasDrawer(),
      body: Column(
        children: [
          // Minimalist iOS Stadium Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: IosNeuSearchBar(
              controller: _searchController,
              hintText: 'Search by user, action, or entity...',
              onChanged: (val) {
                setState(() => _filterQuery = val.trim().toLowerCase());
              },
              onClear: () {
                setState(() => _filterQuery = '');
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
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final log = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: IosNeuCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  color: IosNeuColors.inactiveBadge,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  _getActionIcon(log.action),
                                  size: 19,
                                  color: neuTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          log.action.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                            color: neuTheme.textPrimary,
                                          ),
                                        ),
                                        if (log.createdAt != null)
                                          Text(
                                            log.createdAt!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: neuTheme.textSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'By: ${log.userName} • ${log.resourceType}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: neuTheme.textPrimary,
                                      ),
                                    ),
                                    if (log.details != null && log.details!.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        log.details!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: neuTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
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
