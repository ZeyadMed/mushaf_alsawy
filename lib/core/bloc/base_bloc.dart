import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mushaf_alsawy/core/http/either.dart';
import 'package:mushaf_alsawy/core/http/failure.dart';
import 'package:mushaf_alsawy/core/http/params.dart';
part 'base_state.dart';

abstract class BaseCubit<T> extends Cubit<BaseState<T>> {
  final Future<Either<Failure, List<T>>> Function() fetchFunction;
  final Future<Either<Failure, T>> Function()? fetchFunctionMap;

  BaseCubit({required this.fetchFunction, this.fetchFunctionMap})
      : super(BaseState<T>()) {
    // fetchData();
  }

  Future<void> fetchData({
    int? teacherId,
    int? classId,
    PaginationParams? pagination,
    String? search,
  }) async {
    emit(state.copyWith(status: Status.loading));
    final result = await fetchFunction();
    result.fold(
      (failure) => emit(state.copyWith(
          status: Status.failure, errorMessage: failure.message)),
      (data) => emit(state.copyWith(status: Status.success, items: data)),
    );
  }

  Future<void> fetchDataMap() async {
    emit(state.copyWith(status: Status.loading));
    final result = await fetchFunctionMap!();
    result.fold(
      (failure) => emit(state.copyWith(
          status: Status.failure, errorMessage: failure.message)),
      (data) => emit(state.copyWith(status: Status.success, data: data)),
    );
  }
}
