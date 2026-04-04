import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/settings/off_settings_service.dart';

class OffSettingsRoute extends StatefulWidget {
  const OffSettingsRoute({super.key});

  @override
  State<OffSettingsRoute> createState() => _OffSettingsRouteState();
}

class _OffSettingsRouteState extends State<OffSettingsRoute> {
  final OffSettingsService _settingsService = getIt<OffSettingsService>();

  static const _regions = <DropdownMenuItem<String>>[
    DropdownMenuItem(value: 'world', child: Text('World')),
    DropdownMenuItem(value: 'de', child: Text('Germany')),
    DropdownMenuItem(value: 'us', child: Text('United States')),
    DropdownMenuItem(value: 'fr', child: Text('France')),
    DropdownMenuItem(value: 'be', child: Text('Belgium')),
  ];

  static const _languages = <DropdownMenuItem<String>>[
    DropdownMenuItem(value: 'en', child: Text('English')),
    DropdownMenuItem(value: 'de', child: Text('German')),
    DropdownMenuItem(value: 'fr', child: Text('French')),
    DropdownMenuItem(value: 'nl', child: Text('Dutch')),
  ];

  String _region = OffSettingsService.defaultRegion;
  String _language = OffSettingsService.defaultLanguage;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadContributionSettings();
    if (!mounted) return;
    setState(() {
      _region = settings.region;
      _language = settings.language;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    await _settingsService.saveContributionSettings(
      region: _region,
      language: _language,
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Open Food Facts settings saved',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open Food Facts Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Contribution Region',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _region,
                  items: _regions,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _region = value;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Contribution Language',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _language,
                  items: _languages,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _language = value;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveSettings,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
    );
  }
}
