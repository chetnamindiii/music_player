import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:waveform_flutter/waveform_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'bloc/audio_bloc.dart';
import 'bloc/audio_event.dart';
import 'bloc/audio_state.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (context) => AudioBloc(),
        child: MusicPlayerScreen(),
      ),
    );
  }
}

class MusicPlayerScreen extends StatefulWidget {
  @override
  _MusicPlayerScreenState createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  StreamController<Amplitude>? _amplitudeStreamController;
  Random random = Random();

  final String audioUrl =
      "https://codeskulptor-demos.commondatastorage.googleapis.com/descent/background%20music.mp3";

  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }

  void _initializeAudio() async {
    await _audioPlayer.setUrl(audioUrl);

    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        setState(() {
          isPlaying = false;
          _toggleWaveform(false);
        });

        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
      }
    });
  }

  void _toggleWaveform(bool play) {
    if (play) {
      _amplitudeStreamController = StreamController<Amplitude>();

      Timer.periodic(Duration(milliseconds: 50), (timer) {
        if (_amplitudeStreamController != null &&
            !_amplitudeStreamController!.isClosed) {
          double baseAmplitude = 10 + random.nextDouble() * 5;
          double waveVariation =
              sin(timer.tick * 0.2) * 5 + random.nextDouble() * 3;
          double finalAmplitude = baseAmplitude + waveVariation;

          _amplitudeStreamController!.add(
            Amplitude(
              current: finalAmplitude,
              max: 30.0,
            ),
          );
        } else {
          timer.cancel();
        }
      });
    } else {
      _amplitudeStreamController?.close();
      _amplitudeStreamController = null;
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _amplitudeStreamController?.close();
    super.dispose();
  }

  Stream<Duration> get _progressStream =>
      Rx.combineLatest2<Duration, Duration?, Duration>(
        _audioPlayer.positionStream,
        _audioPlayer.durationStream.map((d) => d ?? Duration.zero),
        (position, duration) => position,
      );

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Music Player"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: screenWidth * 0.6,
              height: screenWidth * 0.6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/cover.jpg', fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            Text(
              "Imagine Dragons - Thunder",
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Alternative Rock",
              style: TextStyle(
                color: Colors.white70,
                fontSize: screenWidth * 0.04,
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            SizedBox(
              height: screenHeight * 0.12,
              child: isPlaying && _amplitudeStreamController != null
                  ? AnimatedWaveList(
                      stream: _amplitudeStreamController!.stream,
                      barBuilder: (animation, amplitude) {
                        Color dynamicColor = (amplitude.current > 15)
                            ? Colors.red
                            : Colors.blueAccent;

                        return WaveFormBar(
                          animation: animation,
                          amplitude: amplitude,
                          color: dynamicColor,
                        );
                      },
                    )
                  : Center(
                      child:
                          Text("Paused", style: TextStyle(color: Colors.white)),
                    ),
            ),
            SizedBox(height: screenHeight * 0.03),
            StreamBuilder<Duration>(
              stream: _progressStream,
              builder: (context, snapshot) {
                Duration position = snapshot.data ?? Duration.zero;
                return Column(
                  children: [
                    Slider(
                      activeColor: Colors.blueAccent,
                      inactiveColor: Colors.white24,
                      min: 0.0,
                      max: (_audioPlayer.duration ?? Duration.zero)
                          .inSeconds
                          .toDouble(),
                      value: position.inSeconds.toDouble(),
                      onChanged: (value) {
                        _audioPlayer.seek(Duration(seconds: value.toInt()));
                      },
                    ),
                    Text(
                      "${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: screenHeight * 0.03),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.skip_previous,
                      color: Colors.white, size: screenWidth * 0.1),
                  onPressed: () {},
                ),
                SizedBox(width: screenWidth * 0.05),
                ElevatedButton(
                  onPressed: () {
                    if (isPlaying) {
                      _audioPlayer.pause();
                      _toggleWaveform(false);
                    } else {
                      _audioPlayer.play();
                      _toggleWaveform(true);
                    }
                    setState(() {
                      isPlaying = !isPlaying;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    size: screenWidth * 0.08,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: screenWidth * 0.05),
                IconButton(
                  icon: Icon(Icons.skip_next,
                      color: Colors.white, size: screenWidth * 0.1),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
