import 'dart:convert';
import 'dart:io';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../constants/api_constants.dart';

class VoiceService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _filePath;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  Future<void> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _filePath = '${dir.path}/query_$timestamp.m4a';

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: _filePath!,
        );
        _isRecording = true;
      }
    } catch (e) {
      print('Failed to start recording: $e');
    }
  }

  Future<String?> stopAndSend() async {
    try {
      await _recorder.stop();
      _isRecording = false;

      if (_filePath == null || !File(_filePath!).existsSync()) {
        return null;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.BASE_URL}/api/voice-query'),
      );

      request.files.add(await http.MultipartFile.fromPath('audio', _filePath!));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Clean up the local file
      try {
        final file = File(_filePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting temp file: $e');
      }

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        return jsonResponse['answer'];
      } else {
        print('Voice query failed with status ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error during stopAndSend: $e');
      return null;
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}
