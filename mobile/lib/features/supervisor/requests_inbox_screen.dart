import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/atlas_card.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/status_badge.dart';
import 'supervisor_repository.dart';

class RequestsInboxScreen extends ConsumerWidget {
  const RequestsInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(supervisorRequestsFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervision Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(supervisorRequestsFutureProvider),
          ),
        ],
      ),
      drawer: const AtlasDrawer(),
      body: requestsAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading supervision requests...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(supervisorRequestsFutureProvider),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'No Pending Requests',
                  subtitle: 'When student teams submit supervision proposals to you, they will appear in this inbox.',
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(supervisorRequestsFutureProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: AtlasCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                req.teamName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            StatusBadge(status: req.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          req.projectTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              'Requested by: ${req.requestedByName}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Student Pitch Message:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                req.message,
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        if (req.status.toLowerCase() == 'pending') ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(color: AppColors.error),
                                  ),
                                  onPressed: () => _handleResponse(context, ref, req, 'reject'),
                                  child: const Text('Decline'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                  ),
                                  onPressed: () => _handleResponse(context, ref, req, 'accept'),
                                  child: const Text('Accept Guidance'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _handleResponse(
    BuildContext context,
    WidgetRef ref,
    SupervisorRequestItem req,
    String action,
  ) {
    final notesController = TextEditingController();
    final isAccept = action == 'accept';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAccept ? 'Accept Supervision' : 'Decline Supervision'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAccept
                  ? 'Confirm acceptance to become the official thesis supervisor for "${req.teamName}".'
                  : 'Decline this supervision request. You may optionally provide constructive rationale.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes / Feedback (Optional)',
                hintText: 'Add an advisory note to the team...',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isAccept ? AppColors.success : AppColors.error,
            ),
            child: Text(isAccept ? 'Confirm Accept' : 'Confirm Decline'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final repo = ref.read(supervisorRepositoryProvider);
                final msg = await repo.respondToRequest(
                  requestId: req.id,
                  action: action,
                  notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: isAccept ? AppColors.success : AppColors.info,
                    ),
                  );
                  ref.invalidate(supervisorRequestsFutureProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
