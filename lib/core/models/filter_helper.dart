class FilterHelper {
  static const Map<String, String> countryCodeMap = {
    'USA': 'US',
    'India': 'IN',
    'Korea': 'KR',
    'Japan': 'JP',
    'China': 'CN',
    'Vietnam': 'VN',
    'United Kingdom': 'GB',
    'France': 'FR',
    'Germany': 'DE',
    'Spain': 'ES',
    'Italy': 'IT',
    'Thailand': 'TH',
    'Hong Kong': 'HK',
    'Taiwan': 'TW',
  };

  static String getCountryCodes(Set<String> countryNames) {
    final codes = countryNames
        .map((name) => countryCodeMap[name])
        .where((code) => code != null)
        .toList();
    return codes.join(',');
  }

  static String? getCountryName(String code) {
    return countryCodeMap.entries
        .firstWhere(
          (entry) => entry.value == code,
          orElse: () => const MapEntry('', ''),
        )
        .key;
  }
}
