class Branch {
  final int id;
  final String displayName;
  final String extension;
  final String server;
  final String port;
  final String protocol;
  final String destinationCall;
  final String password;

  Branch({
    required this.id,
    required this.displayName,
    required this.extension,
    required this.server,
    required this.port,
    required this.protocol,
    required this.destinationCall,
    required this.password,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'],
      displayName: json['display_name'],
      extension: json['extension'],
      server: json['server'],
      port: json['port'],
      protocol: json['protocol'],
      destinationCall: json['destination_call'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'extension': extension,
      'server': server,
      'port': port,
      'protocol': protocol,
      'destination_call': destinationCall,
      'password': password,
    };
  }

  String get name => displayName;
}
