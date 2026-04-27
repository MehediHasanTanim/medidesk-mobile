import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

// ── Login request / response ───────────────────────────────────────────────

@freezed
class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String username,
    required String password,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}

@freezed
class LoginUser with _$LoginUser {
  const factory LoginUser({
    required String id,
    required String username,
    @JsonKey(name: 'full_name') required String fullName,
    String? email,
    required String role,
    @JsonKey(name: 'chamber_ids') @Default([]) List<String> chamberIds,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
  }) = _LoginUser;

  factory LoginUser.fromJson(Map<String, dynamic> json) =>
      _$LoginUserFromJson(json);
}

@freezed
class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    required String access,
    required String refresh,
    required LoginUser user,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
}

// ── User profile (GET /auth/me/) ───────────────────────────────────────────

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String username,
    @JsonKey(name: 'full_name') String? fullName,
    String? email,
    String? role,
    @JsonKey(name: 'chamber_ids') @Default([]) List<String> chamberIds,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

// ── Change-password request ────────────────────────────────────────────────

@freezed
class ChangePasswordRequest with _$ChangePasswordRequest {
  const factory ChangePasswordRequest({
    @JsonKey(name: 'old_password') required String oldPassword,
    @JsonKey(name: 'new_password') required String newPassword,
  }) = _ChangePasswordRequest;

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordRequestFromJson(json);
}
