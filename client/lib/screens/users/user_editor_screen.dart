import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user.dart';
import '../../providers/role_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../data/mock_ui_text.dart';

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
  String? _avatarPath;

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

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked != null && mounted) {
      setState(() => _avatarPath = picked.path);
    }
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
        if (_avatarPath != null) 'avatar': _avatarPath,
        'isActive': _isActive,
      };
      if (_user == null) {
        await ref.read(userNotifierProvider.notifier).create(data);
      } else {
        await ref
            .read(userNotifierProvider.notifier)
            .updateItem(_user!.id, data);
      }
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(MockUiText.userSaved),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(MockUiText.error(e)), backgroundColor: AppColors.error),
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

    final initials = (_firstNameController.text.isNotEmpty
            ? _firstNameController.text[0]
            : '') +
        (_lastNameController.text.isNotEmpty
            ? _lastNameController.text[0]
            : '');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(_user == null ? MockUiText.newUser : MockUiText.editUser),
        actions: [
          AppButton(
            label: MockUiText.save,
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
              // Avatar picker
              Center(
                child: Stack(
                  children: [
                    AvatarWidget(
                      imageUrl: _avatarPath ?? _user?.avatar,
                      initials: initials.isNotEmpty
                          ? initials.toUpperCase()
                          : '?',
                      size: 88,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _pickAvatar,
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: Text(_avatarPath != null || _user?.avatar != null
                    ? MockUiText.changePhoto
                    : MockUiText.uploadPhoto),
              ),
              const SizedBox(height: 16),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(MockUiText.userInfo,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                                labelText: MockUiText.firstNameRequired),
                            onChanged: (_) => setState(() {}),
                            validator: (v) =>
                                v?.isEmpty ?? true ? MockUiText.requiredText : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                                labelText: MockUiText.lastNameRequired),
                            onChanged: (_) => setState(() {}),
                            validator: (v) =>
                                v?.isEmpty ?? true ? MockUiText.requiredText : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: MockUiText.emailRequired,
                        prefixIcon: Icon(Icons.email_outlined, size: 18),
                      ),
                      validator: (v) {
                        if (v?.isEmpty ?? true) return MockUiText.requiredText;
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(v!)) {
                          return MockUiText.invalidEmail;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: MockUiText.phone,
                        prefixIcon: Icon(Icons.phone_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: _user == null
                            ? MockUiText.passwordRequired
                            : MockUiText.newPasswordLeaveBlankToKeep,
                        prefixIcon: const Icon(Icons.lock_outline, size: 18),
                      ),
                      validator: _user == null
                          ? (v) {
                              if (v?.isEmpty ?? true) {
                                return MockUiText.passwordIsRequired;
                              }
                              if (v!.length < 8) {
                                return MockUiText.atLeast8Characters;
                              }
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
                    Text(MockUiText.access,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    rolesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => Text(MockUiText.errorLoadingRoles),
                      data: (roles) => DropdownButtonFormField<String?>(
                        value: _selectedRoleId,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text(MockUiText.noRole)),
                          ...roles.map((r) => DropdownMenuItem(
                              value: r.id, child: Text(r.name))),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedRoleId = v),
                        decoration: const InputDecoration(
                          labelText: MockUiText.assignedRole3,
                          prefixIcon: Icon(Icons.shield_outlined, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: Text(MockUiText.activeAccount),
                      subtitle:
                          Text(MockUiText.inactiveUsersCannotLogIn),
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
