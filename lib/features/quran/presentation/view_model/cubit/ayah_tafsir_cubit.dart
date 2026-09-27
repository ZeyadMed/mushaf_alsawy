import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mushaf_alsawy/core/bloc/base_bloc.dart';
import 'package:mushaf_alsawy/core/helpers/generic_data_source.dart';
import 'package:mushaf_alsawy/core/http/endpoints.dart';
import 'package:mushaf_alsawy/core/service_locator/service_locator.dart';
import 'package:mushaf_alsawy/features/quran/data/models/ayah_model.dart';
import 'package:mushaf_alsawy/features/quran/data/models/surah_content_response.dart';

/// Loads a single ayah (with its tafsir) from the surah content endpoint.
class AyahTafsirCubit extends Cubit<BaseState<AyahModel>> {
  AyahTafsirCubit({GenericDataSource? dataSource})
      : _dataSource = dataSource ?? GenericDataSource(getIt()),
        super(const BaseState<AyahModel>());

  final GenericDataSource _dataSource;

  static final Map<String, AyahModel> _cache = {};

  Future<void> loadTafsir({required int surah, required int ayah}) async {
    final key = '$surah:$ayah';
    if (_cache[key] case final cached?) {
      emit(state.copyWith(status: Status.success, data: cached));
      return;
    }
    emit(state.copyWith(status: Status.loading, errorMessage: null));
    final result = await _dataSource.fetchResult<SurahContentResponse>(
      endpoint: Endpoints.surahContent(surah),
      queryParameters: {'number': surah, 'pageIndex': ayah, 'pageSize': 1},
      fromJson: SurahContentResponse.fromJson,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        status: Status.failure,
        errorMessage: failure.message,
      )),
      (response) {
        if (response.ayahs.isEmpty) {
          emit(state.copyWith(
            status: Status.failure,
            errorMessage: 'تعذر تحميل التفسير',
          ));
          return;
        }
        final model = response.ayahs.first;
        _cache[key] = model;
        emit(state.copyWith(status: Status.success, data: model));
      },
    );
  }
}
