import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../models/user.dart';
import '../../providers/role_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class UserEditorScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserEditorScreen({super.key, required this.userId});

  @override
  ConsumerState<UserEditorScreen> createState() => _UserEditorScreenState();
}

class _UserEditorScreenState extends ConsumerState<UserEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedRoleId;
  bool _isActive = true;
  bool _loading = true;
  bool _saving = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (widget.userId != 'new') {
      try {
        final repo = ref.read(userRepositoryProvider);
        _user = await repo.getUser(widget.userId);
        _firstNameController.text = _user!.firstName;
        _lastNameController.text = _user!.lastName;
        _emailController.text = _user!.email;
        _phoneController.text = _user!.phone ?? '';
        _selectedRoleId = _user!.roleId;
        _isActive = _user!.isActive;
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text,
        if (_passwordController.text.isNotEmpty)
          'password': _passwordController.text,
        if (_phoneController.text.isNotEmpty) 'phone': _phoneController.text,
        if (_selectedRoleId != null) 'roleId': _selectedRoleId,
        'isActive': _isActive,
      };
      if (_user == null) {
        await ref.read(userNotifierProvider.notifier).create(data);
      } else {
        await ref.read(userNotifierProvider.notifier).updateItem(_user!.id, data);
      }
      if (mounted) {
        context.go(AppRoutes.users);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User saved'), backgroundColor: AppColors.success),
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(rolesProvider(null));

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.users),
        ),
        title: Text(_user == null ? 'New User' : 'Edit User'),
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
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User Info',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration:
                                const InputDecoration(labelText: 'First name *'),
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration:
                                const InputDecoration(labelText: 'Last name *'),
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        prefixIcon: Icon(Icons.email_outlined, size: 18),
                      ),
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Required';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(v!)) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.phone_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: _user == null
                            ? 'Password *'
                            : 'New password (leave blank to keep)',
                        prefixIcon:
                            const Icon(Icons.lock_outline, size: 18),
                      ),
                      validator: _user == null
                          ? (v) {
                              if (v?.isEmpty ?? true)
                                return 'Password is required';
                              if (v!.length < 8)
                                return 'At least 8 characters';
                              return null;
                            }
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Access',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    rolesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) =>
                          const Text('Error loading roles'),
                      data: (roles) =>
                          DropdownButtonFormField<String?>(
                        value: _selectedRoleId,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('No role')),
                          ...roles.map((r) => DropdownMenuItem(
                              value: r.id, child: Text(r.name))),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedRoleId = v),
                        decoration: const InputDecoration(
                          labelText: 'Assigned role',
                          prefixIcon:
                              Icon(Icons.shield_outlined, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Active account'),
                      subtitle: const Text(
                          'Inactive users cannot log in'),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      contentPadding: EdgeInsets.zero,
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
}
