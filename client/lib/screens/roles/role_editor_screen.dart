import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../models/role.dart';
import '../../providers/role_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class RoleEditorScreen extends ConsumerStatefulWidget {
  final String roleId;

  const RoleEditorScreen({super.key, required this.roleId});

  @override
  ConsumerState<RoleEditorScreen> createState() => _RoleEditorScreenState();
}

class _RoleEditorScreenState extends ConsumerState<RoleEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _level = 'member';
  bool _isActive = true;
  List<Permission> _permissions = [];
  bool _loading = true;
  bool _saving = false;
  Role? _role;

  static const _resources = [
    'companies', 'flows', 'forms', 'models',
    'roles', 'users', 'letters', 'tickets',
  ];

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    if (widget.roleId != 'new') {
      try {
        final repo = ref.read(roleRepositoryProvider);
        _role = await repo.getRole(widget.roleId);
        _nameController.text = _role!.name;
        _descController.text = _role!.description ?? '';
        _level = _role!.level;
        _isActive = _role!.isActive;
        _permissions = List.from(_role!.permissions);
      } catch (_) {}
    } else {
      _permissions = _resources.map((r) => Permission(resource: r)).toList();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'name': _nameController.text,
        'description': _descController.text.isNotEmpty
            ? _descController.text
            : null,
        'level': _level,
        'isActive': _isActive,
        'permissions': _permissions.map((p) => p.toJson()).toList(),
      };
      if (_role == null) {
        await ref.read(roleNotifierProvider.notifier).create(data);
      } else {
        await ref
            .read(roleNotifierProvider.notifier)
            .updateItem(_role!.id, data);
      }
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Role saved'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double get _permissionCoverage {
    if (_permissions.isEmpty) return 0;
    int granted = 0;
    int total = _permissions.length * 4; // create/read/update/delete
    for (final p in _permissions) {
      if (p.canCreate) granted++;
      if (p.canRead) granted++;
      if (p.canUpdate) granted++;
      if (p.canDelete) granted++;
    }
    return granted / total;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final coverage = _permissionCoverage;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(_role == null ? 'New Role' : 'Edit Role'),
        actions: [
          AppButton(
            label: 'Save',
            loading: _saving,
            onPressed: _save,
            icon: Icons.save_outlined,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Role Details',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'Role name *'),
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _level,
                      items: const [
                        DropdownMenuItem(
                            value: 'owner', child: Text('Owner')),
                        DropdownMenuItem(
                            value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(
                            value: 'manager', child: Text('Manager')),
                        DropdownMenuItem(
                            value: 'member', child: Text('Member')),
                        DropdownMenuItem(
                            value: 'viewer', child: Text('Viewer')),
                      ],
                      onChanged: (v) => setState(() => _level = v!),
                      decoration: const InputDecoration(
                          labelText: 'Access level'),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Active'),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Permission coverage indicator
              AppCard(
                child: Row(
                  children: [
                    CircularPercentIndicator(
                      radius: 40,
                      lineWidth: 8,
                      percent: coverage,
                      center: Text(
                        '${(coverage * 100).toInt()}%',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      progressColor: _coverageColor(coverage),
                      backgroundColor:
                          _coverageColor(coverage).withValues(alpha: 0.12),
                      animation: true,
                      animationDuration: 800,
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Permission Coverage',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(coverage * 100).toInt()}% of CRUD operations are granted across all resources.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: AppColors.lightTextSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Permissions DataTable2
              AppCard(
                padding: const EdgeInsets.all(0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text('Permissions',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        'Configure CRUD permissions per resource',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    SizedBox(
                      height: (_resources.length * 52.0) + 56,
                      child: DataTable2(
                        columnSpacing: 0,
                        horizontalMargin: 16,
                        headingRowHeight: 40,
                        dataRowHeight: 52,
                        headingTextStyle: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12),
                        columns: const [
                          DataColumn2(
                              label: Text('Resource'),
                              size: ColumnSize.L),
                          DataColumn2(
                              label: Center(child: Text('Create')),
                              size: ColumnSize.S,
                              numeric: true),
                          DataColumn2(
                              label: Center(child: Text('Read')),
                              size: ColumnSize.S,
                              numeric: true),
                          DataColumn2(
                              label: Center(child: Text('Update')),
                              size: ColumnSize.S,
                              numeric: true),
                          DataColumn2(
                              label: Center(child: Text('Delete')),
                              size: ColumnSize.S,
                              numeric: true),
                        ],
                        rows: _resources.map((resource) {
                          final permIdx = _permissions
                              .indexWhere((p) => p.resource == resource);
                          final perm = permIdx >= 0
                              ? _permissions[permIdx]
                              : Permission(resource: resource);

                          return DataRow2(
                            cells: [
                              DataCell(Text(
                                resource,
                                style: const TextStyle(fontSize: 13),
                              )),
                              DataCell(Center(
                                child: Checkbox(
                                  value: perm.canCreate,
                                  onChanged: (v) => setState(() {
                                    final updated =
                                        perm.copyWith(canCreate: v!);
                                    if (permIdx >= 0) {
                                      _permissions[permIdx] = updated;
                                    } else {
                                      _permissions.add(updated);
                                    }
                                  }),
                                ),
                              )),
                              DataCell(Center(
                                child: Checkbox(
                                  value: perm.canRead,
                                  onChanged: (v) => setState(() {
                                    final updated =
                                        perm.copyWith(canRead: v!);
                                    if (permIdx >= 0) {
                                      _permissions[permIdx] = updated;
                                    } else {
                                      _permissions.add(updated);
                                    }
                                  }),
                                ),
                              )),
                              DataCell(Center(
                                child: Checkbox(
                                  value: perm.canUpdate,
                                  onChanged: (v) => setState(() {
                                    final updated =
                                        perm.copyWith(canUpdate: v!);
                                    if (permIdx >= 0) {
                                      _permissions[permIdx] = updated;
                                    } else {
                                      _permissions.add(updated);
                                    }
                                  }),
                                ),
                              )),
                              DataCell(Center(
                                child: Checkbox(
                                  value: perm.canDelete,
                                  onChanged: (v) => setState(() {
                                    final updated =
                                        perm.copyWith(canDelete: v!);
                                    if (permIdx >= 0) {
                                      _permissions[permIdx] = updated;
                                    } else {
                                      _permissions.add(updated);
                                    }
                                  }),
                                ),
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _coverageColor(double coverage) {
    if (coverage >= 0.7) return AppColors.success;
    if (coverage >= 0.4) return AppColors.warning;
    return AppColors.info;
  }
}
