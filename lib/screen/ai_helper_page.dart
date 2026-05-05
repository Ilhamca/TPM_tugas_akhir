import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tugas_akhir/theme/app_color.dart';

class AiHelperPage extends StatefulWidget {
  const AiHelperPage({super.key});

  @override
  State<AiHelperPage> createState() => _AiHelperPageState();
}

class _AiHelperPageState extends State<AiHelperPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  final List<String> _quickQuestions = [
    'Cuaca di Yogyakarta hari ini?',
    'Tips mengantar paket saat hujan?',
    'Berapa estimasi BBM Yogya ke Sleman?',
    'Cara merawat paket fragile?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    _controller.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final url = Uri.parse('http://192.168.18.106/gudang_pintar/api/gemini_proxy.php');

      final contents = _messages.map((m) => {
        'role': m['role'] == 'assistant' ? 'model' : 'user',
        'parts': [{'text': m['content']}]
      }).toList();

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': contents,
        }),
      );

    if (res.statusCode == 200) {
      final d = jsonDecode(res.body);
      final reply = d['candidates'][0]['content']['parts'][0]['text'];
      setState(() => _messages.add({'role': 'assistant', 'content': reply}));
    } else {
      setState(() => _messages.add({'role': 'assistant', 'content': 'Error ${res.statusCode}: ${res.body}'}));
    }
  } catch (e) {
    setState(() => _messages.add({'role': 'assistant', 'content': 'Tidak dapat terhubung ke AI. Cek koneksi internet.'}));
  } finally {
    if (mounted) setState(() => _isLoading = false);
    _scrollToBottom();
  }
}

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.smart_toy, color: Colors.purple, size: 28)),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Helper', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Asisten Kurir Pintar', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          // Quick questions
          if (_messages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8, runSpacing: 8,
                children: _quickQuestions.map((q) => ActionChip(
                  label: Text(q, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _sendMessage(q),
                  backgroundColor: Colors.purple.shade50,
                )).toList(),
              ),
            ),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _messages.length) {
                  return const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 40, height: 20, child: LinearProgressIndicator())));
                }
                final m = _messages[i];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 6)],
                    ),
                    child: Text(m['content']!, style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 14)),
                  ),
                );
              },
            ),
          ),

          // Input area
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Tanya sesuatu...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () => _sendMessage(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}