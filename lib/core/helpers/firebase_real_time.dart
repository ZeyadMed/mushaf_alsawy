// import 'package:firebase_database/firebase_database.dart';

// class FirebaseRealtimeService {
//   FirebaseRealtimeService({
//     required this.dbRef,
//   });
//   final DatabaseReference dbRef;

//   Stream<Map<String, dynamic>?> listenToLatestSnapshot({
//     required String path,
//     required String orderByField,
//     required dynamic equalToValue,
//   }) {
//     return dbRef
//         .child(path)
//         .orderByChild(orderByField)
//         .equalTo(equalToValue)
//         .limitToLast(1)
//         .onChildAdded
//         .map((event) {
//       final value = event.snapshot.value;
//       if (value is Map) {
//         return Map<String, dynamic>.from(value);
//       }
//       return null;
//     });
//   }

//   Stream<String?> listenToDeletedKeys({
//     required String path,
//     String? orderByField,
//     dynamic equalToValue,
//   }) {
//     Query query = dbRef.child(path);

//     if (orderByField != null && equalToValue != null) {
//       query = query.orderByChild(orderByField).equalTo(equalToValue);
//     }

//     return query.onChildRemoved.map((event) => event.snapshot.key);
//   }

//   // New: return the removed child's data so callers can match by ids reliably
//   Stream<Map<String, dynamic>?> listenToDeletedData({
//     required String path,
//     String? orderByField,
//     dynamic equalToValue,
//   }) {
//     Query query = dbRef.child(path);
//     if (orderByField != null && equalToValue != null) {
//       query = query.orderByChild(orderByField).equalTo(equalToValue);
//     }
//     return query.onChildRemoved.map((event) {
//       final value = event.snapshot.value;
//       if (value is Map) {
//         return Map<String, dynamic>.from(value);
//       }
//       return null;
//     });
//   }

//   // New: Unfiltered deleted-data stream to avoid query-miss on removals
//   Stream<Map<String, dynamic>?> listenToDeletedDataNoFilter({
//     required String path,
//   }) {
//     final query = dbRef.child(path);
//     return query.onChildRemoved.map((event) {
//       final value = event.snapshot.value;
//       if (value is Map) {
//         return Map<String, dynamic>.from(value);
//       }
//       return null;
//     });
//   }

//   Stream<Map<String, dynamic>?> listenToUpdatedData({
//     required String path,
//     required String orderByField,
//     required dynamic equalToValue,
//   }) {
//     return dbRef
//         .child(path)
//         .orderByChild(orderByField)
//         .equalTo(equalToValue)
//         .onChildChanged
//         .map((event) {
//       final value = event.snapshot.value;
//       if (value is Map) {
//         return Map<String, dynamic>.from(value);
//       }
//       return null;
//     });
//   }
// }
