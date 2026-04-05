import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/products/routes/product_upload_job_route.dart';
import 'package:inoventory_ui/products/product_upload_job_service.dart';
import 'package:inoventory_ui/settings/off_settings_route.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InoDrawer extends StatefulWidget {
  final Future<void> Function() logout;

  const InoDrawer({Key? key, required this.logout}) : super(key: key);

  @override
  State<InoDrawer> createState() => _InoDrawerState();
}

class _InoDrawerState extends State<InoDrawer> {
  bool forceFetchProducts = Globals.forceFetchProducts;
  final ProductUploadJobService _jobService = getIt<ProductUploadJobService>();
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _firstName {
    final user = _supabase.auth.currentUser;
    final metadata = user?.userMetadata ?? const {};
    final rawName = [
      metadata['first_name'],
      metadata['given_name'],
      metadata['username'],
      metadata['full_name'],
      metadata['name'],
      user?.email,
    ].whereType<String>().firstWhere(
          (value) => value.trim().isNotEmpty,
          orElse: () => 'there',
        );

    final normalized = rawName.trim();
    if (normalized.contains('@')) {
      return normalized.split('@').first;
    }
    return normalized.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Drawer(
        backgroundColor: colorScheme.surface,
        child: ListView(padding: EdgeInsets.zero, children: [
          Container(
            height: 188,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              gradient: LinearGradient(
                colors: [
                  colorScheme.surfaceContainerHighest,
                  colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withOpacity(0.75),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Hello, $_firstName',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _supabase.auth.currentUser?.email ?? 'Signed in',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer
                                  .withOpacity(0.75),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            title: Row(children: [
              const Text('Force fetch: '),
              Checkbox(
                  value: forceFetchProducts,
                  onChanged: (bool? value) {
                    Globals.forceFetchProducts = value!;
                    setState(() {
                      forceFetchProducts = value;
                    });
                  }),
            ]),
          ),
          ListTile(
            title: const Text('Open Food Facts Settings'),
            onTap: () async {
              final navigator = Navigator.of(context);
              await navigator.push(
                MaterialPageRoute(
                  builder: (context) => const OffSettingsRoute(),
                ),
              );
              if (!mounted) {
                return;
              }
              navigator.pop();
            },
          ),
          AnimatedBuilder(
            animation: _jobService,
            builder: (context, _) {
              final jobs = _jobService.jobs.take(5).toList();
              if (jobs.isEmpty) {
                return const SizedBox.shrink();
              }

              return ExpansionTile(
                initiallyExpanded: true,
                title: Text('Product Upload Jobs (${jobs.length})'),
                children: jobs
                    .map(
                      (job) => ListTile(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductUploadJobRoute(job: job),
                            ),
                          );
                        },
                        dense: true,
                        title: Text('${job.actionLabel}: ${job.product.ean}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job.message ?? job.status.name),
                            if (job.status ==
                                    ProductUploadJobStatus.uploading ||
                                job.status == ProductUploadJobStatus.processing)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: LinearProgressIndicator(
                                  value: job.status ==
                                          ProductUploadJobStatus.processing
                                      ? null
                                      : job.progress,
                                ),
                              ),
                            if (job.canRetry || job.canDelete)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Wrap(
                                  spacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProductUploadJobRoute(job: job),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.visibility,
                                          size: 18),
                                      label: const Text('View'),
                                    ),
                                    if (job.canRetry)
                                      OutlinedButton.icon(
                                        onPressed: () =>
                                            _jobService.retryJob(job.id),
                                        icon:
                                            const Icon(Icons.refresh, size: 18),
                                        label: const Text('Retry'),
                                      ),
                                    if (job.canDelete)
                                      TextButton.icon(
                                        onPressed: () =>
                                            _jobService.deleteJob(job.id),
                                        icon: const Icon(Icons.close, size: 18),
                                        label: const Text('Dismiss'),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        trailing: Text(job.status.name),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          ExpansionTile(
            title: const Text('Developer'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              _DebugInfoRow(
                label: 'Backend URL',
                value: Constants.inoventoryBackendUrl,
              ),
              _DebugInfoRow(
                label: 'App Version',
                value: Constants.version,
              ),
              _DebugInfoRow(
                label: 'Build Mode',
                value: kReleaseMode ? 'release' : 'debug',
              ),
              _DebugInfoRow(
                label: 'Platform',
                value: defaultTargetPlatform.name,
              ),
              _DebugInfoRow(
                label: 'Force Fetch',
                value: forceFetchProducts ? 'enabled' : 'disabled',
              ),
              _DebugInfoRow(
                label: 'User ID',
                value: _supabase.auth.currentUser?.id ?? 'not logged in',
              ),
            ],
          ),
          ListTile(
            title: const Text('Logout'),
            onTap: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              await widget.logout();
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Successfully logged out",
                      style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.green));
            },
          )
        ]));
  }
}

class _DebugInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DebugInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
