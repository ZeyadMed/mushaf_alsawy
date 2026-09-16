import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:mushaf_alsawy/core/bloc/base_bloc.dart';
import 'package:mushaf_alsawy/core/http/either.dart';
import 'package:mushaf_alsawy/core/http/failure.dart';

/// A ScrollController variant that tolerates being attached to multiple
/// scrollables. Flutter's default [ScrollController] asserts when the same
/// controller is attached to more than one [ScrollPosition]. In codebases
/// where a shared cubit exposes a controller used by multiple screens (for
/// example when screens are kept alive by an `IndexedStack`), that can
/// trigger an assertion.
///
/// This implementation tries the normal attach via `super.attach`. If the
/// framework throws (e.g. an assertion), the controller falls back to
/// listening directly to the provided [ScrollPosition] and forwards metrics
/// via [onPositionScroll]. This allows the cubit to react to scroll events
/// without forcing a single controller instance to be uniquely attached.
class _SafeScrollController extends ScrollController {
  _SafeScrollController({
    this.onPositionScroll,
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    String? debugLabel,
  }) : super(
          initialScrollOffset: initialScrollOffset,
          keepScrollOffset: keepScrollOffset,
          debugLabel: debugLabel,
        );

  final void Function(ScrollPosition pos)? onPositionScroll;
  final Map<ScrollPosition, VoidCallback> _positionListeners = {};

  @override
  void attach(ScrollPosition position) {
    try {
      super.attach(position);
    } catch (_) {
      // Fallback: add a direct listener to the ScrollPosition so we still
      // receive scroll callbacks even if we cannot attach to the controller
      // positions set (which is where framework would normally register).
      if (!_positionListeners.containsKey(position)) {
        final listener = () {
          try {
            onPositionScroll?.call(position);
          } catch (_) {}
        };
        position.addListener(listener);
        _positionListeners[position] = listener;
      }
    }
  }

  @override
  void detach(ScrollPosition position) {
    // Remove any fallback listener we added.
    final l = _positionListeners.remove(position);
    if (l != null) {
      try {
        position.removeListener(l);
      } catch (_) {}
    }
    try {
      super.detach(position);
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final kv
        in Map<ScrollPosition, VoidCallback>.from(_positionListeners).entries) {
      try {
        kv.key.removeListener(kv.value);
      } catch (_) {}
    }
    _positionListeners.clear();
    try {
      super.dispose();
    } catch (_) {}
  }
}

// افتراض: عندك هياكل شبيهة باللي استخدمتها في كودك (Failure, BaseState, Status)
// لو مسمياتك مختلفة عدّلها حسب مشروعك.

abstract class GenericPaginationCubit<T> extends Cubit<BaseState<T>> {
  GenericPaginationCubit() : super(BaseState<T>());

  /// A scroll controller that is tolerant to being attached to multiple
  /// scrollables. In the common case the framework will attach the
  /// controller normally and the cubit's listener will be invoked; in
  /// the rare case where attaching to multiple scrollables would throw
  /// an assertion, the controller falls back to listening directly to
  /// the individual [ScrollPosition]s and forwards metrics to the
  /// provided callback.
  late final _SafeScrollController scrollController =
      _SafeScrollController(onPositionScroll: _handlePositionScroll);

  // استدعيها من initState للـ Widget أو من مكان التهيئة
  void initPagination() {
    // Ensure the controller has our listener attached. If the framework
    // attaches the controller to a Scrollable normally this will work.
    // If attaching fails (e.g. because another Scrollable already used
    // the same controller), the safe controller will instead attach a
    // listener directly to the ScrollPosition and call
    // `_handlePositionScroll`.
    try {
      scrollController.addListener(_onScroll);
    } catch (_) {
      // In case of unexpected errors, ensure we still try to rely on
      // position-level callbacks (the safe controller handles this).
    }
  }

  // لو عايز تُنضّف (close) لما الـ cubit يتقفل
  @override
  Future<void> close() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    return super.close();
  }

  void _onScroll() {
    // Default controller-based path (when controller is attached normally)
    try {
      final pos = scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent &&
          !state.hasReachedMax &&
          !state.isFailure &&
          !state.isLoading &&
          !state.isLoadingMore &&
          !state.isLoadingMoreFauilare) {
        fetch(page: state.page);
      }
    } catch (_) {
      // If the controller doesn't expose a position (because we fell back
      // to position-level listeners), ignore here — position callbacks
      // will call _handlePositionScroll instead.
    }
  }

  void _handlePositionScroll(ScrollPosition pos) {
    try {
      if (pos.pixels >= pos.maxScrollExtent &&
          !state.hasReachedMax &&
          !state.isFailure &&
          !state.isLoading &&
          !state.isLoadingMore &&
          !state.isLoadingMoreFauilare) {
        fetch(page: state.page);
      }
    } catch (_) {}
  }

  // دالة عامة للاستدعاء من الـ UI لو عايز تعيد التحميل
  Future<void> refresh() async => fetch(page: 1);

  /// Apply a filter (metadata) to the pagination and reload from the start.
  ///
  /// - `metadata`: arbitrary key/value map that the subclass `loadPage`
  ///   implementation can read from `state.metadata` to apply filters.
  /// - `reset`: when true (default) the current items/page will be reset
  ///   and fetching will start from page 1.
  Future<void> applyFilter(
      {Map<String, dynamic>? metadata, bool reset = true}) async {
    // Merge provided metadata with existing metadata so filters accumulate
    final Map<String, dynamic> newMeta = {
      ...state.metadata,
      ...(metadata ?? {}),
    };

    if (reset) {
      // Emit a loading state and reset pagination so fetch(page:1)
      // will replace items. Include metadata so it is preserved.
      emit(state.copyWith(
        status: Status.loading,
        metadata: newMeta,
        page: 1,
        items: [],
        hasReachedMax: false,
      ));
    } else {
      // Update metadata and set loading, without clearing UI immediately.
      emit(state.copyWith(
        status: Status.loading,
        metadata: newMeta,
      ));
    }

    await fetch(page: 1);
  }

  /// Remove the `date` filter (if present), reset pagination and fetch
  /// the first page. Useful when you want to clear date filtering and
  /// reload data from scratch.
  Future<void> fetchFirstPageClearDate() async {
    // emit(state.copyWith(metadata: null));
    final Map<String, dynamic> newMeta = {
      ...state.metadata,
    }..remove('date');

    // Reset pagination state and emit loading so UI shows the loading state.
    emit(state.copyWith(
      status: Status.loading,
      metadata: newMeta,
      page: 1,
      items: [],
      hasReachedMax: false,
    ));

    await fetch(page: 1);
  }

  // الدالة العامة اللي تدير الفيتش
  Future<void> fetch({required int page}) async {
    if (state.hasReachedMax && page != 1) return;

    if (page == 1) {
      emit(state.copyWith(status: Status.loading));
    } else {
      emit(state.copyWith(status: Status.isLoadingMore));
    }

    final Either<Failure, dynamic> result = await loadPage(page);

    result.fold(
      (failure) => _handleFailure(page, failure),
      (data) => _handleSuccess(page, data),
    );
  }

  void _handleFailure(int page, Failure failure) {
    if (page == 1) {
      emit(state.copyWith(
          status: Status.failure, errorMessage: failure.message));
    } else {
      emit(state.copyWith(
          status: Status.isLoadingMoreFauilare, errorMessage: failure.message));
    }
  }

  void _handleSuccess(int page, dynamic pageResult) {
    // Attempt to handle several pagination shapes used by different APIs.
    // Common shapes:
    // - pageResult.items (List)
    // - pageResult.clients (List)  <- used by Clients API (ClientData)
    // - pageResult['data'] (Map) with inner list
    try {
      // Try multiple known keys to obtain the list of items.
      dynamic rawList;
      try {
        rawList = pageResult.items;
      } catch (_) {
        try {
          rawList = (pageResult as dynamic).clients;
        } catch (_) {
          try {
            // some APIs return 'opponents' (opponents list)
            rawList = (pageResult as dynamic).opponents;
          } catch (_) {
            try {
              // opponent lawyers, or other similarly named lists
              rawList = (pageResult as dynamic).opponentLawyers;
            } catch (_) {
              try {
                // fallback to map-like access (e.g. when pageResult is a Map)
                rawList = pageResult['data'];
              } catch (_) {
                rawList = null;
              }
            }
          }
        }
      }

      // If still null, try to introspect Map shapes: find the first List value
      if (rawList == null) {
        try {
          if (pageResult is Map) {
            // 1) check direct values for a List
            for (final v in pageResult.values) {
              if (v is List) {
                rawList = v;
                break;
              }
              // 2) sometimes the API wraps list under a nested 'data' map
              if (v is Map && v['data'] is List) {
                rawList = v['data'];
                break;
              }
            }
          }
        } catch (_) {}
      }

      if (rawList == null) {
        throw StateError('Unable to parse paginated items from response');
      }

      final List<T> data = (rawList as List).cast<T>();

      // Debug logging to help trace pagination issues
      try {
        final dynPag = pageResult.pagination;
        debugPrint(
            '[Pagination] page requested: $page, received items: ${data.length}');
        debugPrint('[Pagination] pagination raw: ${dynPag.toString()}');
      } catch (_) {}

      int _toInt(dynamic v) {
        if (v == null) return 0;
        if (v is int) return v;
        if (v is double) return v.toInt();
        if (v is String) return int.tryParse(v) ?? 0;
        return 0;
      }

      final dynamic pagination = pageResult.pagination;
      final int currentPage = _toInt(pagination?.currentPage);
      int pagesCount = _toInt(pagination?.pagesCount);
      final int perPage = _toInt(pagination?.perPage);
      final int total = _toInt(pagination?.total);

      // If pagesCount is not provided, try calculating from total/perPage
      if (pagesCount == 0 && perPage > 0 && total > 0) {
        pagesCount = ((total + perPage - 1) / perPage).ceil();
      }

      // Fallback: if pagesCount still zero, but `total` seems like page count, use it
      if (pagesCount == 0 && total > 0) {
        pagesCount = total;
      }

      final List<T> updated = page == 1 ? data : [...state.items, ...data];

      final bool reachedMax =
          (pagesCount > 0) ? (currentPage >= pagesCount) : data.isEmpty;

      emit(state.copyWith(
        status: Status.success,
        items: updated,
        page: page + 1,
        hasReachedMax: reachedMax,
      ));
      debugPrint(
          '[Pagination] emitted success: items=${updated.length}, nextPage=${page + 1}, hasReachedMax=$reachedMax');
    } catch (e) {
      // If parsing failed, emit failure so UI can handle it and avoid silent breakage.
      debugPrint('[Pagination] parse error: ${e.toString()}');
      emit(state.copyWith(status: Status.failure, errorMessage: e.toString()));
    }
  }

  // الـ subclass لازم ي implement الدالة دي
  Future<Either<Failure, dynamic>> loadPage(int page);
}
