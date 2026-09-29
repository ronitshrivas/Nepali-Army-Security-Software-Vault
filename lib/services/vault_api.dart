import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/auth.dart';
import '../models/alert.dart';
import '../models/device.dart';
import '../models/device_detail.dart';
import '../models/officer.dart';
import '../models/audit.dart';
import '../models/reports.dart';
import '../models/user.dart';
import '../models/policy.dart';
import 'api_client.dart';

/// All backend calls, mapped to typed models. Mirrors the Vault.Api controllers
/// exactly (routes verified against the backend source).
class VaultApi {
  final ApiClient _c;
  VaultApi(this._c);

  Dio get _dio => _c.raw;

  // Auth -------------------------------------------------------------------

  Future<LoginResult> login(String username, String password,
      {String? totpCode}) async {
    final resp = await _c.post('/auth/login', data: {
      'username': username,
      'password': password,
      if (totpCode != null && totpCode.isNotEmpty) 'totpCode': totpCode,
    });
    final code = resp.statusCode ?? 0;
    if (code == 200 && resp.data is Map) {
      return LoginResult(LoginOutcome.success,
          response: LoginResponse.fromJson(resp.data as Map<String, dynamic>));
    }
    if (code == 401 &&
        resp.data is Map &&
        (resp.data as Map)['error'] == 'two_factor_required') {
      return LoginResult(LoginOutcome.twoFactorRequired);
    }
    if (code == 423) {
      return LoginResult(LoginOutcome.locked,
          message: 'Account locked. Try again in a few minutes.');
    }
    if (code == 401) {
      return LoginResult(LoginOutcome.invalidCredentials,
          message: 'Invalid username, password, or 2FA code.');
    }
    if (code == 429) {
      return LoginResult(LoginOutcome.error,
          message: 'Too many attempts. Please wait and try again.');
    }
    return LoginResult(LoginOutcome.error, message: 'Login failed ($code).');
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _c.post('/auth/logout', data: {'refreshToken': refreshToken});
    } catch (_) {}
  }

  Future<void> changeMyPassword(String current, String next) async {
    final resp = await _c.post('/users/me/change-password',
        data: {'currentPassword': current, 'newPassword': next});
    final code = resp.statusCode ?? 0;
    if (code == 204) return;
    if (code == 400 &&
        resp.data is Map &&
        (resp.data as Map)['error'] == 'invalid_current_password') {
      throw ApiException('Current password is incorrect.', statusCode: 400);
    }
    throw ApiException('Could not change password ($code).', statusCode: code);
  }

  Future<TotpSetup> setupTotp() async {
    final resp = await _c.post('/auth/2fa/setup');
    _ok(resp.statusCode);
    return TotpSetup.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> enableTotp(String code) async {
    final resp = await _c.post('/auth/2fa/enable', data: {'code': code});
    if ((resp.statusCode ?? 0) != 204) {
      throw ApiException(_msg(resp.data, 'Invalid code.'));
    }
  }

  // Officers ---------------------------------------------------------------

  Future<PagedResult<OfficerListItem>> searchOfficers({
    String? q,
    String? unit,
    String? role,
    bool? active,
    int page = 1,
    int pageSize = 25,
  }) async {
    final resp = await _c.get('/officers', query: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (unit != null && unit.isNotEmpty) 'unit': unit,
      if (role != null && role.isNotEmpty) 'role': role,
      if (active != null) 'active': active,
      'page': page,
      'pageSize': pageSize,
    });
    _ok(resp.statusCode);
    return PagedResult.fromJson(
        resp.data as Map<String, dynamic>, OfficerListItem.fromJson);
  }

  Future<OfficerDetail> getOfficer(String id) async {
    final resp = await _c.get('/officers/$id');
    _ok(resp.statusCode);
    return OfficerDetail.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<OfficerDetail> createOfficer(Map<String, dynamic> body) async {
    final resp = await _c.post('/officers', data: body);
    if ((resp.statusCode ?? 0) == 409) {
      throw ApiException('An officer with that ID number already exists.',
          statusCode: 409);
    }
    _ok(resp.statusCode);
    return OfficerDetail.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<OfficerDetail> updateOfficer(String id, Map<String, dynamic> body) async {
    final resp = await _c.put('/officers/$id', data: body);
    if ((resp.statusCode ?? 0) == 409) {
      throw ApiException('An officer with that ID number already exists.',
          statusCode: 409);
    }
    _ok(resp.statusCode);
    return OfficerDetail.fromJson(resp.data as Map<String, dynamic>);
  }

  // Documents --------------------------------------------------------------

  Future<List<DocumentInfo>> listDocuments(String officerId) async {
    final resp = await _c.get('/officers/$officerId/documents');
    _ok(resp.statusCode);
    return (resp.data as List? ?? [])
        .map((e) => DocumentInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> uploadDocument(
      String officerId, String filePath, String fileName) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final resp = await _dio.post('/officers/$officerId/documents', data: form);
    if ((resp.statusCode ?? 0) >= 300) {
      throw ApiException(_msg(resp.data, 'Upload failed.'));
    }
  }

  Future<Uint8List> downloadDocument(String officerId, String documentId) async {
    final resp = await _dio.get<List<int>>(
      '/officers/$officerId/documents/$documentId/content',
      options: Options(responseType: ResponseType.bytes),
    );
    _ok(resp.statusCode);
    return Uint8List.fromList(resp.data ?? []);
  }

  // Devices ----------------------------------------------------------------

  Future<PagedResult<DeviceListItem>> listDevices({
    String? status,
    String? platform,
    int page = 1,
    int pageSize = 25,
  }) async {
    final resp = await _c.get('/devices', query: {
      if (status != null) 'status': status,
      if (platform != null && platform.isNotEmpty) 'platform': platform,
      'page': page,
      'pageSize': pageSize,
    });
    _ok(resp.statusCode);
    return PagedResult.fromJson(
        resp.data as Map<String, dynamic>, DeviceListItem.fromJson);
  }

  Future<DeviceDetail> getDevice(String id) async {
    final resp = await _c.get('/devices/$id');
    _ok(resp.statusCode);
    return DeviceDetail.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<EnrollDeviceResponse> enrollDevice(Map<String, dynamic> body) async {
    final resp = await _c.post('/devices', data: body);
    if ((resp.statusCode ?? 0) == 404) {
      throw ApiException('Owner officer not found.', statusCode: 404);
    }
    _ok(resp.statusCode);
    return EnrollDeviceResponse.fromJson(resp.data as Map<String, dynamic>);
  }

  // Theft ------------------------------------------------------------------

  Future<void> markDeviceLost(String deviceId, {String? note}) async {
    final resp = await _c.post('/theft/devices/$deviceId/mark-lost',
        data: {'note': note});
    if ((resp.statusCode ?? 0) >= 300) {
      throw ApiException(_msg(resp.data, 'Could not mark device lost.'));
    }
  }

  Future<DispatchCommandResponse> dispatchCommand(
      String deviceId, String type) async {
    final resp =
        await _c.post('/theft/devices/$deviceId/commands', data: {'type': type});
    if ((resp.statusCode ?? 0) >= 300) {
      throw ApiException(_msg(resp.data, 'Could not dispatch command.'));
    }
    return DispatchCommandResponse.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> confirmCommand(String commandId, String token) async {
    final resp = await _c.post('/theft/commands/$commandId/confirm',
        data: {'confirmationToken': token});
    if ((resp.statusCode ?? 0) >= 300) {
      throw ApiException(_msg(resp.data, 'Confirmation failed.'));
    }
  }

  // Reports ----------------------------------------------------------------

  Future<FleetHealthReport> getFleetHealth() async {
    final resp = await _c.get('/reports/fleet-health');
    _ok(resp.statusCode);
    return FleetHealthReport.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<List<ComplianceResult>> getComplianceStatus() async {
    final resp = await _c.get('/reports/compliance');
    _ok(resp.statusCode);
    return (resp.data as List? ?? [])
        .map((e) => ComplianceResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DeviceListItem>> getLostDevices() async {
    final resp = await _c.get('/reports/lost-devices');
    _ok(resp.statusCode);
    return (resp.data as List? ?? [])
        .map((e) => DeviceListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PagedResult<SecurityEventItem>> getDeviceThreats(String deviceId,
      {int page = 1, int pageSize = 50}) async {
    final resp = await _c.get('/reports/devices/$deviceId/threats',
        query: {'page': page, 'pageSize': pageSize});
    _ok(resp.statusCode);
    return PagedResult.fromJson(
        resp.data as Map<String, dynamic>, SecurityEventItem.fromJson);
  }

  // Audit ------------------------------------------------------------------

  Future<List<AuditEntry>> auditLog({
    int page = 1,
    int pageSize = 50,
    String? action,
    DateTime? from,
    DateTime? to,
  }) async {
    final resp = await _c.get('/audit', query: {
      'page': page,
      'pageSize': pageSize,
      if (action != null && action.isNotEmpty) 'action': action,
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    });
    _ok(resp.statusCode);
    final data = resp.data as Map<String, dynamic>;
    return (data['items'] as List? ?? [])
        .map((e) => AuditEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChainVerifyResult> verifyChain() async {
    final resp = await _c.get('/audit/verify-chain');
    _ok(resp.statusCode);
    return ChainVerifyResult.fromJson(resp.data as Map<String, dynamic>);
  }

  // Users ------------------------------------------------------------------

  Future<List<UserListItem>> listUsers() async {
    final resp = await _c.get('/users');
    _ok(resp.statusCode);
    return (resp.data as List? ?? [])
        .map((e) => UserListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createUser(String username, String password, String role) async {
    final resp = await _c.post('/users',
        data: {'username': username, 'password': password, 'role': role});
    if ((resp.statusCode ?? 0) == 409) {
      throw ApiException('Username already taken.', statusCode: 409);
    }
    if ((resp.statusCode ?? 0) >= 300) {
      throw ApiException(_msg(resp.data, 'Could not create user.'));
    }
  }

  Future<void> changeUserRole(String userId, String role) async {
    final resp = await _c.put('/users/$userId/role', data: {'role': role});
    _noContentOrThrow(resp, 'Could not change role.');
  }

  Future<void> resetUserPassword(String userId, String newPassword) async {
    final resp = await _c.post('/users/$userId/reset-password',
        data: {'newPassword': newPassword});
    _noContentOrThrow(resp, 'Could not reset password.');
  }

  Future<void> lockUser(String userId) async {
    final resp = await _c.post('/users/$userId/lock');
    _noContentOrThrow(resp, 'Could not lock user.');
  }

  Future<void> unlockUser(String userId) async {
    final resp = await _c.post('/users/$userId/unlock');
    _noContentOrThrow(resp, 'Could not unlock user.');
  }

  Future<void> revokeUserSessions(String userId) async {
    final resp = await _c.post('/users/$userId/revoke-sessions');
    _noContentOrThrow(resp, 'Could not revoke sessions.');
  }

  // Policies ---------------------------------------------------------------

  Future<List<PolicyDto>> listPolicies() async {
    final resp = await _c.get('/policies');
    _ok(resp.statusCode);
    return (resp.data as List? ?? [])
        .map((e) => PolicyDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PolicyDto> createPolicy(Map<String, dynamic> body) async {
    final resp = await _c.post('/policies', data: body);
    _ok(resp.statusCode);
    return PolicyDto.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> assignPolicy(String policyId,
      {String? deviceId, String? groupName}) async {
    final resp = await _c.post('/policies/assign', data: {
      'policyId': policyId,
      if (deviceId != null) 'deviceId': deviceId,
      if (groupName != null) 'groupName': groupName,
    });
    _noContentOrThrow(resp, 'Could not assign policy.');
  }

  // Alerts -----------------------------------------------------------------

  Future<AlertPage> listAlerts({
    String? status,
    String? type,
    int page = 1,
    int pageSize = 50,
  }) async {
    final resp = await _c.get('/alerts', query: {
      if (status != null) 'status': status,
      if (type != null) 'type': type,
      'page': page,
      'pageSize': pageSize,
    });
    _ok(resp.statusCode);
    return AlertPage.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> acknowledgeAlert(String id) async {
    final resp = await _c.post('/alerts/$id/acknowledge');
    if ((resp.statusCode ?? 0) >= 300) {
      throw ApiException(_msg(resp.data, 'Could not acknowledge alert.'));
    }
  }

  Future<void> resolveAlert(String id) async {
    final resp = await _c.post('/alerts/$id/resolve');
    if ((resp.statusCode ?? 0) >= 300) {
      throw ApiException(_msg(resp.data, 'Could not resolve alert.'));
    }
  }

  // Helpers ----------------------------------------------------------------

  void _ok(int? code) {
    if (code == null || code >= 300) {
      if (code == 403) {
        throw ApiException('Your role does not have access to this.',
            statusCode: 403);
      }
      throw ApiException('Request failed ($code).', statusCode: code);
    }
  }

  void _noContentOrThrow(Response resp, String fallback) {
    final code = resp.statusCode ?? 0;
    if (code == 204 || code == 200) return;
    if (code == 409) {
      throw ApiException(_msg(resp.data, 'Not allowed — protected account.'),
          statusCode: 409);
    }
    throw ApiException(_msg(resp.data, fallback), statusCode: code);
  }

  String _msg(dynamic data, String fallback) {
    if (data is Map && data['error'] is String) {
      return (data['error'] as String).replaceAll('_', ' ');
    }
    return fallback;
  }
}
