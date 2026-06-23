import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../models/access_control_models.dart';

/// Client API gouvernance  -  prêt pour brancher le provider (mock en fallback).
class AccessControlApiService {
  final Dio _dio;

  AccessControlApiService(ApiClient client) : _dio = client.dio;

  Future<Map<String, dynamic>> fetchOrganization(String scenario) async {
    final response = await _dio.get('/access-control/organization', queryParameters: {'scenario': scenario});
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<dynamic>> fetchMembers(String scenario) async {
    final response = await _dio.get('/access-control/members', queryParameters: {'scenario': scenario});
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> reparentNode({
    required String scenario,
    required String nodeId,
    String? parentId,
    OrgHierarchyLinkType? linkType,
  }) async {
    final response = await _dio.patch(
      '/access-control/organization/nodes/$nodeId/reparent',
      queryParameters: {'scenario': scenario},
      data: {
        'parent_id': parentId,
        if (linkType != null) 'hierarchy_link_type': linkType.name,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> updateOrganization(String scenario, List<OrgNode> nodes) async {
    await _dio.put(
      '/access-control/organization',
      data: {
        'scenario': scenario,
        'nodes': nodes
            .map(
              (n) => {
                'id': n.id,
                'label': n.label,
                'subtitle': n.subtitle,
                'role_id': n.roleId,
                'parent_id': n.parentId,
                'avatar_initials': n.avatarInitials,
                'member_id': n.memberId,
                'sort_order': n.sortOrder,
                'hierarchy_link_type': n.hierarchyLinkType.name,
              },
            )
            .toList(),
      },
    );
  }
}
