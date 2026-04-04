import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/products/product_service.dart';

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

  ProductUploadJob copyWith({
    ProductUploadJobStatus? status,
    double? progress,
    String? message,
  }) {
    return ProductUploadJob(
      id: id,
      product: product,
      images: images,
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
}

class ProductUploadJobServiceImpl extends ChangeNotifier
    implements ProductUploadJobService {
  final ProductService productService;
  final StreamController<ProductUploadJobEvent> _eventsController =
      StreamController<ProductUploadJobEvent>.broadcast();
  final List<ProductUploadJob> _jobs = [];
  bool _isProcessing = false;
  int _counter = 0;

  ProductUploadJobServiceImpl(this.productService);

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
    final job = ProductUploadJob(
      id: 'product-job-${_counter++}',
      product: product,
      images: images,
      language: language,
      region: region,
      actionLabel: actionLabel,
      createdAt: DateTime.now(),
      status: ProductUploadJobStatus.queued,
      progress: 0,
      message: 'Queued',
    );
    _jobs.add(job);
    notifyListeners();
    unawaited(_processQueue());
  }

  Future<void> _processQueue() async {
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
            _updateJob(
              nextJob.id,
              _findJob(nextJob.id).copyWith(
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
        _eventsController.add(ProductUploadJobEvent(_findJob(nextJob.id)));
      } catch (e) {
        _updateJob(
          nextJob.id,
          _findJob(nextJob.id).copyWith(
            status: ProductUploadJobStatus.failed,
            message: e.toString(),
          ),
        );
        _eventsController.add(ProductUploadJobEvent(_findJob(nextJob.id)));
      }
    }

    _isProcessing = false;
  }

  ProductUploadJob _findJob(String id) =>
      _jobs.firstWhere((job) => job.id == id);

  void _updateJob(String id, ProductUploadJob updatedJob) {
    final index = _jobs.indexWhere((job) => job.id == id);
    if (index == -1) {
      return;
    }
    _jobs[index] = updatedJob;
    notifyListeners();
  }
}
