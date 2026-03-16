import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_finance_os/core/services/nova_service.dart';

class NovaTestScreen extends ConsumerStatefulWidget {
  const NovaTestScreen({super.key});

  @override
  ConsumerState<NovaTestScreen> createState() => _NovaTestScreenState();
}

class _NovaTestScreenState extends ConsumerState<NovaTestScreen> {
  final TextEditingController _controller = TextEditingController();
  String _response = "Ask Finance OS anything...";
  bool _isLoading = false;

  void _send() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _response = "Nova 2 Lite is thinking...";
    });

    final novaService = ref.read(novaServiceProvider);
    final result = await novaService.sendRawMessage(prompt: _controller.text);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _response = result['text'] ?? result['message'] ?? "No response";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nova 2 Lite - AWS Bedrock")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(_response, style: const TextStyle(fontSize: 16)),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Ask a financial question...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _isLoading ? null : _send,
                  icon: _isLoading 
                    ? const CircularProgressIndicator() 
                    : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
