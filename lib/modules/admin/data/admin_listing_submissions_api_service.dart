import '../../../models/api/admin_api_models.dart';
import '../../../services/admin/admin_api_service.dart';

/// Admin listing submissions operations via REST API.
class AdminListingSubmissionsApiService {
  AdminListingSubmissionsApiService(this._api);

  final AdminApiService _api;

  Future<List<ListingSubmission>> listAll() async {
    return _api.listSubmissions();
  }

  Future<List<ListingSubmission>> listPending() async {
    final all = await _api.listSubmissions();
    return all.where((s) {
      final status = s.approvalStatus?.toLowerCase() ?? '';
      return status.isEmpty || status == 'pending';
    }).toList();
  }

  Future<ListingSubmission> approve(String submissionId) async {
    return _api.updateSubmission(submissionId, approvalStatus: 'approved');
  }

  Future<ListingSubmission> reject(String submissionId, {String? reason}) async {
    return _api.updateSubmission(submissionId, approvalStatus: 'rejected');
  }

  Future<ListingSubmission> updateStock(String submissionId, int stock) async {
    return _api.updateSubmission(submissionId, stock: stock);
  }
}
