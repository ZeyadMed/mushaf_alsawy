import 'package:get_it/get_it.dart';
import 'package:mushaf_alsawy/core/service_locator/shared_service_locator/shared_service_locator.dart';

final GetIt getIt = GetIt.instance;

abstract interface class DI {
  static Future<void> getItInit() async {
    // final cacheHelper = CacheHelper;
    // await CacheHelper.init();
    await SharedServiceLocator.execute(getIt: getIt);
  }

  static Future<void> resetGetItAndInit() async {
    // Reset all registrations and singletons, disposing instances where possible
    await getIt.reset(dispose: true);
    // Re-run initialization sequence
    await getItInit();
  }
}
