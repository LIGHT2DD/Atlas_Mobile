import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/status_badge.dart';
import 'coordinator_repository.dart';

class CoordinatorUsersScreen extends ConsumerStatefulWidget {
  const CoordinatorUsersScreen({super.key});

  @override
  ConsumerState<CoordinatorUsersScreen> createState() => _CoordinatorUsersScreenState();
}

class _CoordinatorUsersScreenState extends ConsumerState<CoordinatorUsersScreen> {
  int _selectedTabIndex = 0; // 0 = Supervisors, 1 = Coordinators
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final neuTheme = context.neuTheme;
    final selectedRole = _selectedTabIndex == 0 ? 'supervisor' : 'coordinator';
    final usersAsync = ref.watch(coordinatorUsersProvider(selectedRole));

    return Scaffold(
      backgroundColor: neuTheme.baseColor,
      appBar: const NeuAppBar(title: 'User Management'),
      drawer: const AtlasDrawer(),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            children: [
              // Top Controls & Segment Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: IosNeuSegmentPill(
                            label: 'Supervisors',
                            isSelected: _selectedTabIndex == 0,
                            onTap: () => setState(() => _selectedTabIndex = 0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: IosNeuSegmentPill(
                            label: 'Coordinators',
                            isSelected: _selectedTabIndex == 1,
                            onTap: () => setState(() => _selectedTabIndex = 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Search Bar
                    IosNeuSearchBar(
                      hintText: _selectedTabIndex == 0
                          ? 'Search supervisors by name or email...'
                          : 'Search coordinators by name or email...',
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    ),
                  ],
                ),
              ),

              // User List Body
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(coordinatorUsersProvider(selectedRole));
                  },
                  child: usersAsync.when(
                    loading: () => const LoadingIndicator(message: 'Loading user roster...'),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(TablerIcons.alert_circle, color: neuTheme.dangerColor, size: 40),
                            const SizedBox(height: 12),
                            Text('Failed to load roster: $e', textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            NeuButton(
                              text: 'Retry',
                              onPressed: () => ref.invalidate(coordinatorUsersProvider(selectedRole)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  data: (users) {
                    final filtered = users.where((u) {
                      if (_searchQuery.isEmpty) return true;
                      return u.fullName.toLowerCase().contains(_searchQuery) ||
                          u.email.toLowerCase().contains(_searchQuery) ||
                          (u.departmentName?.toLowerCase().contains(_searchQuery) ?? false);
                    }).toList();

                    if (filtered.isEmpty) {
                      return EmptyState(
                        icon: _selectedTabIndex == 0 ? TablerIcons.school : TablerIcons.shield_check,
                        title: _selectedTabIndex == 0 ? 'No Supervisors Found' : 'No Coordinators Found',
                        message: _searchQuery.isNotEmpty
                            ? 'No users match your search query.'
                            : _selectedTabIndex == 0
                                ? 'No faculty supervisors are currently registered.'
                                : 'No additional department coordinators registered.',
                        actionLabel: _selectedTabIndex == 0 ? 'Add First Supervisor' : 'Add Coordinator',
                        onAction: () => _showAddUserModal(context, role: selectedRole),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final user = filtered[index];
                        final isCoord = user.role.toLowerCase() == 'coordinator';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: IosNeuCard(
                            borderRadius: BorderRadius.circular(20),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Avatar Initial
                                Container(
                                  width: 46,
                                  height: 46,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isCoord
                                        ? const Color(0xFF805AD5).withValues(alpha: 0.15)
                                        : const Color(0xFF38A169).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isCoord ? TablerIcons.shield : TablerIcons.user_check,
                                    color: isCoord ? const Color(0xFF805AD5) : const Color(0xFF38A169),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // User Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              user.fullName,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: neuTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                          StatusBadge(
                                            status: isCoord ? 'coordinator' : 'approved',
                                            customLabel: isCoord ? 'COORDINATOR' : 'SUPERVISOR',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        user.email,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: neuTheme.textSecondary,
                                        ),
                                      ),
                                      if (user.departmentName != null && user.departmentName!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              TablerIcons.building,
                                              size: 13,
                                              color: neuTheme.accentColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              user.departmentName!,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: neuTheme.accentColor,
                                              ),
                                            ),
                                          ],
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
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: IosNeuFAB(
          icon: _selectedTabIndex == 0 ? TablerIcons.user_plus : TablerIcons.shield_lock,
          tooltip: _selectedTabIndex == 0 ? 'Add Supervisor' : 'Add Coordinator',
          onPressed: () => _showAddUserModal(context, role: selectedRole),
        ),
      ),
    );
  }

  void _showAddUserModal(BuildContext context, {required String role}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddUserModalSheet(role: role),
    );
  }
}

class _AddUserModalSheet extends ConsumerStatefulWidget {
  final String role; // 'supervisor' or 'coordinator'

  const _AddUserModalSheet({required this.role});

  @override
  ConsumerState<_AddUserModalSheet> createState() => _AddUserModalSheetState();
}

class _AddUserModalSheetState extends ConsumerState<_AddUserModalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _currentPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureCurrentPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isCoord = widget.role == 'coordinator';
    if (isCoord && !_emailController.text.trim().toLowerCase().endsWith('@atlas.edu')) {
      NeuToast.show(
        context,
        message: 'Coordinator accounts must use an institutional email ending with @atlas.edu.',
        type: NeuToastType.error,
        title: 'Institutional Domain Required',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(coordinatorRepositoryProvider);
      final newUser = await repo.createUser(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
        role: widget.role,
        currentPassword: isCoord ? _currentPasswordController.text : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ref.invalidate(coordinatorUsersProvider);

        NeuToast.show(
          context,
          message: '${widget.role.capitalize()} account created for ${newUser.fullName}.',
          type: NeuToastType.success,
          title: 'Account Created',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        NeuToast.show(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
          type: NeuToastType.error,
          title: 'Creation Failed',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final neuTheme = context.neuTheme;
    final isCoord = widget.role == 'coordinator';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: neuTheme.baseColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle Drag bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: neuTheme.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isCoord
                          ? const Color(0xFF805AD5).withValues(alpha: 0.15)
                          : neuTheme.accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCoord ? TablerIcons.shield_lock : TablerIcons.user_plus,
                      color: isCoord ? const Color(0xFF805AD5) : neuTheme.accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCoord ? 'Add Academic Coordinator' : 'Add Faculty Supervisor',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: neuTheme.textPrimary,
                          ),
                        ),
                        Text(
                          isCoord
                              ? 'Enforces elevated sudo verification & @atlas.edu'
                              : 'Registers a new thesis mentor to the faculty roster',
                          style: TextStyle(
                            fontSize: 12,
                            color: neuTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Sudo Mode Warning Banner for Coordinator
              if (isCoord) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF805AD5).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF805AD5).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(TablerIcons.shield_lock, color: Color(0xFF805AD5), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Elevated Administrative Authority: New coordinators hold full institutional privileges. Current coordinator password verification is enforced.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: neuTheme.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Name Inputs
              Row(
                children: [
                  Expanded(
                    child: NeuTextField(
                      controller: _firstNameController,
                      labelText: 'First Name',
                      hintText: isCoord ? 'Prof. David' : 'Dr. Sarah',
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeuTextField(
                      controller: _lastNameController,
                      labelText: 'Last Name',
                      hintText: isCoord ? 'Miller' : 'Jenkins',
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Email Input
              NeuTextField(
                controller: _emailController,
                labelText: 'Institutional Email',
                hintText: isCoord ? 'coordinator@atlas.edu' : 'supervisor@atlas.edu',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  if (isCoord && !v.trim().toLowerCase().endsWith('@atlas.edu')) {
                    return 'Must end with @atlas.edu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Password Input
              NeuTextField(
                controller: _passwordController,
                labelText: 'Initial Account Password',
                hintText: 'Minimum 8 characters',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? TablerIcons.eye_off : TablerIcons.eye,
                    size: 18,
                    color: neuTheme.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) => (v == null || v.length < 8) ? 'At least 8 characters required' : null,
              ),
              const SizedBox(height: 14),

              // Current Coordinator Password (Sudo Check)
              if (isCoord) ...[
                NeuTextField(
                  controller: _currentPasswordController,
                  labelText: 'Your Current Coordinator Password (Sudo Mode)',
                  hintText: 'Enter your password to authorize',
                  obscureText: _obscureCurrentPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword ? TablerIcons.eye_off : TablerIcons.eye,
                      size: 18,
                      color: neuTheme.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Current password is required to create a coordinator'
                      : null,
                ),
                const SizedBox(height: 20),
              ] else ...[
                const SizedBox(height: 6),
              ],

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: NeuButton(
                      text: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: NeuButton(
                      text: _isLoading
                          ? 'Creating...'
                          : isCoord
                              ? 'Authorize & Create'
                              : 'Create Supervisor',
                      icon: isCoord ? TablerIcons.shield_check : TablerIcons.user_plus,
                      onPressed: _isLoading ? null : _submit,
                    ),
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

extension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
