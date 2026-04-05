import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const offRegionOptions = <String, String>{
  'world': 'World',
  'de': 'Germany',
  'us': 'United States',
  'fr': 'France',
  'be': 'Belgium',
};

const offLanguageOptions = <String, String>{
  'en': 'English',
  'de': 'German',
  'fr': 'French',
  'nl': 'Dutch',
};

class OffContributionSettings {
  final String region;
  final String language;

  const OffContributionSettings({
    required this.region,
    required this.language,
  });
}

abstract class OffSettingsService {
  static const defaultRegion = 'world';
  static const defaultLanguage = 'en';

  Future<OffContributionSettings> loadContributionSettings();

  Future<bool> hasContributionSettings();

  Future<void> saveContributionSettings({
    required String region,
    required String language,
  });
}

class OffSettingsServiceImpl implements OffSettingsService {
  static const _regionKey = 'off_region';
  static const _languageKey = 'off_language';

  final FlutterSecureStorage storage;

  OffSettingsServiceImpl(this.storage);

  @override
  Future<OffContributionSettings> loadContributionSettings() async {
    final region =
        await storage.read(key: _regionKey) ?? OffSettingsService.defaultRegion;
    final language = await storage.read(key: _languageKey) ??
        OffSettingsService.defaultLanguage;

    return OffContributionSettings(region: region, language: language);
  }

  @override
  Future<bool> hasContributionSettings() async {
    final region = await storage.read(key: _regionKey);
    final language = await storage.read(key: _languageKey);
    return region != null && language != null;
  }

  @override
  Future<void> saveContributionSettings({
    required String region,
    required String language,
  }) async {
    await storage.write(key: _regionKey, value: region);
    await storage.write(key: _languageKey, value: language);
  }
}
