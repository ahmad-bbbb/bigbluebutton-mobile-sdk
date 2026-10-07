import 'dart:async';

import 'package:bbb_meeting_sdk/bbb_meeting_sdk.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'bbb_meeting_sdk example',
        theme: ThemeData(colorSchemeSeed: Colors.blue),
        home: const JoinPage(),
      );
}

class JoinPage extends StatefulWidget {
  const JoinPage({super.key});

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  // Pre-fill with `flutter run --dart-define=BBB_JOIN_URL=https://...`.
  final _url = TextEditingController(text: const String.fromEnvironment('BBB_JOIN_URL'));
  final _log = <String>[];
  StreamSubscription<BbbMeetingEvent>? _events;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Optional warm-up of the native runtime; a failure shows up in the log below.
    BbbMeetingSdk.initialize().catchError((Object e) {
      if (mounted) _add('initialize failed: $e');
    });
    _events = BbbMeetingSdk.events.listen((event) => _add(switch (event) {
          BbbJoinedEvent() => 'joined',
          BbbLeftEvent(info: final info) => 'left: $info',
          BbbErrorEvent(message: final message) => 'error: $message',
        }));
  }

  @override
  void dispose() {
    _events?.cancel();
    _url.dispose();
    super.dispose();
  }

  void _add(String line) => setState(() => _log.insert(0, line));

  Future<void> _join() async {
    setState(() => _busy = true);
    try {
      // Screen sharing from iOS needs a Broadcast Upload Extension in the host app: pass
      // screensharePresenter: true only then (see the package README).
      final left = await BbbMeetingSdk.join(BbbJoinOptions(joinUrl: _url.text.trim()));
      _add('back in the app: ${left.reason.name}${left.detail == null ? '' : ' (${left.detail})'}');
    } catch (e) {
      _add('join failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('BigBlueButton meeting SDK')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _url,
                keyboardType: TextInputType.url,
                autocorrect: false,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Join URL',
                  hintText: 'https://<server>/html5client/join?sessionToken=...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _busy ? null : _join,
                child: Text(_busy ? 'In the meeting…' : 'Join meeting'),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _log.length,
                  itemBuilder: (_, i) => Text(_log[i], style: Theme.of(context).textTheme.bodySmall),
                ),
              ),
            ],
          ),
        ),
      );
}
