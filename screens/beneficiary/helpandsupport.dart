import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:twc/utils/accessibility_manager.dart';
import 'package:google_mlkit_smart_reply/google_mlkit_smart_reply.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      "text": "Hello! I am here to assist you.\nHow can I help you?",
      "isUser": false,
    },
  ];
  final SmartReply _smartReply = SmartReply();
  List<String> _suggestedReplies = [];

  @override
  void initState() {
    super.initState();
    _smartReply.addMessageToConversationFromRemoteUser("Hello! I am here to assist you.\nHow can I help you?", DateTime.now().millisecondsSinceEpoch, "bot");
    _updateSmartReplies();
  }

  @override
  void dispose() {
    _smartReply.close();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _updateSmartReplies() async {
    try {
      final response = await _smartReply.suggestReplies();
      if (response.status == SmartReplySuggestionResultStatus.success) {
        setState(() {
          _suggestedReplies = response.suggestions;
        });
      } else {
        setState(() {
          _suggestedReplies = [];
        });
      }
    } catch (e) {
      debugPrint("Smart Reply Error: $e");
    }
  }

  void _handleSendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    String userText = _messageController.text.trim();
    setState(() {
      _messages.add({"text": userText, "isUser": true});
      _suggestedReplies.clear();
    });

    _smartReply.addMessageToConversationFromLocalUser(userText, DateTime.now().millisecondsSinceEpoch);

    String userQuery = userText.toLowerCase();
    _messageController.clear();

    // Simulating AI response delay
    Future.delayed(const Duration(milliseconds: 800), () {
      _simulateAIResponse(userQuery);
    });
  }

  void _simulateAIResponse(String query) {
    String botResponse =
        "I'm sorry, I didn't quite get that. You can ask me about registration, password reset, updating your profile, requesting a volunteer, our services, canceling a request, viewing schedule, logging out, or contact support.";

    query = query.toLowerCase();

    if (query.contains("hello") || query.contains("hi") || query.contains("hey")) {
      botResponse = "Hi there! I'm the Together We Can assistant. How can I help you today?";
    } else if (query.contains("register") || query.contains("create an account") || query.contains("sign up")) {
      botResponse = "To register, click on 'Start' and then 'Register' on the Login Page. You can choose to register as a Beneficiary or a Volunteer, then fill in your details.";
    } else if (query.contains("forgot my password") || query.contains("reset my password") || query.contains("password")) {
      botResponse = "On the Login screen, click on 'Forgot Password?'. Enter your email address and we will send you a link to reset your password.";
    } else if (query.contains("update my profile") || query.contains("change my email") || query.contains("change my phone number") || query.contains("phone number") || query.contains("update email")) {
      botResponse = "Go to the Profile tab, access your profile settings, and update your email or phone number. Remember to save your changes!";
    } else if (query.contains("request a volunteer") || query.contains("need a volunteer")) {
      botResponse = "Log in as a beneficiary, go to your dashboard, and click on 'Request Volunteer'. Fill in the required details and submit.";
    } else if (query.contains("services do you offer") || query.contains("what services") || query.contains("your services")) {
      botResponse = "We offer digital coordination for volunteer transportation, environmental sustainability initiatives, and accessibility assistance.";
    } else if (query.contains("cancel a request") || query.contains("cancel request")) {
      botResponse = "Go to your Dashboard, view 'My Requests', select the request you wish to cancel, and click 'Cancel Request'.";
    } else if (query.contains("view my volunteer schedule") || query.contains("my schedule") || query.contains("accepted requests") || query.contains("volunteer schedule")) {
      botResponse = "Log in as a volunteer, navigate to your Dashboard, and click on 'My Schedule' or 'Accepted Requests' to see your upcoming tasks.";
    } else if (query.contains("log out") || query.contains("logout") || query.contains("sign out")) {
      botResponse = "Go to your Profile or Settings tab and click on the 'Logout' button.";
    } else if (query.contains("contact support") || query.contains("admin") || query.contains("email")) {
      botResponse = "You can contact our support team directly via Gmail at:\n\ntwcteam.omdis@gmail.com";
    } else if (query.contains("faq") || query.contains("about")) {
      botResponse = "Together We Can is a digital platform for volunteer coordination. You can ask me specific questions like 'How do I register?' or 'How do I reset my password?'.";
    } else if (query.contains("accessibility")) {
      botResponse = "Our app ensures accessibility by providing AI-driven matching, digital coordination, and optimized transportation for those with limited mobility.";
    } else if (query.contains("vision 2040")) {
      botResponse = "We are aligned with Oman Vision 2040's commitment to environmentally responsible digital solutions.";
    }

    setState(() {
      _messages.add({"text": botResponse, "isUser": false});
    });
    
    _smartReply.addMessageToConversationFromRemoteUser(botResponse, DateTime.now().millisecondsSinceEpoch, "bot");
    _updateSmartReplies();

    AccessibilityManager.speak(botResponse);
  }

  void _showAccessibilityOptions() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Accessibility Options"),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text("Enable Text-to-Speech"),
                    value: AccessibilityManager.isTtsEnabled,
                    activeColor: const Color(0xFF9EA4FF),
                    onChanged: (val) {
                      setDialogState(() {
                        AccessibilityManager.toggleTts(val);
                      });
                    },
                  ),
                  const Divider(),
                  const Text("Adjust Font Size", style: TextStyle(fontWeight: FontWeight.bold)),
                  ValueListenableBuilder<double>(
                    valueListenable: AccessibilityManager.fontScaleNotifier,
                    builder: (context, scale, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 32),
                            onPressed: () => AccessibilityManager.decreaseFontSize(),
                          ),
                          Text("${(scale * 100).toInt()}%", style: const TextStyle(fontSize: 18)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 32),
                            onPressed: () => AccessibilityManager.increaseFontSize(),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _quickActionBtn(String title, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB4C2FF),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onTap ?? () {
            _messageController.text = title;
            _handleSendMessage();
          },
          child: Text(title, style: const TextStyle(color: Color(0xFF2E3B71))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color themePurple = Color(0xFF9EA4FF);
    const Color botBgColor = Color(0xFFF3E5F5);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF0FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.network(
              'https://res.cloudinary.com/dv2x9fveq/image/upload/v1765480794/IMG_4695_k6exsh.png',
              width: 40,
              errorBuilder: (context, e, s) => const Icon(Icons.favorite, color: themePurple),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: botBgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: themePurple,
                        child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Chatbot",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E3B71),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _quickActionBtn("Accessibility options", onTap: _showAccessibilityOptions),
                  _quickActionBtn("FAQ"),
                  _quickActionBtn("Contact support"),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        bool isUser = _messages[index]["isUser"];
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isUser ? themePurple : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              _messages[index]["text"],
                              style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_suggestedReplies.isNotEmpty)
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _suggestedReplies.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                            child: ActionChip(
                              label: Text(_suggestedReplies[index]),
                              onPressed: () {
                                _messageController.text = _suggestedReplies[index];
                                _handleSendMessage();
                              },
                              backgroundColor: Colors.white,
                              side: BorderSide(color: themePurple),
                            ),
                          );
                        },
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: "Type a message...",
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _handleSendMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themePurple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Icon(Icons.send, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}