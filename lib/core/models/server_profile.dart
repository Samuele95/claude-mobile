import 'dart:convert';

enum AuthMethod { key, password }

enum ClaudeMode { standard, skipPermissions, customPrompt }

class ServerProfile {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final AuthMethod authMethod;
  final ClaudeMode claudeMode;
  final String customPrompt;
  final DateTime createdAt;

  const ServerProfile({
    required this.id,
    required this.name,
    required this.host,
    this.port = 22,
    required this.username,
    this.authMethod = AuthMethod.password,
    this.claudeMode = ClaudeMode.skipPermissions,
    this.customPrompt = '',
    required this.createdAt,
  });

  ServerProfile copyWith({
    String? name,
    String? host,
    int? port,
    String? username,
    AuthMethod? authMethod,
    ClaudeMode? claudeMode,
    String? customPrompt,
  }) {
    return ServerProfile(
      id: id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      authMethod: authMethod ?? this.authMethod,
      claudeMode: claudeMode ?? this.claudeMode,
      customPrompt: customPrompt ?? this.customPrompt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'port': port,
        'username': username,
        'authMethod': authMethod.name,
        'claudeMode': claudeMode.name,
        'customPrompt': customPrompt,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ServerProfile.fromJson(Map<String, dynamic> json) {
    // Backward compat: map old startupCommand to claudeMode
    ClaudeMode mode = ClaudeMode.skipPermissions;
    String prompt = '';
    if (json.containsKey('claudeMode')) {
      mode = ClaudeMode.values.firstWhere(
        (e) => e.name == (json['claudeMode'] as String?),
        orElse: () => ClaudeMode.skipPermissions,
      );
      prompt = json['customPrompt'] as String? ?? '';
    } else if (json.containsKey('startupCommand')) {
      final cmd = json['startupCommand'] as String? ?? '';
      if (cmd == 'claude') {
        mode = ClaudeMode.standard;
      } else if (cmd.contains('-p ')) {
        mode = ClaudeMode.customPrompt;
        final match = RegExp(r'-p\s+"([^"]*)"').firstMatch(cmd);
        prompt = match?.group(1) ?? cmd;
      } else {
        mode = ClaudeMode.skipPermissions;
      }
    }

    return ServerProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      host: json['host'] as String,
      port: json['port'] as int? ?? 22,
      username: json['username'] as String,
      authMethod: AuthMethod.values.firstWhere(
        (e) => e.name == (json['authMethod'] as String?),
        orElse: () => AuthMethod.password,
      ),
      claudeMode: mode,
      customPrompt: prompt,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String encode() => jsonEncode(toJson());
  static ServerProfile decode(String source) =>
      ServerProfile.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
