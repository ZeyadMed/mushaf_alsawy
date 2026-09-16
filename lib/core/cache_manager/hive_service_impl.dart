// import 'package:professional_lawyer/core/cache_manager/location_cache_interface.dart';



// // part "book_cache_interface.dart";

// part "token_cache_interface.dart";


// part "paginated_cache_interface.dart";


// part "banner_cache_interface.dart";

// class HiveServiceImpl
//     implements
//     //     IUserCache,
//     //     ITokenCache,
//         ILocationCache,
//     //     IFavouriteCache,
//         IBannerCache {
// // ---------------------- Boxes ----------------------
//   static const String userBoxName = 'user_box';
//   static const String tokenBoxName = 'token_box';
//   static const String locationBoxName = 'location_box';
//   static const String declinedBookBox = 'declined_book_box';
//   static const String completeBookBox = 'complete_book_box';
//   static const String favouriteBox = 'favourite_box';

// // ----------------------- Keys ----------------------
//   static const String currentUserKey = 'current_user';
//   static const String accessTokenKey = 'access_token';
//   static const String currentLocationKey = 'current_location';
//   static const String isCurrentLocationKey = 'is_current_location';

//   // static Box<BaseUser>? _userBox;
//   static Box<String>? _tokenBox;
//   static Box? _locationBox;

//   HiveServiceImpl._();

//   static final HiveServiceImpl instance = HiveServiceImpl._();

//   static Future<void> init() async {
//     await Hive.initFlutter();
//     // Hive.registerAdapter(PatientModelAdapter());
//     // Hive.registerAdapter(NurseModelAdapter());
//     // Hive.registerAdapter(LocationModelAdapter());
//     // Hive.registerAdapter(BookModelAdapter());
//     // Hive.registerAdapter(SearchForServiceModelAdapter());
//     // Hive.registerAdapter(TransactionsResponseAdapter());
//     // Hive.registerAdapter(TransactionItemAdapter());
//     // Hive.registerAdapter(ShowPatientOrderForNurserModelAdapter());
//     // Hive.registerAdapter(NotificationModelAdapter());
//     // Hive.registerAdapter(NotificationStatusAdapter());
//     // Hive.registerAdapter(PatientTransactionModelAdapter());
//     // Hive.registerAdapter(BannarModelAdapter());
//     // _userBox = await Hive.openBox<BaseUser>(userBoxName);
//     // _tokenBox = await Hive.openBox<String>(tokenBoxName);
//     // _locationBox = await Hive.openBox(locationBoxName);
//     // await Hive.openBox<BookModel>(declinedBookBox);
//     // await Hive.openBox<BookModel>(completeBookBox);
//     // await Hive.openBox<SearchForServiceModel>(favouriteBox);
//   }

// // ---------------------- User ----------------------
// //   @override
// //   Future<void> cacheUserModel(BaseUser user) async {
// //     await _userBox?.put(currentUserKey, user);
// //   }

// //   @override
// //   BaseUser? getCachedUserModel() {
// //     return _userBox?.get(currentUserKey);
// //   }

// //   @override
// //   Future<void> updateCachedUserModel(BaseUser user) async {
// //     final currentUser = _userBox?.get(currentUserKey);
// //     if (currentUser != null) {
// //       final updatedUser = currentUser.copyWith(
// //         id: user.id,
// //         fullName: user.fullName,
// //         email: user.email,
// //         phone: user.phone,
// //         image: user.image,
// //         codeCountry: user.codeCountry,
// //       );
// //       await _userBox?.put(currentUserKey, updatedUser);
// //     } else {
// //       await _userBox?.put(currentUserKey, user);
// //     }
// //   }

// //   @override
// //   Future<void> clearUserModel() async {
// //     await _userBox?.delete(currentUserKey);
// //   }

// // // ---------------------- Token ----------------------
// //   @override
// //   Future<void> saveAccessToken(String token) async {
// //     await _tokenBox?.put(accessTokenKey, token);
// //   }

// //   @override
// //   String? getAccessToken() {
// //     return _tokenBox?.get(accessTokenKey);
// //   }

// //   @override
// //   Future<void> clearAccessToken() async {
// //     await _tokenBox?.delete(accessTokenKey);
// //   }

// // ---------------------- Location ----------------------
//   @override
//   Future<void> cacheCurrentLocation(LocationModel location) async {
//     await _locationBox?.put(currentLocationKey, location);
//   }

//   @override
//   LocationModel? getCachedCurrentLocation() {
//     return _locationBox?.get(currentLocationKey) as LocationModel?;
//   }

//   @override
//   Future<void> clearCachedCurrentLocation() async {
//     await _locationBox?.delete(currentLocationKey);
//   }

//   @override
//   Future<bool> hasCachedCurrentLocation() async {
//     final location = _locationBox?.get(currentLocationKey) as LocationModel?;
//     return location != null;
//   }

//   @override
//   Future<void> cacheCurrentLocationIfNotNull(LocationModel? location) async {
//     if (location != null) {
//       await cacheCurrentLocation(location);
//     }
//   }

//   @override
//   Future<void> setIsCurrentLocation(bool value) async {
//     await _locationBox?.put(isCurrentLocationKey, value);
//   }

//   @override
//   bool getIsCurrentLocation() {
//     final val = _locationBox?.get(isCurrentLocationKey) as bool?;
//     return val ?? true;
//   }

// // ------------------- Books ---------------------
//   /*@override
//   Future<void> putBookList(String boxName, List<BookModel> books) async {
//     final box = await openBox<BookModel>(boxName);
//     for (var book in books) {
//       await box.put(book.id, book);
//     }
//   }

//   @override
//   Future<List<BookModel>> getBookList(String boxName) async {
//     final box = await openBox<BookModel>(boxName);
//     return box.values.toList();
//   }

//   @override
//   List<BookModel> getAllBooks(String boxName) {
//     final box = Hive.box<BookModel>(boxName);
//     return box.values.whereType<BookModel>().toList();
//   }*/

// // ------------------- Favourites ---------------------
//   // @override
//   // Future<void> addFavourite(SearchForServiceModel bookModel) async {
//   //   final box = await openBox<SearchForServiceModel>(favouriteBox);
//   //   await box.put(bookModel.id, bookModel);
//   // }

//   // @override
//   // Future<List<SearchForServiceModel>> getFavourites() async {
//   //   final box = await openBox<SearchForServiceModel>(favouriteBox);
//   //   return box.values.toList();
//   // }

//   // @override
//   // Future<void> removeFavourite(int id) async {
//   //   final box = await openBox<SearchForServiceModel>(favouriteBox);
//   //   await box.delete(id);
//   // }
//   // // ------------------ Banners ---------------------

//   // @override
//   // Future<void> cacheBannerList(List<BannarModel> items,
//   //     {required String boxName}) async {
//   //   final box = await Hive.openBox<BannarModel>(boxName);
//   //   await box.putAll(items.asMap());
//   // }

//   // @override
//   // Future<void> clearBannerList({required String boxName}) async {
//   //   final box = await Hive.openBox<BannarModel>(boxName);
//   //   await box.clear();
//   // }

//   // @override
//   // Future<List<BannarModel>> getBannerList(String boxName) async {
//   //   final box = Hive.box<BannarModel>(boxName);
//   //   return box.values.toList();
//   // }

// // ------------------- Paginated Cache ---------------------
//   Future<void> _cachePage<T>(List<T> items, {required String cacheKey}) async {
//     final box = await Hive.openBox<T>(cacheKey);
//     await box.putAll(items.asMap());
//   }

// // Generic retrieval method
//   Future<List<T>> _getCachedPage<T>({required String cacheKey}) async {
//     final box = await Hive.openBox<T>(cacheKey);
//     return box.values.toList();
//   }

// // Generic clear method
//   Future<void> _clearCachedPage<T>({required String cacheKey}) async {
//     final box = await Hive.openBox<T>(cacheKey);
//     await box.clear();
//   }

// // ------------------ Generic ---------------------
//   static Future<Box<E>> openBox<E>(String boxName) async {
//     if (Hive.isBoxOpen(boxName)) return Hive.box<E>(boxName);
//     return await Hive.openBox<E>(boxName);
//   }

//   static Future<void> put<E>(String boxName, dynamic key, E value) async {
//     final box = await openBox<E>(boxName);
//     await box.put(key, value);
//   }

//   static Future<E?> get<E>(String boxName, dynamic key) async {
//     final box = await openBox<E>(boxName);
//     return box.get(key);
//   }

//   static Future<void> delete<E>(String boxName, dynamic key) async {
//     final box = await openBox<E>(boxName);
//     await box.delete(key);
//   }

//   static Future<void> clearBox<E>(String boxName) async {
//     final box = await openBox<E>(boxName);
//     await box.clear();
//   }

//   static Future<void> closeBox<E>(String boxName) async {
//     final box = Hive.box<E>(boxName);
//     await box.close();
//   }

//   Future<void> clearAll() async {
//     // await _userBox?.clear();
//     await _tokenBox?.clear();
//     await _locationBox?.clear();
//     await Hive.close();
//     // await Hive.box<BookModel>(declinedBookBox).clear();
//     // await Hive.box<BookModel>(completeBookBox).clear();
//   }
  
//   @override
//   Future<void> cacheBannerList(List<String> items, {required String boxName}) {
//     // TODO: implement cacheBannerList
//     throw UnimplementedError();
//   }
  
//   @override
//   Future<void> clearBannerList({required String boxName}) {
//     // TODO: implement clearBannerList
//     throw UnimplementedError();
//   }
  
//   @override
//   Future<List<String>> getBannerList(String boxName) {
//     // TODO: implement getBannerList
//     throw UnimplementedError();
//   }
// }
