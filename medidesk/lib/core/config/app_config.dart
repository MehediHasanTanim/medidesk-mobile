enum AppEnvironment { development, staging, production }

class AppConfig {
  const AppConfig._({
    required this.environment,
    required this.baseUrl,
    required this.workManagerTaskName,
  });

  final AppEnvironment environment;
  final String baseUrl;
  final String workManagerTaskName;

  static const AppConfig development = AppConfig._(
    environment: AppEnvironment.development,
    baseUrl: 'http://192.168.0.211:8005/api/v1', // Physical device → host LAN IP
    workManagerTaskName: 'com.medidesk.sync.dev',
  );

  static const AppConfig staging = AppConfig._(
    environment: AppEnvironment.staging,
    baseUrl: 'https://staging-api.medidesk.app/api/v1',
    workManagerTaskName: 'com.medidesk.sync.staging',
  );

  static const AppConfig production = AppConfig._(
    environment: AppEnvironment.production,
    baseUrl: 'https://api.medidesk.app/api/v1',
    workManagerTaskName: 'com.medidesk.sync',
  );

  // Toggle this before building
  static AppConfig get current => development;

  bool get isDebug => environment == AppEnvironment.development;
}
