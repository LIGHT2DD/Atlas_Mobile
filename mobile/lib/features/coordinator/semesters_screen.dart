import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/atlas_card.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/status_badge.dart';
import 'coordinator_repository.dart';

final semestersListProvider = FutureProvider.autoDispose<List<SemesterModel>>((ref) async {
  final repo = ref.watch(coordinatorRepositoryProvider);
  return repo.getSemesters();
});

class SemestersScreen extends ConsumerWidget {
  const SemestersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semestersAsync = ref.watch(semestersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Semesters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(semestersListProvider),
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
                  icon: Icons.calendar_today_outlined,
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
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
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
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.check_circle_outline, size: 16),
                              label: const Text('Set as Active Semester'),
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
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Term'),
        onPressed: () => _createSemesterDialog(context, ref),
      ),
    );
  }

  void _createSemesterDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final startController = TextEditingController();
    final endController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Academic Term'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Semester Name *', hintText: 'Fall 2026'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Code *', hintText: 'F2026'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: startController,
                decoration: const InputDecoration(labelText: 'Start Date (YYYY-MM-DD)', hintText: '2026-09-01'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: endController,
                decoration: const InputDecoration(labelText: 'End Date (YYYY-MM-DD)', hintText: '2026-12-20'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Create Term'),
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
    );
  }
}
