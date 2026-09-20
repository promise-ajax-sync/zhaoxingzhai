import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zhaoxingzhai/core/auth/auth_session.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/app_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.authSession,
    required this.onAccountDeleted,
  });
  final AuthSession authSession;
  final Future<void> Function() onAccountDeleted;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    widget.authSession.addListener(_changed);
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authSession != widget.authSession) {
      oldWidget.authSession.removeListener(_changed);
      widget.authSession.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.authSession.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => AppPageContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppPageHeading(title: '设置', subtitle: '管理账号、个人资料与应用偏好'),
        if (widget.authSession.isSignedIn)
          _AccountCenter(
            session: widget.authSession,
            onAccountDeleted: widget.onAccountDeleted,
          )
        else
          _SignInCard(session: widget.authSession),
        const SizedBox(height: AppTheme.space4),
        const _SettingsSection(
          icon: Icons.shield_outlined,
          title: '隐私与数据',
          description: '历史和角色默认本地优先；登录后才会同步到账户云端。',
        ),
        const SizedBox(height: AppTheme.space3),
        const _SettingsSection(
          icon: Icons.info_outline,
          title: '关于小兆',
          description: '占卜与 AI 解读仅供传统文化研究和休闲参考，不替代专业意见。',
        ),
      ],
    ),
  );
}

class _SignInCard extends StatefulWidget {
  const _SignInCard({required this.session});
  final AuthSession session;

  @override
  State<_SignInCard> createState() => _SignInCardState();
}

class _SignInCardState extends State<_SignInCard> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _register = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (_register) {
        await widget.session.register(
          email: _email.text,
          password: _password.text,
          displayName: _name.text,
        );
      } else {
        await widget.session.login(
          email: _email.text,
          password: _password.text,
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _forgotPassword() async {
    await showDialog<void>(
      context: context,
      builder: (context) => _ResetPasswordDialog(
        session: widget.session,
        initialEmail: _email.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primaryContainer, colors.surfaceContainerLow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final form = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('登录')),
                  ButtonSegment(value: true, label: Text('注册')),
                ],
                selected: {_register},
                onSelectionChanged: _submitting
                    ? null
                    : (value) => setState(() {
                        _register = value.first;
                        _error = null;
                      }),
              ),
              const SizedBox(height: 18),
              if (_register) ...[
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: '昵称',
                    prefixIcon: Icon(Icons.face_outlined),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                key: const ValueKey('settings-auth-email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '邮箱',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('settings-auth-password'),
                controller: _password,
                obscureText: true,
                onSubmitted: (_) => _submitting ? null : _submit(),
                decoration: const InputDecoration(
                  labelText: '密码（至少 8 位）',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: colors.error)),
              ],
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: Icon(_register ? Icons.person_add_alt_1 : Icons.login),
                label: Text(
                  _submitting ? '请稍候…' : (_register ? '创建账号' : '登录账号'),
                ),
              ),
              if (!_register)
                TextButton(
                  onPressed: _submitting ? null : _forgotPassword,
                  child: const Text('忘记密码？'),
                ),
            ],
          );
          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: colors.primary,
                child: Icon(
                  Icons.auto_awesome,
                  color: colors.onPrimary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '把你的记录带在身边',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              const Text('登录后可跨设备恢复历史与角色。游客模式仍然可用，注册时会自动绑定当前设备数据。'),
            ],
          );
          if (constraints.maxWidth < 720) {
            return Column(children: [intro, const SizedBox(height: 28), form]);
          }
          return Row(
            children: [
              Expanded(child: intro),
              const SizedBox(width: 48),
              Expanded(child: form),
            ],
          );
        },
      ),
    );
  }
}

class _AccountCenter extends StatefulWidget {
  const _AccountCenter({required this.session, required this.onAccountDeleted});
  final AuthSession session;
  final Future<void> Function() onAccountDeleted;

  @override
  State<_AccountCenter> createState() => _AccountCenterState();
}

class _AccountCenterState extends State<_AccountCenter> {
  late final TextEditingController _name;
  String? _message;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.session.user?.displayName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      await widget.session.updateProfile(displayName: _name.text);
      if (mounted) setState(() => _message = '个人资料已保存');
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 82,
      );
      if (image == null) return;
      await widget.session.uploadAvatar(
        bytes: await image.readAsBytes(),
        filename: image.name,
      );
      if (mounted) setState(() => _message = '头像已更新');
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => _ChangePasswordDialog(session: widget.session),
    );
    if (changed == true && mounted) {
      setState(() => _message = '密码已修改，请使用新密码重新登录');
    }
  }

  Future<void> _deleteAccount() async {
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DeleteAccountDialog(session: widget.session),
    );
    if (deleted == true) {
      await widget.onAccountDeleted();
    }
  }

  Future<void> _verifyEmail() async {
    try {
      final developmentToken = await widget.session.requestEmailVerification();
      if (!mounted) return;
      final controller = TextEditingController(text: developmentToken ?? '');
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('验证邮箱'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('验证码已发送至 ${widget.session.user!.email}'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: '一次性验证码'),
                ),
                if (developmentToken != null) ...[
                  const SizedBox(height: 8),
                  const Text('开发环境已自动填入调试验证码。'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认验证'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await widget.session.confirmEmail(controller.text);
        if (mounted) setState(() => _message = '邮箱验证成功');
      }
      controller.dispose();
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.session.user!;
    final colors = Theme.of(context).colorScheme;
    final avatarUrl = user.avatarUrl?.trim() ?? '';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InkWell(
                onTap: widget.session.busy ? null : _pickAvatar,
                customBorder: const CircleBorder(),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: colors.primaryContainer,
                      foregroundImage: avatarUrl.isEmpty
                          ? null
                          : NetworkImage(avatarUrl),
                      child: avatarUrl.isEmpty
                          ? Text(
                              String.fromCharCode(
                                (user.displayName ?? user.email).runes.first,
                              ).toUpperCase(),
                            )
                          : null,
                    ),
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.surface, width: 2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Icon(
                            Icons.photo_camera_outlined,
                            size: 15,
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? '小兆用户',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          user.emailVerified
                              ? Icons.verified
                              : Icons.warning_amber,
                          size: 15,
                          color: user.emailVerified
                              ? colors.primary
                              : colors.tertiary,
                        ),
                        const SizedBox(width: 5),
                        Text(user.emailVerified ? '邮箱已验证' : '邮箱尚未验证'),
                      ],
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: widget.session.busy ? null : widget.session.logout,
                icon: const Icon(Icons.logout),
                label: const Text('退出账号'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: '用户名',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.session.busy ? null : _pickAvatar,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('从相册更换头像'),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: widget.session.busy ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('保存资料'),
              ),
              if (!user.emailVerified)
                OutlinedButton.icon(
                  onPressed: widget.session.busy ? null : _verifyEmail,
                  icon: const Icon(Icons.mark_email_read_outlined),
                  label: const Text('验证邮箱'),
                ),
              OutlinedButton.icon(
                onPressed: widget.session.busy ? null : _changePassword,
                icon: const Icon(Icons.password_outlined),
                label: const Text('修改密码'),
              ),
              OutlinedButton.icon(
                onPressed: widget.session.busy ? null : _deleteAccount,
                style: OutlinedButton.styleFrom(foregroundColor: colors.error),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('注销账号'),
              ),
            ],
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!, style: TextStyle(color: colors.primary)),
          ],
        ],
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.session});
  final AuthSession session;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_confirmation.text.trim() != '注销账号') {
      setState(() => _error = '请输入“注销账号”完成确认');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.session.deleteAccount(password: _password.text);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: Icon(
      Icons.warning_amber_rounded,
      color: Theme.of(context).colorScheme.error,
    ),
    title: const Text('永久注销账号'),
    content: SizedBox(
      width: 410,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('注销后，云端账号、角色、占卜历史、AI 解读和头像都会永久删除，且无法恢复。本机相关数据也会被清除。'),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: '当前密码'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmation,
            decoration: const InputDecoration(labelText: '输入“注销账号”确认'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context, false),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: _busy ? null : _submit,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
        child: Text(_busy ? '正在注销…' : '永久删除'),
      ),
    ],
  );
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.session});
  final AuthSession session;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({
    required this.session,
    required this.initialEmail,
  });
  final AuthSession session;
  final String initialEmail;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  late final TextEditingController _email;
  final _token = TextEditingController();
  final _password = TextEditingController();
  bool _codeRequested = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final developmentToken = await widget.session.requestPasswordReset(
        _email.text,
      );
      if (developmentToken != null) {
        _token.text = developmentToken;
      }
      if (mounted) {
        setState(() => _codeRequested = true);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _reset() async {
    if (_password.text.length < 8) {
      setState(() => _error = '新密码至少需要 8 位');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.session.resetPassword(
        resetToken: _token.text,
        newPassword: _password.text,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('找回密码'),
    content: SizedBox(
      width: 390,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _email,
            enabled: !_codeRequested,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: '注册邮箱'),
          ),
          if (_codeRequested) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _token,
              decoration: const InputDecoration(labelText: '重置验证码'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: '新密码（至少 8 位）'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: _busy ? null : (_codeRequested ? _reset : _requestCode),
        child: Text(_busy ? '请稍候…' : (_codeRequested ? '重置密码' : '发送验证码')),
      ),
    ],
  );
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_next.text.length < 8) {
      setState(() => _error = '新密码至少需要 8 位');
      return;
    }
    if (_next.text != _confirm.text) {
      setState(() => _error = '两次输入的新密码不一致');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.session.changePassword(
        currentPassword: _current.text,
        newPassword: _next.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('修改密码'),
    content: SizedBox(
      width: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _current,
            obscureText: true,
            decoration: const InputDecoration(labelText: '当前密码'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _next,
            obscureText: true,
            decoration: const InputDecoration(labelText: '新密码（至少 8 位）'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirm,
            obscureText: true,
            onSubmitted: (_) => _busy ? null : _submit(),
            decoration: const InputDecoration(labelText: '再次输入新密码'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context, false),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: _busy ? null : _submit,
        child: Text(_busy ? '修改中…' : '确认修改'),
      ),
    ],
  );
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(description, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}
