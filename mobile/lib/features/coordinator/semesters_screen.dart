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
import 'coordinator_repository.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

final semestersListProvider = FutureProvider.autoDispose<List<SemesterModel>>((ref) async {
  final repo = ref.watch(coordinatorRepositoryProvider);
  return repo.getSemesters();
});

class SemestersScreen extends ConsumerWidget {
  const SemestersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final neuTheme = context.neuTheme;
    final semestersAsync = ref.watch(semestersListProvider);

    return Scaffold(
      backgroundColor: neuTheme.baseColor,
      appBar: NeuAppBar(
        title: 'Academic Semesters',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: NeuIconButton(
              icon: TablerIcons.rotate_clockwise,
              tooltip: 'Refresh Semesters',
              onPressed: () => ref.refresh(semestersListProvider),
            ),
          ),
        ],
      ),
      drawer: const AtlasDrawer(),
      body: semestersAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading academic periods...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(semestersListProvider),
        ),
        data: (semesters) {
          if (semesters.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: EmptyState(
                  icon: TablerIcons.calendar_event,
                  title: 'No Semesters Configured',
                  subtitle: 'Create academic terms to anchor project cycles, deadlines, and cohorts.',
                  actionLabel: 'New Semester',
                  onAction: () => _createSemesterDialog(context, ref),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(semestersListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: semesters.length,
              itemBuilder: (context, index) {
                final s = semesters[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: AtlasCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                s.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: neuTheme.textPrimary,
                                ),
                              ),
                            ),
                            StatusBadge(
                              status: s.isActive ? 'approved' : 'pending',
                              customLabel: s.isActive ? 'Active Term' : 'Inactive',
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Code: ${s.code}',
                          style: const TextStyle(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600),
                        ),
                        if (s.startDate != null || s.endDate != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Period: ${s.startDate ?? "TBD"} to ${s.endDate ?? "TBD"}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                        if (!s.isActive) ...[
                          const Divider(height: 20),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IosNeuButton(
                              icon: TablerIcons.circle_check,
                              text: 'Set as Active Semester',
                              isPrimary: true,
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              onPressed: () async {
                                try {
                                  final repo = ref.read(coordinatorRepositoryProvider);
                                  final msg = await repo.activateSemester(s.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(msg), backgroundColor: AppColors.success),
                                    );
                                    ref.invalidate(semestersListProvider);
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
      floatingActionButton: IosNeuFAB(
        tooltip: 'Create Academic Term',
        onPressed: () => _createSemesterDialog(context, ref),
      ),
    );
  }

  void _createSemesterDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final startController = TextEditingController();
    final endController = TextEditingController();

    final neuTheme = context.neuTheme;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: IosNeuCard(
          isLarge: true,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Academic Term',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: neuTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 18),
                NeuTextField(
                  controller: nameController,
                  labelText: 'Semester Name *',
                  hintText: 'Fall 2026',
                ),
                const SizedBox(height: 12),
                NeuTextField(
                  controller: codeController,
                  labelText: 'Code *',
                  hintText: 'F2026',
                ),
                const SizedBox(height: 12),
                NeuTextField(
                  controller: startController,
                  labelText: 'Start Date (YYYY-MM-DD)',
                  hintText: '2026-09-01',
                ),
                const SizedBox(height: 12),
                NeuTextField(
                  controller: endController,
                  labelText: 'End Date (YYYY-MM-DD)',
                  hintText: '2026-12-20',
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IosNeuButton(
                      text: 'Cancel',
                      isPrimary: false,
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    const SizedBox(width: 10),
                    IosNeuButton(
                      text: 'Create Term',
                      isPrimary: true,
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty || codeController.text.trim().isEmpty) return;
                        Navigator.of(ctx).pop();
                        try {
                          final repo = ref.read(coordinatorRepositoryProvider);
                          await repo.createSemester(
                            name: nameController.text.trim(),
                            code: codeController.text.trim(),
                            startDate: startController.text.trim().isEmpty ? null : startController.text.trim(),
                            endDate: endController.text.trim().isEmpty ? null : endController.text.trim(),
                          );
                          ref.invalidate(semestersListProvider);
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
      ),
    );
  }
}
