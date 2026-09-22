import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mushaf_alsawy/core/bloc/base_bloc.dart';
import 'package:mushaf_alsawy/core/helpers/generic_data_source.dart';
import 'package:mushaf_alsawy/core/http/either.dart';
import 'package:mushaf_alsawy/core/http/endpoints.dart';
import 'package:mushaf_alsawy/core/http/failure.dart';
import 'package:mushaf_alsawy/core/service_locator/service_locator.dart';
import 'package:mushaf_alsawy/features/quran/data/models/ayah_model.dart';

class SurahContentCubit extends Cubit<BaseState<AyahModel>> {
  SurahContentCubit({GenericDataSource? dataSource})
      : _dataSource = dataSource ?? GenericDataSource(getIt()),
        super(const BaseState<AyahModel>());

  final GenericDataSource _dataSource;

  Future<void> loadContent(
      {required int surahNumber, required int pageSize}) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null));

    final items = <AyahModel>[];
    var pageIndex = 1;
    const requestPageSize = 10;
    Either<Failure, List<AyahModel>> result =
        const Right<Failure, List<AyahModel>>([]);

    do {
      result = await _dataSource.fetchData<AyahModel>(
        endpoint: Endpoints.surahContent(surahNumber),
        queryParameters: {
          'number': surahNumber,
          'pageIndex': pageIndex,
          'pageSize': requestPageSize,
        },
        fromJson: AyahModel.fromJson,
      );

      final pageResult = result;
      if (pageResult.isError) {
        break;
      }

      final pageItems = pageResult.fold(
        (_) => <AyahModel>[],
        (page) => page,
      );
      items.addAll(pageItems);
      pageIndex++;

      if (pageItems.length < requestPageSize || items.length >= pageSize) {
        break;
      }
    } while (true);

    result.fold(
      (failure) => emit(state.copyWith(
        status: Status.failure,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: Status.success,
        items: List<AyahModel>.unmodifiable(items),
      )),
    );
  }
}
