import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/products/product_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

enum ProductUploadJobStatus {
  queued,
  uploading,
  processing,
  completed,
  failed,
}

class ProductUploadJob {
  final String id;
  final Product product;
  final Map<String, File> images;
  final String language;
  final String region;
  final String actionLabel;
  final DateTime createdAt;
  final ProductUploadJobStatus status;
  final double progress;
  final String? message;

  const ProductUploadJob({
    required this.id,
    required this.product,
    required this.images,
    required this.language,
    required this.region,
    required this.actionLabel,
    required this.createdAt,
    required this.status,
    required this.progress,
    this.message,
  });

  bool get canRetry => status == ProductUploadJobStatus.failed;

  bool get canDelete =>
      status == ProductUploadJobStatus.completed ||
      status == ProductUploadJobStatus.failed;

  ProductUploadJob copyWith({
    Map<String, File>? images,
    ProductUploadJobStatus? status,
    double? progress,
    String? message,
  }) {
    return ProductUploadJob(
      id: id,
      product: product,
      images: images ?? this.images,
      language: language,
      region: region,
      actionLabel: actionLabel,
      createdAt: createdAt,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      message: message ?? this.message,
    );
  }
}

class ProductUploadJobEvent {
  final ProductUploadJob job;

  const ProductUploadJobEvent(this.job);
}

abstract class ProductUploadJobService implements Listenable {
  List<ProductUploadJob> get jobs;

  Stream<ProductUploadJobEvent> get events;

  Future<void> enqueueUpsert({
    required Product product,
    required Map<String, File> images,
    required String language,
    required String region,
    required String actionLabel,
  });

  Future<void> updateJob({
    required String jobId,
    required Product product,
    required Map<String, File> images,
    required String language,
    required String region,
    String? actionLabel,
    bool queueForRetry = false,
  });

  Future<void> retryJob(String jobId);

  Future<void> deleteJob(String jobId);
}

class ProductUploadJobServiceImpl extends ChangeNotifier
    implements ProductUploadJobService {
  static const _storageKey = 'product_upload_jobs';
  static const _storageDirectoryName = 'product-upload-jobs';
  static const _maxJobs = 20;

  final ProductService productService;
  final FlutterSecureStorage storage;
  final Future<Directory> Function() _directoryProvider;
  final StreamController<ProductUploadJobEvent> _eventsController =
      StreamController<ProductUploadJobEvent>.broadcast();
  final List<ProductUploadJob> _jobs = [];
  final Uuid _uuid = const Uuid();
  late final Future<void> _ready = _restoreJobs();
  bool _isProcessing = false;

  ProductUploadJobServiceImpl(
    this.productService,
    this.storage, {
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  @override
  List<ProductUploadJob> get jobs => List.unmodifiable(_jobs.reversed);

  @override
  Stream<ProductUploadJobEvent> get events => _eventsController.stream;

  @override
  Future<void> enqueueUpsert({
    required Product product,
    required Map<String, File> images,
    required String language,
    required String region,
    required String actionLabel,
  }) async {
    await _ready;

    final persistedImages = await _copyImagesToStableStorage(images);
    final job = ProductUploadJob(
      id: _uuid.v4(),
      product: product,
      images: persistedImages,
      language: language,
      region: region,
      actionLabel: actionLabel,
      createdAt: DateTime.now(),
      status: ProductUploadJobStatus.queued,
      progress: 0,
      message: 'Queued',
    );

    _jobs.add(job);
    await _trimJobs();
    await _persistJobs();
    notifyListeners();
    unawaited(_processQueue());
  }

  @override
  Future<void> updateJob({
    required String jobId,
    required Product product,
    required Map<String, File> images,
    required String language,
    required String region,
    String? actionLabel,
    bool queueForRetry = false,
  }) async {
    await _ready;
    final existingJob = _findJob(jobId);
    final persistedImages = await _copyImagesToStableStorage(images);
    await _deleteImageFiles(existingJob.images.values);

    _updateJob(
      jobId,
      ProductUploadJob(
        id: existingJob.id,
        product: product,
        images: persistedImages,
        language: language,
        region: region,
        actionLabel: actionLabel ?? existingJob.actionLabel,
        createdAt: existingJob.createdAt,
        status:
            queueForRetry ? ProductUploadJobStatus.queued : existingJob.status,
        progress: 0,
        message: queueForRetry ? 'Queued for retry' : existingJob.message,
      ),
    );

    if (queueForRetry) {
      unawaited(_processQueue());
    }
  }

  @override
  Future<void> retryJob(String jobId) async {
    await _ready;
    final job = _findJob(jobId);
    if (!job.canRetry) {
      return;
    }

    MapEntry<String, File>? missingImage;
    for (final entry in job.images.entries) {
      if (!entry.value.existsSync()) {
        missingImage = entry;
        break;
      }
    }
    if (missingImage != null) {
      _updateJob(
        jobId,
        job.copyWith(
          message:
              'Saved image for ${missingImage.key} is no longer available.',
        ),
      );
      return;
    }

    _updateJob(
      jobId,
      job.copyWith(
        status: ProductUploadJobStatus.queued,
        progress: 0,
        message: 'Queued for retry',
      ),
    );
    unawaited(_processQueue());
  }

  @override
  Future<void> deleteJob(String jobId) async {
    await _ready;
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) {
      return;
    }

    final job = _jobs.removeAt(index);
    await _deleteImageFiles(job.images.values);
    await _persistJobs();
    notifyListeners();
  }

  Future<void> _restoreJobs() async {
    try {
      final rawJobs = await storage.read(key: _storageKey);
      if (rawJobs == null || rawJobs.isEmpty) {
        return;
      }

      final decoded = jsonDecode(rawJobs);
      if (decoded is! List) {
        return;
      }

      _jobs
        ..clear()
        ..addAll(
          decoded
              .whereType<Map>()
              .map((job) => _jobFromJson(job.cast<String, dynamic>()))
              .map(_normalizeRestoredJob),
        );
      notifyListeners();
      unawaited(_processQueue());
    } catch (_) {
      await storage.delete(key: _storageKey);
    }
  }

  ProductUploadJob _normalizeRestoredJob(ProductUploadJob job) {
    if (job.status == ProductUploadJobStatus.uploading ||
        job.status == ProductUploadJobStatus.processing) {
      return job.copyWith(
        status: ProductUploadJobStatus.failed,
        progress: 0,
        message: 'Interrupted before completion. Retry to continue.',
      );
    }
    return job;
  }

  Future<Map<String, File>> _copyImagesToStableStorage(
    Map<String, File> images,
  ) async {
    if (images.isEmpty) {
      return const {};
    }

    final directory = await _jobsDirectory();
    final copiedImages = <String, File>{};
    for (final entry in images.entries) {
      final extension = _extensionFor(entry.value.path);
      final targetPath =
          '${directory.path}/${_uuid.v4()}-${entry.key}$extension';
      copiedImages[entry.key] = await entry.value.copy(targetPath);
    }
    return copiedImages;
  }

  Future<Directory> _jobsDirectory() async {
    final baseDirectory = await _directoryProvider();
    final directory = Directory('${baseDirectory.path}/$_storageDirectoryName');
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  String _extensionFor(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1) {
      return '';
    }
    return path.substring(dotIndex);
  }

  Future<void> _processQueue() async {
    await _ready;
    if (_isProcessing) {
      return;
    }
    _isProcessing = true;

    while (true) {
      final nextIndex = _jobs.indexWhere(
        (job) => job.status == ProductUploadJobStatus.queued,
      );
      if (nextIndex == -1) {
        break;
      }

      final nextJob = _jobs[nextIndex];
      _updateJob(
        nextJob.id,
        nextJob.copyWith(
          status: ProductUploadJobStatus.uploading,
          progress: 0,
          message: 'Uploading to Inoventory',
        ),
      );

      try {
        await productService.upsertToOpenFoodFacts(
          nextJob.product,
          nextJob.images,
          language: nextJob.language,
          region: nextJob.region,
          onSendProgress: (sent, total) {
            final progress = total <= 0 ? 0.0 : sent / total;
            final current = _tryFindJob(nextJob.id);
            if (current == null) {
              return;
            }
            _updateJob(
              nextJob.id,
              current.copyWith(
                status: ProductUploadJobStatus.uploading,
                progress: progress.clamp(0.0, 1.0),
                message: 'Uploading to Inoventory',
              ),
            );
          },
        );

        _updateJob(
          nextJob.id,
          _findJob(nextJob.id).copyWith(
            status: ProductUploadJobStatus.processing,
            progress: 1,
            message: 'Processing in backend and Open Food Facts',
          ),
        );

        _updateJob(
          nextJob.id,
          _findJob(nextJob.id).copyWith(
            status: ProductUploadJobStatus.completed,
            progress: 1,
            message: '${nextJob.actionLabel} completed',
          ),
        );
        await _discardJobImages(nextJob.id);
        _eventsController.add(ProductUploadJobEvent(_findJob(nextJob.id)));
      } catch (e) {
        _updateJob(
          nextJob.id,
          _findJob(nextJob.id).copyWith(
            status: ProductUploadJobStatus.failed,
            progress: 0,
            message: _formatErrorMessage(e),
          ),
        );
        _eventsController.add(ProductUploadJobEvent(_findJob(nextJob.id)));
      }
    }

    _isProcessing = false;
  }

  Future<void> _discardJobImages(String jobId) async {
    final job = _tryFindJob(jobId);
    if (job == null || job.images.isEmpty) {
      return;
    }

    await _deleteImageFiles(job.images.values);
    _updateJob(jobId, job.copyWith(images: const {}));
  }

  Future<void> _deleteImageFiles(Iterable<File> files) async {
    for (final file in files) {
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> _trimJobs() async {
    while (_jobs.length > _maxJobs) {
      final removedJob = _jobs.removeAt(0);
      await _deleteImageFiles(removedJob.images.values);
    }
  }

  ProductUploadJob _findJob(String id) =>
      _jobs.firstWhere((job) => job.id == id);

  ProductUploadJob? _tryFindJob(String id) {
    final index = _jobs.indexWhere((job) => job.id == id);
    if (index == -1) {
      return null;
    }
    return _jobs[index];
  }

  void _updateJob(String id, ProductUploadJob updatedJob) {
    final index = _jobs.indexWhere((job) => job.id == id);
    if (index == -1) {
      return;
    }
    _jobs[index] = updatedJob;
    unawaited(_persistJobs());
    notifyListeners();
  }

  Future<void> _persistJobs() async {
    await storage.write(
      key: _storageKey,
      value: jsonEncode(_jobs.map(_jobToJson).toList()),
    );
  }

  Map<String, dynamic> _jobToJson(ProductUploadJob job) {
    return {
      'id': job.id,
      'product': _productToJson(job.product),
      'images': {
        for (final entry in job.images.entries) entry.key: entry.value.path,
      },
      'language': job.language,
      'region': job.region,
      'actionLabel': job.actionLabel,
      'createdAt': job.createdAt.toIso8601String(),
      'status': job.status.name,
      'progress': job.progress,
      'message': job.message,
    };
  }

  ProductUploadJob _jobFromJson(Map<String, dynamic> json) {
    return ProductUploadJob(
      id: json['id'] as String,
      product:
          _productFromJson((json['product'] as Map).cast<String, dynamic>()),
      images: ((json['images'] as Map?) ?? const {})
          .cast<String, dynamic>()
          .map((key, value) => MapEntry(key, File(value as String))),
      language: json['language'] as String,
      region: json['region'] as String,
      actionLabel: json['actionLabel'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: ProductUploadJobStatus.values.byName(json['status'] as String),
      progress: (json['progress'] as num).toDouble(),
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> _productToJson(Product product) {
    return {
      'id': product.id,
      'name': product.name,
      'ean': product.ean,
      'brands': product.brands,
      'weight': product.weight,
      'tags': product.tags,
      'source': product.source,
      'imageUrl': product.imageUrl,
      'thumbUrl': product.thumbUrl,
    };
  }

  Product _productFromJson(Map<String, dynamic> json) {
    return Product(
      json['id'] as String,
      json['name'] as String,
      ean: json['ean'] as String,
      brands: json['brands'] as String?,
      weight: json['weight'] as String?,
      tags: (json['tags'] as List?)?.cast<String>(),
      source: json['source'] as String?,
      imageUrl: json['imageUrl'] as String?,
      thumbUrl: json['thumbUrl'] as String?,
    );
  }

  String _formatErrorMessage(Object error) {
    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    if (raw.startsWith('DioException [') && raw.contains(']: ')) {
      return raw.split(']: ').last.trim();
    }
    return raw;
  }
}
