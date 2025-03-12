abstract class AudioState {}

class AudioInitial extends AudioState {}

class AudioPlaying extends AudioState {}

class AudioPaused extends AudioState {}

class AudioWaveformUpdated extends AudioState {
  final List<double> waveform;
  AudioWaveformUpdated(this.waveform);
}
