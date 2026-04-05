import 'dart:io';

import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/products/product_upload_job_service.dart';
import 'package:inoventory_ui/products/widgets/add_product.dart';

class ProductUploadJobRoute extends StatelessWidget {
  final ProductUploadJob job;

  ProductUploadJobRoute({
    super.key,
    required this.job,
  });

  final ProductUploadJobService _jobService = getIt<ProductUploadJobService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Job')),
      body: AddProductView(
        barcode: job.product.ean,
        initialProduct: job.product,
        initialImages: Map<String, File>.from(job.images),
        initialLanguage: job.language,
        initialRegion: job.region,
        initialErrorMessage:
            job.status == ProductUploadJobStatus.failed ? job.message : null,
        submitButtonLabel: 'Save and Retry Job',
        successMessage: 'Job updated and queued',
        onCancelProductAddition: () {
          Navigator.of(context).pop();
        },
        onSubmitProduct: (product, images, language, region) async {
          await _jobService.updateJob(
            jobId: job.id,
            product: product,
            images: images,
            language: language,
            region: region,
            queueForRetry: true,
          );
        },
        onSuccessfulProductAddition: (_) async {
          if (!context.mounted) {
            return;
          }
          Navigator.of(context).pop(true);
        },
      ),
    );
  }
}
