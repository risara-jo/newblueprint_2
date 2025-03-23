import 'package:flutter/material.dart';
import 'package:siri_wave/siri_wave.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceInputBar extends StatefulWidget {
  final void Function(String) onSubmit;

  const VoiceInputBar({super.key, required this.onSubmit});

  @override
  State<VoiceInputBar> createState() => _VoiceInputBarState();
}

class _VoiceInputBarState extends State<VoiceInputBar> {
  final TextEditingController _controller = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final IOS9SiriWaveformController _siriWaveController =
      IOS9SiriWaveformController();

  bool _isListening = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _hasText = _controller.text.trim().isNotEmpty;
      });
    });
  }

  void _handleSend() {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    widget.onSubmit(input);
    _controller.clear();
  }

  void _startVoiceInput() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() {
            _isListening = false;
            _siriWaveController.amplitude = 0.0;
          });
        }
      },
      onError: (error) {
        print("Speech Error: $error");
        setState(() {
          _isListening = false;
          _siriWaveController.amplitude = 0.0;
        });
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _siriWaveController.amplitude = 1.0;
      });

      _speech.listen(
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
          });
        },
      );
    } else {
      print("❌ Microphone not available");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isListening)
          SiriWaveform.ios9(
            controller: _siriWaveController,
            options: const IOS9SiriWaveformOptions(
              height: 80,
              width: 500,
              showSupportBar: true,
            ),
          ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: "Discribe your floor plan...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 59, 59, 59),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0056A4), Color(0xFF3E80D8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _hasText ? Icons.send : Icons.mic,
                    color: Colors.white,
                  ),
                  onPressed: _hasText ? _handleSend : _startVoiceInput,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
