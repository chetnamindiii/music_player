import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_event.dart';
import 'audio_state.dart';

class AudioBloc extends Bloc<AudioEvent, AudioState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final String audioUrl =
      "https://codeskulptor-demos.commondatastorage.googleapis.com/descent/background%20music.mp3";

  AudioBloc() : super(AudioInitial()) {
    on<PlayAudio>((event, emit) async {
      try {
        await _audioPlayer.setUrl(audioUrl);
        await _audioPlayer.play();
        emit(AudioPlaying());
      } catch (e) {
        emit(AudioPaused());
      }
    });

    on<PauseAudio>((event, emit) async {
      await _audioPlayer.pause();
      emit(AudioPaused());
    });

    on<UpdateWaveform>((event, emit) {
      emit(AudioWaveformUpdated(event.waveform));
    });
  }
}
