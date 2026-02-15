import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/server_profile.dart';
import '../../core/providers.dart';

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
  bool _testing = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _hostCtrl = TextEditingController(text: widget.existing?.host ?? '');
    _portCtrl =
        TextEditingController(text: (widget.existing?.port ?? 22).toString());
    _userCtrl = TextEditingController(text: widget.existing?.username ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _testing = true;
      _testResult = null;
    });

    final profile = _buildProfile();
    final ssh = ref.read(sshServiceProvider);

    try {
      await ssh.connect(profile);
      await ssh.disconnect();
      setState(() => _testResult = 'success');
    } catch (e) {
      setState(() => _testResult = e.toString());
    } finally {
      setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = _buildProfile();
    await ref.read(profilesProvider.notifier).add(profile);
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
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
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
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hostCtrl,
              decoration:
                  const InputDecoration(labelText: 'Host (Tailscale IP)'),
              keyboardType: TextInputType.url,
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _portCtrl,
                    decoration: const InputDecoration(labelText: 'Port'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (v) =>
                        v?.trim().isEmpty == true ? 'Required' : null,
                  ),
                ),
              ],
            ),
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
                            child: CircularProgressIndicator(strokeWidth: 2),
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
          ],
        ),
      ),
    );
  }
}
