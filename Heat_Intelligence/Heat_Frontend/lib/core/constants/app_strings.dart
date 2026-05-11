/// Centralized string constants
class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'Heat Intelligence';
  static const String appTagline = 'Stay cool. Stay safe.';

  // Onboarding
  static const String onboardTitle1 = 'Real-Time Heat Detection';
  static const String onboardDesc1 =
      'Monitor urban heat islands with live temperature data and satellite-grade analytics.';
  static const String onboardTitle2 = 'Smart Heat Maps';
  static const String onboardDesc2 =
      'Visualize heat zones on interactive maps with color-coded risk levels.';
  static const String onboardTitle3 = 'Intelligent Alerts';
  static const String onboardDesc3 =
      'Get notified before entering high-risk heat zones. AI-powered predictions keep you safe.';

  // Dashboard
  static const String dashboard = 'Dashboard';
  static const String currentTemp = 'Current Temperature';
  static const String heatIndex = 'Heat Index';
  static const String riskLevel = 'Risk Level';
  static const String recommendations = 'Stay Safe Tips';
  static const String heatTrend = '7-Day Heat Trend';

  // Risk levels
  static const String highRisk = 'High Risk';
  static const String moderateRisk = 'Moderate';
  static const String safe = 'Safe';

  // Heat Map
  static const String heatMap = 'Heat Map';
  static const String loadingMap = 'Loading heat zones...';

  // Analysis
  static const String areaAnalysis = 'Area Analysis';
  static const String heatHistory = 'Heat History';
  static const String prediction = 'AI Prediction';

  // Alerts
  static const String alerts = 'Alerts';
  static const String noAlerts = 'No alerts. You\'re in a safe zone!';

  // Settings
  static const String settings = 'Settings';
  static const String darkMode = 'Dark Mode';
  static const String notifications = 'Push Notifications';
  static const String alertThreshold = 'Alert Threshold';
  static const String locationTracking = 'Background Location';
  static const String about = 'About';
  static const String version = 'Version 1.0.0';

  // Actions
  static const String getStarted = 'Get Started';
  static const String next = 'Next';
  static const String skip = 'Skip';
  static const String retry = 'Retry';
  static const String refresh = 'Refresh';

  // Errors
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'No internet connection.';
  static const String errorLocation = 'Unable to get your location.';
  static const String errorPermission = 'Location permission is required.';

  // Recommendations
  static const List<String> highRiskTips = [
    '🧴 Apply sunscreen with SPF 50+',
    '💧 Drink water every 15 minutes',
    '🏠 Stay indoors between 11 AM – 3 PM',
    '👒 Wear a hat and light-colored clothing',
    '🚨 Watch for signs of heat stroke',
  ];

  static const List<String> moderateRiskTips = [
    '💧 Stay hydrated throughout the day',
    '🌳 Seek shade when possible',
    '👕 Wear loose, breathable clothing',
    '⏰ Limit outdoor activities during peak hours',
  ];

  static const List<String> safeTips = [
    '✅ Conditions are comfortable',
    '💧 Keep drinking water regularly',
    '🌤️ Enjoy outdoor activities safely',
  ];
}
