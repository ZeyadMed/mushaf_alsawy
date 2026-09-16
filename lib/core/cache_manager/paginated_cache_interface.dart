// part of 'hive_service_impl.dart';

// abstract interface class IPaginatedCache<T> {
//   Future<void> cachePage(List<T> items, {required String cacheKey});

//   Future<List<T>> getCachedPage({required String cacheKey});

//   Future<void> clearCachedPage({required String cacheKey});
// }

// class OrderForNurserPaginatedCache<OrderModel> implements IPaginatedCache<OrderModel> {
//   final HiveServiceImpl hiveService;

//   OrderForNurserPaginatedCache(this.hiveService);

//   @override
//   Future<void> cachePage(List<OrderModel> items, {required String cacheKey}) =>
//       hiveService._cachePage(items, cacheKey: 'orders_$cacheKey');

//   @override
//   Future<List<OrderModel>> getCachedPage({required String cacheKey}) =>
//       hiveService._getCachedPage(cacheKey: 'orders_$cacheKey');

//   @override
//   Future<void> clearCachedPage({required String cacheKey}) =>
//       hiveService._clearCachedPage(cacheKey: 'orders_$cacheKey');
// }

// class ShowOrdersForNurserPaginatedCache<ShowPatientOrderForNurserModel> implements IPaginatedCache<ShowPatientOrderForNurserModel> {
//   final HiveServiceImpl hiveService;

//   ShowOrdersForNurserPaginatedCache(this.hiveService);

//   @override
//   Future<void> cachePage(List<ShowPatientOrderForNurserModel> items,
//           {required String cacheKey}) =>
//       hiveService._cachePage(items, cacheKey: 'patient_orders_$cacheKey');

//   @override
//   Future<List<ShowPatientOrderForNurserModel>> getCachedPage(
//           {required String cacheKey}) =>
//       hiveService._getCachedPage(cacheKey: 'patient_orders_$cacheKey');

//   @override
//   Future<void> clearCachedPage({required String cacheKey}) =>
//       hiveService._clearCachedPage(cacheKey: 'patient_orders_$cacheKey');
// }

// class TransactionsPaginatedCache<TransactionsItem> implements IPaginatedCache<TransactionsItem> {
//   final HiveServiceImpl hiveService;

//   TransactionsPaginatedCache(this.hiveService);

//   @override
//   Future<void> cachePage(List<TransactionsItem> items, {required String cacheKey}) =>
//       hiveService._cachePage(items, cacheKey: 'transactions_$cacheKey');

//   @override
//   Future<List<TransactionsItem>> getCachedPage({required String cacheKey}) =>
//       hiveService._getCachedPage(cacheKey: 'transactions_$cacheKey');

//   @override
//   Future<void> clearCachedPage({required String cacheKey}) =>
//       hiveService._clearCachedPage(cacheKey: 'transactions_$cacheKey');
// }   


// class IncomingBooksPaginatedCache<BookModel> implements IPaginatedCache<BookModel> {
//   final HiveServiceImpl hiveService;

//   IncomingBooksPaginatedCache(this.hiveService);

//   @override
//   Future<void> cachePage(List<BookModel> items, {required String cacheKey}) =>
//       hiveService._cachePage(items, cacheKey: 'incoming_books_$cacheKey');

//   @override
//   Future<List<BookModel>> getCachedPage({required String cacheKey}) =>
//       hiveService._getCachedPage(cacheKey: 'incoming_books_$cacheKey');

//   @override
//   Future<void> clearCachedPage({required String cacheKey}) =>
//       hiveService._clearCachedPage(cacheKey: 'incoming_books_$cacheKey');
// }

// class NotificationsPaginatedCache<NotificationModel> implements IPaginatedCache<NotificationModel> {
//   final HiveServiceImpl hiveService;

//   NotificationsPaginatedCache(this.hiveService);

//   @override
//   Future<void> cachePage(List<NotificationModel> items, {required String cacheKey}) =>
//       hiveService._cachePage(items, cacheKey: 'notifications_$cacheKey');
//   @override
//   Future<List<NotificationModel>> getCachedPage({required String cacheKey}) =>
//       hiveService._getCachedPage(cacheKey: 'notifications_$cacheKey');

//   @override
//   Future<void> clearCachedPage({required String cacheKey}) =>
//       hiveService._clearCachedPage(cacheKey: 'notifications_$cacheKey');
// }

// class PatientTransactionPaginatedCache<PatientTransactionModel> implements IPaginatedCache<PatientTransactionModel> {
//   final HiveServiceImpl hiveService;

//   PatientTransactionPaginatedCache(this.hiveService);

//   @override
//   Future<void> cachePage(List<PatientTransactionModel> items, {required String cacheKey}) =>
//       hiveService._cachePage(items, cacheKey: 'patient_transactions_$cacheKey');

//   @override
//   Future<List<PatientTransactionModel>> getCachedPage({required String cacheKey}) =>
//       hiveService._getCachedPage(cacheKey: 'patient_transactions_$cacheKey');

//   @override
//   Future<void> clearCachedPage({required String cacheKey}) =>
//       hiveService._clearCachedPage(cacheKey: 'patient_transactions_$cacheKey');
// }

