import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'auth_storage.dart';

class ActivityService {
  ActivityService._();

  static Future<bool> recordWatch({
    required int contentId,
    int? episodeId,
  }) async {
    try {
      final customerIdString = await AuthStorage.getUserId();

      if (customerIdString == null || customerIdString.isEmpty) {
        debugPrint('Watch activity: customer ID not found');
        return false;
      }

      final customerId = int.tryParse(customerIdString);

      if (customerId == null) {
        debugPrint('Watch activity: invalid customer ID');
        return false;
      }

      final body = <String, dynamic>{
        'CustomerID': customerId,
        'ContentID': contentId,
      };

      if (episodeId != null) {
        body['EpisodeID'] = episodeId;
      }

      final response = await ApiService.post('/api/v1/app/activities', body);

      debugPrint(
        'Watch activity response: '
        '${response.statusCode}',
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Watch activity error: $e');

      return false;
    }
  }
}
