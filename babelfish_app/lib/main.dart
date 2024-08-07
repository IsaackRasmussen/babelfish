import 'dart:async';
import 'package:record/record.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_speech/endless_streaming_service_v2.dart';
import 'package:google_speech/generated/google/cloud/speech/v2/cloud_speech.pb.dart';
import 'package:google_speech/google_speech.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_text_to_speech/cloud_text_to_speech.dart';

import 'package:stomp_dart_client/stomp_dart_client.dart';

const int kAudioSampleRate = 16000;
const int kAudioNumChannels = 1;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
//Do init once and run it before any other method
//Do init once and run it before any other method
    TtsGoogle.init(apiKey: "apiKey");

    return MaterialApp(
      title: 'Mic Stream Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AudioRecognize(),
    );
  }
}

class AudioRecognize extends StatefulWidget {
  const AudioRecognize({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AudioRecognizeState();
}

class _AudioRecognizeState extends State<AudioRecognize> {
  final _audioRecorder = AudioRecorder();
  StompClient? client;

  bool recognizing = false;
  bool recognizeFinished = false;
  String text = '';
  Stream<Uint8List>? _audioStream;

  @override
  void initState() {
    super.initState();
  }

  void onConnectCallback(StompFrame connectFrame) {
    // client is connected and ready
    client?.subscribe(
        destination: '/foo/bar',
        headers: {},
        callback: (frame) {
          // Received a frame for this subscription
          print(frame.body);
        });
  }

  void playSound() async {
    client = StompClient(
        config: StompConfig(
            url: 'wss://localhost:7042/stomp', onConnect: onConnectCallback));

    client?.activate();
  }

  void streamingRecognize() async {
// Check and request permission if needed
    if (await _audioRecorder.hasPermission()) {
      // Start recording to stream
      _audioStream = await _audioRecorder.startStream(const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: kAudioSampleRate,
          numChannels: kAudioNumChannels));
    }
    // Stream to be consumed by speech recognizer
    // Create recording stream

    setState(() {
      recognizing = true;
    });

    await Permission.microphone.request();

    final serviceAccount = ServiceAccount.fromString((await rootBundle
        .loadString('assets/configs/test_service_account.json')));
    final speechToText = EndlessStreamingServiceV2.viaServiceAccount(
        serviceAccount,
        projectId: 'babelfish-431609');
    final config = _getConfig();

    final responseStream = speechToText.endlessStream;

    speechToText.endlessStreamingRecognize(
        StreamingRecognitionConfigV2(
            config: config,
            streamingFeatures:
                StreamingRecognitionFeatures(interimResults: true)),
        _audioStream!,
        restartTime: const Duration(seconds: 60),
        transitionBufferTime: const Duration(seconds: 2));

    var responseText = '';

    responseStream.listen((data) {
      final currentText = data.results
          .where((e) => e.alternatives.isNotEmpty)
          .map((e) => e.alternatives.first.transcript)
          .join('\n');

      if (data.results.first.isFinal) {
        responseText += '\n' + currentText;
        setState(() {
          text = responseText;
          recognizeFinished = true;
        });
      } else {
        setState(() {
          text = responseText + '\n' + currentText;
          recognizeFinished = true;
        });
      }
    }, onDone: () {
      setState(() {
        recognizing = false;
      });
    });
  }

  void stopRecording() async {
    final path = await _audioRecorder.stop();
    //_audioRecorder.dispose();
    setState(() {
      recognizing = false;
    });
  }

  RecognitionConfigV2 _getConfig() => RecognitionConfigV2(
      model: RecognitionModelV2.long,
      languageCodes: ['de-DE', 'en-US'],
      features: RecognitionFeatures(),
      explicitDecodingConfig: ExplicitDecodingConfig(
        encoding: ExplicitDecodingConfig_AudioEncoding.LINEAR16,
        sampleRateHertz: kAudioSampleRate,
        audioChannelCount: kAudioNumChannels,
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio File Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: _RecognizeContent(
                  text: text,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: recognizing ? stopRecording : streamingRecognize,
                  child: recognizing
                      ? const Text('Stop recording')
                      : const Text('Start endless streaming from mic'),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                    onPressed: playSound, child: const Text('Play')),
              ),
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class _RecognizeContent extends StatelessWidget {
  final String text;

  const _RecognizeContent({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          const Text(
            'The text recognized by the Google Speech Api:',
          ),
          const SizedBox(
            height: 16.0,
          ),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
/*import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

void main() async {
  // Set up the SettingsController, which will glue user settings to multiple
  // Flutter Widgets.
  final settingsController = SettingsController(SettingsService());

  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.
  runApp(MyApp(settingsController: settingsController));
}
*/