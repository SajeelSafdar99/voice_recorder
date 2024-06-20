import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecorder extends StatefulWidget {
  const VoiceRecorder({Key? key}) : super(key: key);

  @override
  _VoiceRecorderState createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _filePath;

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
      if (kDebugMode) {
        print('Error initializing recorder: $e');
      }
    }
  }

  Future<void> _checkPermissions() async {
    try {
      var micStatus = await Permission.microphone.request();
      var storageStatus = await Permission.storage.request();

      if (micStatus != PermissionStatus.granted ||
          storageStatus != PermissionStatus.granted) {
        throw 'Microphone and storage permissions are required';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking permissions: $e');
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String path = '${appDocDir.path}/voice_recording_${DateTime.now().millisecondsSinceEpoch}.aac';
      setState(() {
        _filePath = path;
      });
      await _recorder.startRecorder(toFile: _filePath);
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error starting recording: $e');
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping recording: $e');
      }
    }
  }

  Future<void> _playRecording() async {
    try {
      if (_filePath != null && _filePath!.isNotEmpty) {
        var file = File(_filePath!);
        if (await file.exists()) {
          await _audioPlayer.play(DeviceFileSource(_filePath!));
        } else {
          if (kDebugMode) {
            print('File not found at path: $_filePath');
          }
        }
      } else {
        if (kDebugMode) {
          print('File path is empty.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing recording: $e');
      }
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
