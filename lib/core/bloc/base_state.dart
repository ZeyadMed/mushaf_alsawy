part of 'base_bloc.dart';

enum Status { initial, loading, success, failure, isLoadingMore,isLoadingMoreFauilare , custom }

extension BaseStateX<T> on BaseState<T> {
  bool get isInitial => status == Status.initial;

  bool get isLoading => status == Status.loading;

  bool get isSuccess => status == Status.success;

  bool get isFailure => status == Status.failure;

  bool get isCustom => status == Status.custom;

  bool get isLoadingMore => status == Status.isLoadingMore;

  bool get isLoadingMoreFauilare => status == Status.isLoadingMoreFauilare;
  

  bool get isEmpty => isSuccess && items.isEmpty;

  bool get hasData => data != null;
}
 class BaseState<T> extends Equatable {
  final Status status;
  final String? errorMessage;
  final Failure? failure;
  final T? data;
  final List<T> items;
  final DateTime? lastUpdated;
  final Map<String, dynamic> metadata;
  final List<Map<String, dynamic>> secondaryMetadata;
  final int statusCode;
  final int page;
  final bool hasReachedMax;

  const BaseState({
    this.status = Status.initial,
    this.errorMessage,
    this.data,
    this.lastUpdated,
    this.items = const [],
    this.failure,
    this.metadata = const {},
    this.secondaryMetadata = const [],
    this.statusCode = 200,
    this.page = 1,
    this.hasReachedMax = false,
  });

  BaseState<T> copyWith({
    Status? status,
    String? errorMessage,
    T? data,
    DateTime? lastUpdated,
    List<Map<String, dynamic>>? secondaryMetadata,
    List<T>? items,
    Failure? failure,
    Map<String, dynamic>? metadata,
    int? statusCode,
    int? page,
    bool? hasReachedMax,
  }) {
    return BaseState<T>(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      data: data ?? this.data,
      items: items ?? this.items,
      secondaryMetadata: secondaryMetadata?? this.secondaryMetadata,
      metadata: metadata ?? this.metadata,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      failure: failure ?? this.failure,
      statusCode: statusCode ?? this.statusCode,
      page: page ?? this.page,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, data, items, metadata,secondaryMetadata, lastUpdated,failure, statusCode, page, hasReachedMax];
}