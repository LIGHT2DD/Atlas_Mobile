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
    final neuTheme = context.neuTheme;
    final defensesAsync = ref.watch(defensesListProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final isCoordinator = user?.role.isCoordinator ?? false;

    return Scaffold(
      backgroundColor: neuTheme.baseColor,
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
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: neuTheme.textPrimary,
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
                        IosNeuCard(
                          isSunken: true,
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(TablerIcons.clock, size: 20, color: neuTheme.accentColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.date != null ? '${d.date}' : 'Date TBD',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: neuTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${d.startTime} - ${d.endTime}',
                                      style: TextStyle(fontSize: 12, color: neuTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Container(height: 24, width: 1, color: neuTheme.darkShadow),
                              const SizedBox(width: 12),
                              Icon(TablerIcons.door_enter, size: 20, color: neuTheme.accentColor),
                              const SizedBox(width: 6),
                              Text(
                                d.room,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: neuTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Examination Panel
                        Text(
                          'Examination Panel:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: neuTheme.textSecondary,
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(TablerIcons.star, size: 16, color: IosNeuColors.activePill),
                                const SizedBox(width: 8),
                                Text(
                                  'You are an assigned examiner on this panel',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: neuTheme.textPrimary,
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
