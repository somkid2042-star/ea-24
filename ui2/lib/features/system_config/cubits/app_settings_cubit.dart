import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/system_config/system_config_repository.dart';

sealed class AppSettingsState {
  const AppSettingsState();
}

final class AppSettingsInitial extends AppSettingsState {
  const AppSettingsInitial();
}

final class AppSettingsFetchInProgress extends AppSettingsState {
  const AppSettingsFetchInProgress();
}

final class AppSettingsFetchSuccess extends AppSettingsState {
  const AppSettingsFetchSuccess(this.settingsData);

  final String settingsData;
}

final class AppSettingsFetchFailure extends AppSettingsState {
  const AppSettingsFetchFailure(this.errorCode);

  final String errorCode;
}

final class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit(this._systemConfigRepository)
    : super(const AppSettingsInitial());

  final SystemConfigRepository _systemConfigRepository;

  void getAppSetting(String type) {
    emit(const AppSettingsFetchInProgress());
    _systemConfigRepository
        .getAppSettings(type)
        .then((value) => emit(AppSettingsFetchSuccess(value)))
        .catchError((Object e) {
          emit(AppSettingsFetchFailure(e.toString()));
        });
  }
}
