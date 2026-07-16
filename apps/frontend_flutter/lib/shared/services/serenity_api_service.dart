import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../models/serenity_briefing_model.dart';

class SerenityApiService {
  final Dio _dio;

  SerenityApiService(ApiClient client) : _dio = client.dio;

  Future<SerenityBriefing> fetchBriefing() async {
    final response = await _dio.get('/dashboard/serenity-briefing');
    return SerenityBriefing.fromJson(response.data as Map<String, dynamic>);
  }
}
