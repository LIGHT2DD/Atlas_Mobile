import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/atlas_card.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/status_badge.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import 'supervisor_repository.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class RequestsInboxScreen extends ConsumerWidget {
  const RequestsInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(supervisorRequestsFutureProvider);
    final neuTheme = context.neuTheme;

    return Scaffold(
      backgroundColor: neuTheme.baseColor,
      appBar: NeuAppBar(
        title: 'Supervision Requests',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: NeuIconButton(
              icon: TablerIcons.rotate_clockwise,
              tooltip: 'Refresh Requests',
              onPressed: () => ref.refresh(supervisorRequestsFutureProvider),
            ),
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
                  icon: TablerIcons.inbox,
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
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: neuTheme.textPrimary,
                                  ),
                                ),
                              ),
                              StatusBadge(status: req.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            req.projectTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: neuTheme.accentColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(TablerIcons.user, size: 14, color: neuTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'Requested by: ${req.requestedByName}',
                                style: TextStyle(fontSize: 12, color: neuTheme.textSecondary),
                              ),
                            ],
                          ),
                        const Divider(height: 20),
                        IosNeuCard(
                          isSunken: true,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Student Pitch Message:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: neuTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                req.message,
                                style: TextStyle(fontSize: 13, color: neuTheme.textPrimary, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        if (req.status.toLowerCase() == 'pending') ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: IosNeuButton(
                                  text: 'Decline',
                                  isPrimary: false,
                                  onPressed: () => _handleResponse(context, ref, req, 'reject'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: IosNeuButton(
                                  text: 'Accept Guidance',
                                  isPrimary: true,
                                  onPressed: () => _handleResponse(context, ref, req, 'accept'),
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
    final neuTheme = context.neuTheme;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: IosNeuCard(
          borderRadius: BorderRadius.circular(28),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAccept ? 'Accept Supervision' : 'Decline Supervision',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: neuTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isAccept
                    ? 'Confirm acceptance to become the official thesis supervisor for "${req.teamName}".'
                    : 'Decline this supervision request. You may optionally provide constructive rationale.',
                style: TextStyle(fontSize: 13, color: neuTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              NeuTextField(
                controller: notesController,
                maxLines: 3,
                labelText: 'Notes / Feedback (Optional)',
                hintText: 'Add an advisory note to the team...',
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IosNeuButton(
                    text: 'Cancel',
                    isPrimary: false,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                  const SizedBox(width: 12),
                  IosNeuButton(
                    text: isAccept ? 'Confirm Accept' : 'Confirm Decline',
                    isPrimary: true,
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
            ],
          ),
        ),
      ),
    );
  }
}
