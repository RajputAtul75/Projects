/// Frontend heat risk calculation logic
class HeatRiskCalculator {
  HeatRiskCalculator._();

  /// Calculate risk score from temperature, humidity, and optional UV index
  /// Returns a value between 0.0 and 1.0
  static double calculateRiskScore({
    required double temperature,
    required double humidity,
    double? uvIndex,
    double? windSpeed,
  }) {
    // Base risk from temperature (normalized: 25°C = 0, 50°C = 1)
    double tempRisk = ((temperature - 25) / 25).clamp(0.0, 1.0);

    // Humidity amplifier (high humidity worsens heat)
    double humidityFactor = (humidity / 100) * 0.3;

    // UV amplifier
    double uvFactor = 0;
    if (uvIndex != null) {
      uvFactor = (uvIndex / 11) * 0.15;
    }

    // Wind relief (wind lowers perceived risk slightly)
    double windRelief = 0;
    if (windSpeed != null && windSpeed > 0) {
      windRelief = (windSpeed / 40).clamp(0.0, 0.1);
    }

    double score = (tempRisk * 0.55) + humidityFactor + uvFactor - windRelief;
    return score.clamp(0.0, 1.0);
  }

  /// Calculate Heat Index (apparent temperature) using Steadman formula
  static double calculateHeatIndex({
    required double temperatureC,
    required double humidityPercent,
  }) {
    // Convert to Fahrenheit for the formula
    double tf = (temperatureC * 9 / 5) + 32;
    double rh = humidityPercent;

    double hi = -42.379 +
        2.04901523 * tf +
        10.14333127 * rh -
        0.22475541 * tf * rh -
        0.00683783 * tf * tf -
        0.05481717 * rh * rh +
        0.00122874 * tf * tf * rh +
        0.00085282 * tf * rh * rh -
        0.00000199 * tf * tf * rh * rh;

    // Convert back to Celsius
    return (hi - 32) * 5 / 9;
  }

  /// Get risk level label
  static String getRiskLabel(double score) {
    if (score >= 0.75) return 'High Risk';
    if (score >= 0.40) return 'Moderate';
    return 'Safe';
  }

  /// Get emoji for risk level
  static String getRiskEmoji(double score) {
    if (score >= 0.75) return '🔴';
    if (score >= 0.40) return '🟡';
    return '🟢';
  }

  /// Get detailed recommendation text
  static String getRecommendation(double score) {
    if (score >= 0.75) {
      return 'Extreme heat conditions detected. Stay indoors, hydrate frequently, and avoid physical exertion.';
    }
    if (score >= 0.40) {
      return 'Moderate heat. Limit outdoor exposure during peak hours and stay hydrated.';
    }
    return 'Conditions are comfortable. Stay hydrated and enjoy your day!';
  }
}
