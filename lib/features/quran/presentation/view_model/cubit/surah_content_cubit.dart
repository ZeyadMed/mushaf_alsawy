import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mushaf_alsawy/core/bloc/base_bloc.dart';
import 'package:mushaf_alsawy/core/helpers/generic_data_source.dart';
import 'package:mushaf_alsawy/core/http/either.dart';
import 'package:mushaf_alsawy/core/http/endpoints.dart';
import 'package:mushaf_alsawy/core/http/failure.dart';
import 'package:mushaf_alsawy/core/service_locator/service_locator.dart';
import 'package:mushaf_alsawy/features/quran/data/models/ayah_model.dart';
import 'package:mushaf_alsawy/features/quran/data/models/surah_content_response.dart';

class SurahContentCubit extends Cubit<BaseState<AyahModel>> {
  SurahContentCubit({GenericDataSource? dataSource})
      : _dataSource = dataSource ?? GenericDataSource(getIt()),
        super(const BaseState<AyahModel>());

  final GenericDataSource _dataSource;
  String? audioUrl;

  Future<void> loadContent(
      {required int surahNumber, required int pageSize}) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null));

    final items = <AyahModel>[];
    var pageIndex = 1;
    const requestPageSize = 10;
    Either<Failure, SurahContentResponse> result =
        const Right<Failure, SurahContentResponse>(
            SurahContentResponse(ayahs: []));

    do {
      result = await _dataSource.fetchResult<SurahContentResponse>(
        endpoint: Endpoints.surahContent(surahNumber),
        queryParameters: {
          'number': surahNumber,
          'pageIndex': pageIndex,
          'pageSize': requestPageSize,
        },
        fromJson: SurahContentResponse.fromJson,
      );

      final pageResult = result;
      if (pageResult.isError) {
        break;
      }

      final response = pageResult.fold(
        (_) => const SurahContentResponse(ayahs: []),
        (page) => page,
      );
      audioUrl ??= response.audioUrl?.trim();
      final pageItems = response.ayahs;
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
