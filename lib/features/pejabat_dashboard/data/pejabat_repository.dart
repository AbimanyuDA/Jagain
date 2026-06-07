import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/storage/minio_storage_service.dart';
import '../../auth/domain/user_model.dart';
import '../../feed/data/report_repository.dart';
import '../../feed/domain/models/report_post.dart';

class PejabatRepository {
  PejabatRepository({
    FirebaseFirestore? firestore,
    MinioStorageService? storage,
    ReportRepository? reportRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? MinioStorageService.instance,
       _reportRepository = reportRepository ?? ReportRepository();

  final FirebaseFirestore _firestore;
  final MinioStorageService _storage;
  final ReportRepository _reportRepository;

  Stream<List<ReportPost>> watchRegionalReports(
    String wilayah, {
    String? currentUserId,
  }) {
    return _reportRepository.watchReportsByWilayah(
      wilayah,
      currentUserId: currentUserId,
    );
  }

  Future<void> updateReportStatus({
    required String reportId,
    required ReportPostStatus status,
    required String note,
    File? proofImage,
    required UserModel official,
  }) async {
    String? proofImageUrl;
    if (proofImage != null) {
      proofImageUrl = await _storage.uploadImage(
        file: proofImage,
        folder: MinioFolder.statusProofs,
        ownerId: reportId,
      );
    }

    final reportRef = _firestore.collection('reports').doc(reportId);
    final updateRef = reportRef.collection('statusUpdates').doc();
    final now = Timestamp.now();

    final batch = _firestore.batch();
    batch.set(updateRef, {
      'status': status.key,
      'note': note,
      'proofImageUrl': proofImageUrl,
      'officialId': official.uid,
      'officialName': official.name,
      'createdAt': now,
    });
    batch.update(reportRef, {
      'status': status.key,
      'updatedAt': now,
      'statusUpdateCount': FieldValue.increment(1),
    });

    await batch.commit();
  }
}
