import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
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
      _permissions = _resources
          .map((r) => Permission(resource: r))
          .toList();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'name': _nameController.text,
        'description': _descController.text.isNotEmpty ? _descController.text : null,
        'level': _level,
        'isActive': _isActive,
        'permissions': _permissions.map((p) => p.toJson()).toList(),
      };
      if (_role == null) {
        await ref.read(roleNotifierProvider.notifier).create(data);
      } else {
        await ref.read(roleNotifierProvider.notifier).update(_role!.id, data);
      }
      if (mounted) {
        context.go(AppRoutes.roles);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Role saved'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.roles),
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
                        DropdownMenuItem(value: 'owner', child: Text('Owner')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
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

              // Permissions
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Permissions',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Configure CRUD permissions per resource',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    // Header
                    Row(
                      children: [
                        const Expanded(
                            flex: 3,
                            child: Text('Resource',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12))),
                        ...['Create', 'Read', 'Update', 'Delete'].map(
                          (h) => Expanded(
                            child: Center(
                              child: Text(h,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    ..._resources.asMap().entries.map((e) {
                      final resource = e.value;
                      final permIdx = _permissions
                          .indexWhere((p) => p.resource == resource);
                      final perm = permIdx >= 0
                          ? _permissions[permIdx]
                          : Permission(resource: resource);

                      return _PermissionRow(
                        permission: perm,
                        onChanged: (updated) {
                          setState(() {
                            if (permIdx >= 0) {
                              _permissions[permIdx] = updated;
                            } else {
                              _permissions.add(updated);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final Permission permission;
  final ValueChanged<Permission> onChanged;

  const _PermissionRow({required this.permission, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              permission.resource,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: Checkbox(
              value: permission.canCreate,
              onChanged: (v) =>
                  onChanged(permission.copyWith(canCreate: v!)),
            ),
          ),
          Expanded(
            child: Checkbox(
              value: permission.canRead,
              onChanged: (v) =>
                  onChanged(permission.copyWith(canRead: v!)),
            ),
          ),
          Expanded(
            child: Checkbox(
              value: permission.canUpdate,
              onChanged: (v) =>
                  onChanged(permission.copyWith(canUpdate: v!)),
            ),
          ),
          Expanded(
            child: Checkbox(
              value: permission.canDelete,
              onChanged: (v) =>
                  onChanged(permission.copyWith(canDelete: v!)),
            ),
          ),
        ],
      ),
    );
  }
}
