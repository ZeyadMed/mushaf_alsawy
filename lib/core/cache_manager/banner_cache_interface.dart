
part of "hive_service_impl.dart";

abstract class IBannerCache {
  Future<List<String>> getBannerList(String boxName);
  Future<void> cacheBannerList(List<String> items, {required String boxName});
  Future<void> clearBannerList({required String boxName});
}