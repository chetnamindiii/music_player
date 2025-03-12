abstract class AudioEvent {}

class PlayAudio extends AudioEvent {}

class PauseAudio extends AudioEvent {}

class UpdateWaveform extends AudioEvent {
  final List<double> waveform;
  UpdateWaveform(this.waveform);
}
