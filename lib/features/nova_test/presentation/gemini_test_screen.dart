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
  String _response = "Ask something...";
  bool _isLoading = false;

  void _send() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _response = "Thinking (High Level)...";
    });

    final novaService = ref.read(novaServiceProvider);
    // Use sendRawMessage to test the user's specific logic
    final result = await novaService.sendRawMessage(_controller.text);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _response = result ?? "No response";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nova 3 Pro Thinking")),
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
                      hintText: "Enter a complex math or logic problem",
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
