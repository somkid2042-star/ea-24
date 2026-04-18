import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

sealed class MusicPlayerState {
  const MusicPlayerState();
}

final class MusicPlayerInitial extends MusicPlayerState {
  const MusicPlayerInitial();
}

final class MusicPlayerLoaded extends MusicPlayerState {
  const MusicPlayerLoaded({required this.audioDuration});

  final Duration audioDuration;
}

final class MusicPlayerFailure extends MusicPlayerState {
  const MusicPlayerFailure(this.errorMessage);

  final String errorMessage;
}

final class MusicPlayerLoading extends MusicPlayerState {
  const MusicPlayerLoading();
}

final class MusicPlayerCubit extends Cubit<MusicPlayerState> {
  MusicPlayerCubit() : super(const MusicPlayerInitial());

  final AudioPlayer _audioPlayer = AudioPlayer();

  AudioPlayer get audioPlayer => _audioPlayer;

  Future<void> initPlayer(String url) async {
    try {
      emit(const MusicPlayerLoading());

      final result = await _audioPlayer.setUrl(url);

      emit(MusicPlayerLoaded(audioDuration: result!));
    } on Exception catch (_) {
      emit(const MusicPlayerFailure('Error while playing music'));
    }
  }

  @override
  Future<void> close() async {
    await _audioPlayer.dispose();
    await super.close();
  }
}
