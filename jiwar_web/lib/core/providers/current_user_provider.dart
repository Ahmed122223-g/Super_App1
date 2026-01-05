import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jiwar_web/core/services/api_service.dart';

final currentUserProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ApiService().getProfile();
  if (response.isSuccess && response.data != null) {
    return response.data!;
  }
  return {};
});
