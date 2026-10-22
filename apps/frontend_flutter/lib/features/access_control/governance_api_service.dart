import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import 'governance_models.dart';

class GovernanceApiService {
  final Dio _dio;

  GovernanceApiService(ApiClient client) : _dio = client.dio;

  Future<GovernanceWorkspace> workspace() async {
    final response = await _dio.get('/governance/workspace');
    return GovernanceWorkspace.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GovernanceWorkspace> updateWorkspace(Map<String, dynamic> body) async {
    final response = await _dio.patch('/governance/workspace', data: body);
    return GovernanceWorkspace.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GovernanceWorkspace> updateMember(String membershipId, Map<String, dynamic> body) async {
    final response = await _dio.patch('/governance/members/$membershipId', data: body);
    return GovernanceWorkspace.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GovernanceWorkspace> removeMember(String membershipId) async {
    final response = await _dio.delete('/governance/members/$membershipId');
    return GovernanceWorkspace.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<GovernancePerson>> searchPeople(String query) async {
    final response = await _dio.get('/governance/people', queryParameters: {'q': query});
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? const [];
    return [
      for (final item in items)
        if (item is Map) GovernancePerson.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  Future<GovernanceWorkspace> invite(String inviteeId) async {
    final response = await _dio.post('/governance/invitations', data: {'invitee_id': inviteeId});
    return GovernanceWorkspace.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GovernanceWorkspace> invitationAction(String invitationId, String action) async {
    final response = await _dio.post('/governance/invitations/$invitationId/$action');
    return GovernanceWorkspace.fromJson(response.data as Map<String, dynamic>);
  }
}
