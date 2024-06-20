import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: VoiceRecorder(),
    );
  }
}

class VoiceRecorder extends StatefulWidget {

  const VoiceRecorder({Key? key});

  @override
  _VoiceRecorderState createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> {

  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  late String _filePath;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    try {
      await _recorder.openRecorder();
      await _checkPermissions();
    } catch (e) {
      print('Error initializing recorder: $e');
    }
  }

  Future<void> _checkPermissions() async {
    try {

      var micStatus = await Permission.microphone.request();
      if (micStatus != PermissionStatus.granted) {
        throw 'Microphone permission not granted';
      }

      var storageStatus =  await Permission.storage.request().isGranted;
      if (!storageStatus) {
        throw 'Storage permission not granted';
      }
    } catch (e) {
      print('Error checking permissions: $e');
    }
  }


  Future<void> _stopRecording() async {
    try {
      await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String path = '${appDocDir.path}/voice_recording.aac';
      setState(() {
        _filePath = path;
      });
      await _recorder.startRecorder(toFile: _filePath);
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _playRecording() async {
    try {
      if (_filePath.isNotEmpty) {
        var file = File(_filePath);
        if (await file.exists()) {
          Uint8List bytes = file.readAsBytesSync();
          var buffer = bytes.buffer;

          Directory dir = await getApplicationDocumentsDirectory();
          var tmpFile = "${dir.path}/tmp.mp3";
          var writeFile = File(tmpFile).writeAsBytesSync(
              buffer.asUint8List(32, bytes.lengthInBytes - 32)); // Extract a portion of the file

          var urlSource = DeviceFileSource(tmpFile);

          AudioPlayer audioPlayer = AudioPlayer();
          audioPlayer.play(urlSource);

          audioPlayer.dispose();
        } else {
          print('File not found at path: $_filePath');
        }
      } else {
        print('File path is empty.');
      }
    } catch (e) {
      print('Error playing recording: $e');
    }
  }


  @override
  void dispose() {
    _recorder.closeRecorder();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Recorder'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _playRecording,
              child: const Text('Play Recording'),
            ),
          ],
        ),
      ),
    );
  }
}
