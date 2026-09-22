import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mushaf_alsawy/core/bloc/base_bloc.dart';
import 'package:mushaf_alsawy/core/helpers/generic_data_source.dart';
import 'package:mushaf_alsawy/core/http/endpoints.dart';
import 'package:mushaf_alsawy/core/service_locator/service_locator.dart';
import 'package:mushaf_alsawy/features/hadith/data/models/hadith_model.dart';

class HadithDetailsCubit extends Cubit<BaseState<HadithModel>> {
  HadithDetailsCubit({GenericDataSource? dataSource})
      : _dataSource = dataSource ?? GenericDataSource(getIt()),
        super(const BaseState<HadithModel>());

  final GenericDataSource _dataSource;

  Future<void> loadHadith(int id) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null));
    final result = await _dataSource.fetchResult<HadithModel>(
      endpoint: Endpoints.hadith(id),
      fromJson: HadithModel.fromJson,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: Status.failure,
        errorMessage: failure.message,
      )),
      (hadith) => emit(state.copyWith(status: Status.success, data: hadith)),
    );
  }
}
