import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user.dart';
import '../../providers/role_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../data/ui_text.dart';

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
          SnackBar(
              content: Text(UiText.userSaved),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(UiText.error(e)),
              backgroundColor: AppColors.error),
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
        leading: AppBarBackButton(onPressed: () => context.pop()),
        title: Text(_user == null ? UiText.newUser : UiText.editUser),
        actions: [
          AppBarActionButton(
            label: UiText.save,
            loading: _saving,
            onPressed: _save,
            icon: Icons.save_outlined,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero header — identity strip
              EditorHeroHeader(
                title: () {
                  final fullName =
                      '${_firstNameController.text} ${_lastNameController.text}'
                          .trim();
                  if (fullName.isNotEmpty) return fullName;
                  return _user == null ? UiText.newUser : UiText.editUser;
                }(),
                subtitle: _emailController.text.isNotEmpty
                    ? _emailController.text
                    : (_user == null ? UiText.newUser : UiText.editUser),
                leading: GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AvatarWidget(
                        imageUrl: _avatarPath ?? _user?.avatar,
                        initials:
                            initials.isNotEmpty ? initials.toUpperCase() : '?',
                        size: 64,
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Theme.of(context)
                                    .scaffoldBackgroundColor,
                                width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary
                                    .withValues(alpha: 0.30),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                chips: [
                  EditorHeroChip(
                    icon: _isActive
                        ? Icons.check_circle_rounded
                        : Icons.pause_circle_outline_rounded,
                    label: _isActive ? UiText.active : UiText.inactive,
                    color: _isActive ? AppColors.success : AppColors.warning,
                  ),
                  if (_phoneController.text.isNotEmpty)
                    EditorHeroChip(
                      icon: Icons.phone_outlined,
                      label: _phoneController.text,
                      color: AppColors.accent,
                    ),
                ],
                trailing: TextButton.icon(
                  onPressed: _pickAvatar,
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: Text(_avatarPath != null || _user?.avatar != null
                      ? UiText.changePhoto
                      : UiText.uploadPhoto),
                ),
              ),
              const SizedBox(height: 16),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(UiText.userInfo,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: InputDecoration(
                                labelText: UiText.firstNameRequired),
                            onChanged: (_) => setState(() {}),
                            validator: (v) => v?.isEmpty ?? true
                                ? UiText.requiredText
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: InputDecoration(
                                labelText: UiText.lastNameRequired),
                            onChanged: (_) => setState(() {}),
                            validator: (v) => v?.isEmpty ?? true
                                ? UiText.requiredText
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: UiText.emailRequired,
                        prefixIcon: const Icon(Icons.email_outlined, size: 18),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v?.isEmpty ?? true) return UiText.requiredText;
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(v!)) {
                          return UiText.invalidEmail;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: UiText.phone,
                        prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: _user == null
                            ? UiText.passwordRequired
                            : UiText.newPasswordLeaveBlankToKeep,
                        prefixIcon: const Icon(Icons.lock_outline, size: 18),
                      ),
                      validator: _user == null
                          ? (v) {
                              if (v?.isEmpty ?? true) {
                                return UiText.passwordIsRequired;
                              }
                              if (v!.length < 8) {
                                return UiText.atLeast8Characters;
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
                    Text(UiText.access,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    rolesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => Text(UiText.errorLoadingRoles),
                      data: (roles) => DropdownButtonFormField<String?>(
                        value: _selectedRoleId,
                        items: [
                          DropdownMenuItem(
                              value: null, child: Text(UiText.noRole)),
                          ...roles.map((r) => DropdownMenuItem(
                              value: r.id, child: Text(r.name))),
                        ],
                        onChanged: (v) => setState(() => _selectedRoleId = v),
                        decoration: InputDecoration(
                          labelText: UiText.assignedRole3,
                          prefixIcon: const Icon(Icons.shield_outlined, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: Text(UiText.activeAccount),
                      subtitle: Text(UiText.inactiveUsersCannotLogIn),
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
