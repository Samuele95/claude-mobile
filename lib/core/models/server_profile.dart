import 'dart:convert';

enum AuthMethod { key, password }

class ServerProfile {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final AuthMethod authMethod;
  final String startupCommand;
  final DateTime createdAt;

  const ServerProfile({
    required this.id,
    required this.name,
    required this.host,
    this.port = 22,
    required this.username,
    this.authMethod = AuthMethod.password,
    this.startupCommand = 'claude --dangerously-skip-permissions',
    required this.createdAt,
  });

  ServerProfile copyWith({
    String? name,
    String? host,
    int? port,
    String? username,
    AuthMethod? authMethod,
    String? startupCommand,
  }) {
    return ServerProfile(
      id: id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      authMethod: authMethod ?? this.authMethod,
      startupCommand: startupCommand ?? this.startupCommand,
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
        'startupCommand': startupCommand,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ServerProfile.fromJson(Map<String, dynamic> json) => ServerProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        host: json['host'] as String,
        port: json['port'] as int? ?? 22,
        username: json['username'] as String,
        authMethod: AuthMethod.values.firstWhere(
          (e) => e.name == (json['authMethod'] as String?),
          orElse: () => AuthMethod.password,
        ),
        startupCommand: json['startupCommand'] as String? ??
            'claude --dangerously-skip-permissions',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String encode() => jsonEncode(toJson());
  static ServerProfile decode(String source) =>
      ServerProfile.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
