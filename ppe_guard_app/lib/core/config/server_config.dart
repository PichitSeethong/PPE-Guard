class ServerConfig {
  ServerConfig._();

  static const String _rawBaseUrl = String.fromEnvironment(
    'PPE_SERVER_URL',
    defaultValue: 'http://localhost:8000',
  );

  static String get baseUrl {
    final value = _rawBaseUrl.trim();
    if (value.isEmpty) return 'http://localhost:8000';
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static String get webSocketBaseUrl {
    if (baseUrl.startsWith('https://')) {
      return baseUrl.replaceFirst('https://', 'wss://');
    }
    return baseUrl.replaceFirst('http://', 'ws://');
  }
}
