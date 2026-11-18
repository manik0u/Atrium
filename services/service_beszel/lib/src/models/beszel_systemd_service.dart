import 'package:core_models/core_models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'beszel_systemd_service.freezed.dart';
part 'beszel_systemd_service.g.dart';

@freezed
abstract class BeszelSystemdService with _$BeszelSystemdService {
  const factory BeszelSystemdService({
    @Default('') String id,
    @Default('') String name,
    @Default('') String system,
    @Default(0) int state,
    @Default(0) int sub,
    @Default(0.0) double cpu,
    @Default(0.0) double memory,
  }) = _BeszelSystemdService;

  factory BeszelSystemdService.fromJson(Map<String, dynamic> json) =>
      _$BeszelSystemdServiceFromJson(json);
}

extension BeszelSystemdServiceX on BeszelSystemdService {
  String get stateStr {
    switch (state) {
      case 0: return S.t('active');
      case 1: return S.t('inactive');
      case 2: return S.t('failed');
      case 3: return S.t('activating');
      case 4: return 'Deactivating';
      case 5: return 'Reloading';
      default: return S.t('unknown');
    }
  }

  String get subStr {
    switch (sub) {
      case 0: return 'Dead';
      case 1: return S.t('running');
      case 2: return 'Exited';
      case 3: return S.t('failed');
      case 4: return S.t('unknown');
      default: return S.t('unknown');
    }
  }
}
