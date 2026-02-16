import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/server_profile.dart';
import '../../core/providers.dart';
import '../../core/ssh/ssh_service.dart';
import '../settings/preferences_provider.dart';

class AddServerSheet extends ConsumerStatefulWidget {
  final ServerProfile? existing;

  const AddServerSheet({super.key, this.existing});

  @override
  ConsumerState<AddServerSheet> createState() => _AddServerSheetState();
}

class _AddServerSheetState extends ConsumerState<AddServerSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _hostCtrl;
  late final TextEditingController _portCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _customPromptCtrl;
  AuthMethod _authMethod = AuthMethod.password;
  ClaudeMode _claudeMode = ClaudeMode.skipPermissions;
  bool _testing = false;
  String? _testResult;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _hostCtrl = TextEditingController(text: widget.existing?.host ?? '');
    _portCtrl =
        TextEditingController(text: (widget.existing?.port ?? 22).toString());
    _userCtrl = TextEditingController(text: widget.existing?.username ?? '');
    _passwordCtrl = TextEditingController();
    _customPromptCtrl =
        TextEditingController(text: widget.existing?.customPrompt ?? '');
    _authMethod = widget.existing?.authMethod ?? AuthMethod.password;
    _claudeMode = widget.existing?.claudeMode ?? ClaudeMode.skipPermissions;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passwordCtrl.dispose();
    _customPromptCtrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _testing = true;
      _testResult = null;
    });

    final profile = _buildProfile();
    final keyManager = ref.read(keyManagerProvider);
    // Create a temporary SshService to avoid mutating global state
    final tempSsh = SshService(keyManager: keyManager);

    try {
      await tempSsh.connect(profile, password: _passwordCtrl.text);
      await tempSsh.disconnect();
      if (mounted) setState(() => _testResult = 'success');
    } catch (e) {
      if (mounted) setState(() => _testResult = e.toString());
    } finally {
      await tempSsh.dispose();
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = ref.read(preferencesProvider);
    if (prefs.haptics) HapticFeedback.lightImpact();

    final profile = _buildProfile();
    await ref.read(profilesProvider.notifier).add(profile);

    // Store password securely if using password auth
    if (_authMethod == AuthMethod.password && _passwordCtrl.text.isNotEmpty) {
      final storage = ref.read(secureStorageProvider);
      await storage.write(
        key: 'password_${profile.id}',
        value: _passwordCtrl.text,
      );
    }

    if (mounted) Navigator.of(context).pop(profile);
  }

  ServerProfile _buildProfile() {
    return ServerProfile(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      host: _hostCtrl.text.trim(),
      port: int.tryParse(_portCtrl.text) ?? 22,
      username: _userCtrl.text.trim(),
      authMethod: _authMethod,
      claudeMode: _claudeMode,
      customPrompt: _customPromptCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.existing != null ? 'Edit Server' : 'Add Server',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) =>
                        v?.trim().isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _hostCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Host / IP Address'),
                    keyboardType: TextInputType.url,
                    validator: (v) =>
                        v?.trim().isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _portCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Port'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _userCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Username'),
                          validator: (v) =>
                              v?.trim().isEmpty == true ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<AuthMethod>(
                    segments: const [
                      ButtonSegment(
                        value: AuthMethod.password,
                        label: Text('Password'),
                        icon: Icon(Icons.key),
                      ),
                      ButtonSegment(
                        value: AuthMethod.key,
                        label: Text('SSH Key'),
                        icon: Icon(Icons.vpn_key),
                      ),
                    ],
                    selected: {_authMethod},
                    onSelectionChanged: (s) =>
                        setState(() => _authMethod = s.first),
                  ),
                  const SizedBox(height: 12),
                  if (_authMethod == AuthMethod.password)
                    TextFormField(
                      controller: _passwordCtrl,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (v) => _authMethod == AuthMethod.password &&
                              (v?.isEmpty ?? true)
                          ? 'Required'
                          : null,
                    )
                  else
                    Text(
                      'The app\'s SSH key must be added to ~/.ssh/authorized_keys on the server.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ClaudeMode>(
                    initialValue: _claudeMode,
                    decoration:
                        const InputDecoration(labelText: 'Claude Mode'),
                    items: const [
                      DropdownMenuItem(
                        value: ClaudeMode.standard,
                        child: Text('Standard Shell'),
                      ),
                      DropdownMenuItem(
                        value: ClaudeMode.skipPermissions,
                        child: Text('Skip Permissions'),
                      ),
                      DropdownMenuItem(
                        value: ClaudeMode.customPrompt,
                        child: Text('Custom Prompt'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _claudeMode = v);
                    },
                  ),
                  if (_claudeMode == ClaudeMode.customPrompt) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customPromptCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Prompt Text',
                        hintText: 'Enter your prompt...',
                      ),
                      maxLines: 3,
                      minLines: 1,
                      validator: (v) =>
                          _claudeMode == ClaudeMode.customPrompt &&
                                  (v?.trim().isEmpty ?? true)
                              ? 'Required for custom prompt mode'
                              : null,
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (_testResult != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _testResult == 'success'
                            ? 'Connection successful'
                            : 'Failed: $_testResult',
                        style: TextStyle(
                          color: _testResult == 'success'
                              ? Colors.green
                              : Colors.redAccent,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _testing ? null : _testConnection,
                          child: _testing
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Text('Test'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _save,
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
