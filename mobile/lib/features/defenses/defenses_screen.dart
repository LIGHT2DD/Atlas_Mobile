import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import '../../shared/models/defense_model.dart';
import '../../shared/widgets/atlas_card.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/status_badge.dart';
import '../auth/auth_controller.dart';
import 'defense_repository.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

final defensesListProvider = FutureProvider.autoDispose<List<DefenseModel>>((ref) async {
  final repo = ref.watch(defenseRepositoryProvider);
  return repo.getDefenses();
});

class DefensesScreen extends ConsumerWidget {
  const DefensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defensesAsync = ref.watch(defensesListProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final isCoordinator = user?.role.isCoordinator ?? false;

    return Scaffold(
      appBar: NeuAppBar(
        title: 'Oral Defense Hearings',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: NeuIconButton(
              icon: TablerIcons.rotate_clockwise,
              tooltip: 'Refresh Defenses',
              onPressed: () => ref.refresh(defensesListProvider),
            ),
          ),
        ],
      ),
      drawer: const AtlasDrawer(),
      body: defensesAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading defense timetable...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(defensesListProvider),
        ),
        data: (defenses) {
          if (defenses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: EmptyState(
                  icon: TablerIcons.armchair,
                  title: 'No Defenses Scheduled',
                  subtitle:
                      'Institutional defense schedules, panel assignments, and venue details will appear here once booked.',
                  actionLabel: isCoordinator ? 'Schedule Defense Hearing' : null,
                  onAction: isCoordinator
                      ? () => context.push('/defenses/schedule').then((_) {
                            ref.invalidate(defensesListProvider);
                          })
                      : null,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(defensesListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: defenses.length,
              itemBuilder: (context, index) {
                final d = defenses[index];
                final isUserOnPanel = user != null &&
                    d.panelMembers.any((p) => p.userId == user.id || p.name == user.fullName);

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
                                d.teamName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            StatusBadge(status: d.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d.projectTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Time & Venue Container
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(TablerIcons.clock, size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.date != null ? '${d.date}' : 'Date TBD',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${d.startTime} - ${d.endTime}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Container(height: 24, width: 1, color: AppColors.border),
                              const SizedBox(width: 12),
                              const Icon(TablerIcons.door_enter, size: 20, color: AppColors.accent),
                              const SizedBox(width: 6),
                              Text(
                                d.room,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Examination Panel
                        const Text(
                          'Examination Panel:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: d.panelMembers.map((p) {
                            return IosNeuSegmentPill(
                              label: p.name,
                              icon: TablerIcons.user,
                              isSelected: false,
                              onTap: () {},
                            );
                          }).toList(),
                        ),

                        if (isUserOnPanel) ...[
                          const SizedBox(height: 12),
                          IosNeuCard(
                            isSunken: true,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(TablerIcons.star, size: 16, color: IosNeuColors.activePill),
                                SizedBox(width: 8),
                                Text(
                                  'You are an assigned examiner on this panel',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: IosNeuColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
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
      floatingActionButton: isCoordinator
          ? IosNeuFAB(
              tooltip: 'Schedule Defense Hearing',
              onPressed: () {
                context.push('/defenses/schedule').then((_) {
                  ref.invalidate(defensesListProvider);
                });
              },
            )
          : null,
    );
  }
}
