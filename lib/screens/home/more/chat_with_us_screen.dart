import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:pipze/constants/color.dart';

import '../../../controllers/chat_with_us_controller.dart';

class ChatWithUsScreen extends StatelessWidget {
  const ChatWithUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatController());
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Chat with us',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: _buildChatBody(controller, isTablet),
          ),

          // Input Area
          _buildMessageInput(controller, isTablet),
        ],
      ),
    );
  }

  Widget _buildChatBody(ChatController controller, bool isTablet) {
    return Obx(() => ListView.builder(
      controller: controller.scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 32.0 : 16.0,
        vertical: 16.0,
      ),
      itemCount: controller.messages.length +
          (controller.showLanguageSelection.value ? 1 : 0) +
          (controller.isTyping.value ? 1 : 0),
      itemBuilder: (context, index) {
        // Language selection card
        if (controller.showLanguageSelection.value &&
            index == controller.messages.length) {
          return _buildLanguageSelectionCard(controller);
        }

        // Typing indicator
        if (controller.isTyping.value &&
            index == controller.messages.length +
                (controller.showLanguageSelection.value ? 1 : 0)) {
          return _buildTypingIndicator();
        }

        // Regular message
        final message = controller.messages[index];
        return _buildMessageBubble(message, isTablet);
      },
    ));
  }

  Widget _buildMessageBubble(ChatMessage message, bool isTablet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            // Bot avatar
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF7B2CBF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],

          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!message.isUser && message.sender != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 8),
                    child: Text(
                      message.sender!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? const Color(0xFF7B2CBF)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: message.isUser ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (message.isUser) ...[
            const SizedBox(width: 8),
            // User avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.grey[600],
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageSelectionCard(ChatController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Please select the department where you want to get assistance.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),

                // Language options
                ...controller.languages.map((language) =>
                    GestureDetector(
                      onTap: () => controller.selectLanguage(language),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          "${language.number}. ${language.name}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7B2CBF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 40),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -4 * value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput(ChatController controller, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 32.0 : 16.0,
        vertical: 16.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: controller.messageController,
                  decoration: InputDecoration(
                    hintText: 'Ask me anything...',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 15,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.mic,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          onPressed: controller.openVoiceInput,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.attach_file,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          onPressed: controller.openAttachment,
                        ),
                      ],
                    ),
                  ),
                  onSubmitted: controller.sendMessage,
                  textInputAction: TextInputAction.send,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Send button
            GestureDetector(
              onTap: () => controller.sendMessage(controller.messageController.text),
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF7B2CBF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
