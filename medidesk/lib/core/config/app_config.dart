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
    baseUrl: 'http://10.0.2.2:8000/api/v1', // Android emulator → host
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
