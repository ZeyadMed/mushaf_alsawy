import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mushaf_alsawy/core/bloc/base_bloc.dart';
import 'package:mushaf_alsawy/core/helpers/generic_data_source.dart';
import 'package:mushaf_alsawy/core/http/endpoints.dart';
import 'package:mushaf_alsawy/core/service_locator/service_locator.dart';
import 'package:mushaf_alsawy/features/hadith/data/models/hadith_matn_model.dart';

class HadithMatnsCubit extends Cubit<BaseState<HadithMatnModel>> {
  HadithMatnsCubit({GenericDataSource? dataSource})
      : _dataSource = dataSource ?? GenericDataSource(getIt()),
        super(const BaseState<HadithMatnModel>());

  final GenericDataSource _dataSource;

  Future<void> loadMatns() async {
    emit(state.copyWith(status: Status.loading, errorMessage: null));
    final result = await _dataSource.fetchData<HadithMatnModel>(
      endpoint: Endpoints.hadithMatns,
      fromJson: HadithMatnModel.fromJson,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: Status.failure,
        errorMessage: failure.message,
      )),
      (items) => emit(state.copyWith(status: Status.success, items: items)),
    );
  }
}
