import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mushaf_alsawy/core/bloc/base_bloc.dart';
import 'package:mushaf_alsawy/core/helpers/generic_data_source.dart';
import 'package:mushaf_alsawy/core/http/endpoints.dart';
import 'package:mushaf_alsawy/core/service_locator/service_locator.dart';
import 'package:mushaf_alsawy/features/hadith/data/models/hadith_model.dart';

class HadithListCubit extends Cubit<BaseState<HadithModel>> {
  HadithListCubit({required this.matnId, GenericDataSource? dataSource})
      : _dataSource = dataSource ?? GenericDataSource(getIt()),
        super(const BaseState<HadithModel>());

  final int matnId;
  final GenericDataSource _dataSource;
  final List<HadithModel> _allItems = [];
  int _pageIndex = 1;
  String _search = '';
  bool _hasMore = true;

  Future<void> loadHadiths({String search = '', bool refresh = false}) async {
    if (refresh) {
      _pageIndex = 1;
      _search = search.trim();
      _hasMore = true;
      _allItems.clear();
      emit(state.copyWith(
        status: Status.loading,
        items: const [],
        hasReachedMax: false,
        errorMessage: null,
      ));
    }

    if (!_hasMore || state.status == Status.isLoadingMore) return;
    final isFirstPage = _pageIndex == 1;
    if (!isFirstPage) emit(state.copyWith(status: Status.isLoadingMore));

    final result = await _dataSource.fetchData<HadithModel>(
      endpoint: Endpoints.hadiths,
      queryParameters: {
        'MatnId': matnId,
        'Search': _search,
        'PageIndex': _pageIndex,
        'PageSize': 10,
      },
      fromJson: HadithModel.fromJson,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: isFirstPage ? Status.failure : Status.isLoadingMoreFauilare,
        errorMessage: failure.message,
      )),
      (items) {
        _allItems.addAll(items);
        _hasMore = items.length == 10;
        if (_hasMore) _pageIndex++;
        emit(state.copyWith(
          status: Status.success,
          items: List<HadithModel>.unmodifiable(_allItems),
          hasReachedMax: !_hasMore,
          errorMessage: null,
        ));
      },
    );
  }

  Future<void> loadMore() => loadHadiths();

  Future<void> retry() => loadHadiths(search: _search, refresh: true);
}
