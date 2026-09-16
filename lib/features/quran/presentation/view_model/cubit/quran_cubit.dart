import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mushaf_alsawy/core/bloc/base_bloc.dart';
import 'package:mushaf_alsawy/core/helpers/generic_data_source.dart';
import 'package:mushaf_alsawy/core/helpers/pagination_helper.dart';
import 'package:mushaf_alsawy/core/http/endpoints.dart';
import 'package:mushaf_alsawy/core/service_locator/service_locator.dart';
import 'package:mushaf_alsawy/features/quran/data/models/surah_model.dart';

class QuranCubit extends Cubit<BaseState<SurahModel>> {
  QuranCubit({GenericDataSource? dataSource})
      : _dataSource = dataSource ?? GenericDataSource(getIt()),
        super(const BaseState<SurahModel>());

  final GenericDataSource _dataSource;
  late final PaginationHandler<SurahModel, QuranCubit> pagination =
      PaginationHandler<SurahModel, QuranCubit>(bloc: this, pageSize: 10);

  String _search = '';

  Future<void> loadSurahs({String search = '', bool refresh = false}) async {
    _search = search.trim();
    if (refresh || state.status == Status.initial) {
      emit(state.copyWith(
        status: Status.loading,
        items: const [],
        page: 1,
        hasReachedMax: false,
        errorMessage: null,
      ));
      pagination.items.clear();
      pagination.currentPage = 1;
      pagination.hasMoreData = true;
    }

    if (state.status == Status.isLoadingMore || !pagination.hasMoreData) {
      return;
    }

    final page = pagination.currentPage;
    if (page > 1) {
      emit(state.copyWith(status: Status.isLoadingMore));
    }

    final result = await _fetchPage(page, 10);
    result.fold(
      (failure) {
        emit(state.copyWith(
          status: page == 1 ? Status.failure : Status.isLoadingMoreFauilare,
          errorMessage: failure.message,
        ));
      },
      (data) {
        pagination.items.addAll(data);
        if (data.length < 10) {
          pagination.hasMoreData = false;
        } else {
          pagination.currentPage++;
        }
        emit(state.copyWith(
          status: Status.success,
          items: List<SurahModel>.unmodifiable(pagination.items),
          page: pagination.currentPage,
          hasReachedMax: !pagination.hasMoreData,
          errorMessage: null,
        ));
      },
    );
  }

  Future<void> loadMore() async {
    if (state.status != Status.isLoadingMore) {
      await loadSurahs();
    }
  }

  Future<void> retry() => loadSurahs(search: _search, refresh: true);

  Future<dynamic> _fetchPage(int page, int limit) {
    return _dataSource.fetchData<SurahModel>(
      endpoint: Endpoints.surahs,
      queryParameters: {
        'pageIndex': page,
        'pageSize': limit,
        if (_search.isNotEmpty) 'Search': _search,
      },
      fromJson: SurahModel.fromJson,
    );
  }
}
