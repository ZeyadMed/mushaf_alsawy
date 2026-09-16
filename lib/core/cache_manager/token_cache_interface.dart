part of "hive_service_impl.dart";
abstract class ITokenCache {
  Future<void> saveAccessToken(String token);
  String? getAccessToken();
  Future<void> clearAccessToken();
}
