import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:readora/utils/colors.dart';

class AiAgentPanel extends StatefulWidget {
  final String? initialText;
  const AiAgentPanel({super.key, this.initialText});

  @override
  State<AiAgentPanel> createState() => _AiAgentPanelState();
}

class _AiAgentPanelState extends State<AiAgentPanel> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

final String _apiKey = '';

  @override
  void initState() {
    super.initState();
    _messages.add(
        {'role': 'model', 'text': 'Hello! I am your AI reading assistant.'});
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _textController.text = widget.initialText!;
    }
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      List<Map<String, dynamic>> contents = [];
      for (var msg in _messages) {
        if (msg['role'] == 'user' || msg['role'] == 'model') {
          contents.add({
            'role': msg['role'],
            'parts': [
              {'text': msg['text']}
            ]
          });
        }
      }

      final response = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': contents,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() {
          _messages.add({'role': 'model', 'text': reply});
          _isLoading = false;
        });
      } else {
        setState(() {
          _messages.add({
            'role': 'model',
            'text': 'Error: ${response.statusCode} - ${response.body}'
          });
          _isLoading = false;
        });
      }
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({'role': 'model', 'text': 'Network Error: $e'});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColor.clickedbutton,
            Colors.cyanAccent.withValues(alpha: 0.7),
            Colors.purpleAccent.withValues(alpha: 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.25, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColor.clickedbutton.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(-4, 0),
          ),
          BoxShadow(
            color: Colors.purpleAccent.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 2, left: 2, right: 2),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              left: 16,
              right: 16,
              top: 14,
            ),
            decoration: BoxDecoration(
              color: AppColor.bgcolor.withValues(alpha: 0.75),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top handle pill
                Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // Title Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          AppColor.clickedbutton,
                          Colors.cyanAccent,
                        ],
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'AI Reading Assistant',
                      style: TextStyle(
                        color: AppColor.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 10),

                // Chat Messages List
                Flexible(
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                          ),
                          decoration: BoxDecoration(
                            gradient: isUser
                                ? const LinearGradient(
                                    colors: [
                                      AppColor.clickedbutton,
                                      Color(0xFF8A2BE2),
                                    ],
                                  )
                                : null,
                            color: isUser
                                ? null
                                : AppColor.cardcolor.withValues(alpha: 0.65),
                            border: Border.all(
                              color: isUser
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : Colors.white.withValues(alpha: 0.12),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(16).copyWith(
                              bottomRight: isUser
                                  ? const Radius.circular(2)
                                  : const Radius.circular(16),
                              bottomLeft: isUser
                                  ? const Radius.circular(16)
                                  : const Radius.circular(2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Text(
                            msg['text']!,
                            style: const TextStyle(
                              color: AppColor.white,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColor.clickedbutton,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Input Bar with Gradient Border
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: LinearGradient(
                      colors: [
                        AppColor.clickedbutton.withValues(alpha: 0.6),
                        Colors.cyanAccent.withValues(alpha: 0.4),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.clickedbutton.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(1.5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColor.cardcolor.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            style: const TextStyle(
                              color: AppColor.white,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ask AI assistant...',
                              hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColor.clickedbutton,
                                  Colors.cyanAccent,
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
