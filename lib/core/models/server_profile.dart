import 'dart:convert';

class ServerProfile {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final DateTime createdAt;

  const ServerProfile({
    required this.id,
    required this.name,
    required this.host,
    this.port = 22,
    required this.username,
    required this.createdAt,
  });

  ServerProfile copyWith({
    String? name,
    String? host,
    int? port,
    String? username,
  }) {
    return ServerProfile(
      id: id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'port': port,
        'username': username,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ServerProfile.fromJson(Map<String, dynamic> json) => ServerProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        host: json['host'] as String,
        port: json['port'] as int? ?? 22,
        username: json['username'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String encode() => jsonEncode(toJson());
  static ServerProfile decode(String source) =>
      ServerProfile.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
