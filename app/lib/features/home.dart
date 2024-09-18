import 'dart:developer';

import 'dart:io';

import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(
      id: "1",
      firstName: "GeminiUser",
      profileImage:
          "https://bgr.com/wp-content/uploads/2024/02/Google-Gemini.jpg?quality=82&strip=all&resize=1400,1400");
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          "Gemini 🚀",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: DashChat(
          inputOptions: InputOptions(trailing: [
            IconButton(
                onPressed: sendMediaMsg,
                icon: const Icon(
                  Icons.image,
                  color: Colors.white,
                ))
          ]),
          currentUser: currentUser,
          onSend: _sendMessage,
          messages: messages),
    );
  }

  void _sendMessage(ChatMessage msg) {
    setState(() {
      messages = [msg, ...messages];
    });
    try {
      String question = msg.text;
      List<Uint8List>? images;
      if (msg.medias?.isNotEmpty ?? false) {
        images = [
          File(msg.medias!.first.url).readAsBytesSync(),
        ];
      }
      gemini.streamGenerateContent(question, images: images).listen((event) {
        ChatMessage? lastMessage = messages.firstOrNull;
        if (lastMessage != null && lastMessage.user == geminiUser) {
          lastMessage = messages.removeAt(0);
          String response = event.content?.parts
                  ?.fold("", (prev, curr) => "$prev ${curr.text}") ??
              "";
          lastMessage.text += response;
          setState(() {
            messages = [lastMessage!, ...messages];
          });
        } else {
          String response = event.content?.parts?.fold(
                  "", (previous, current) => "$previous ${current.text}") ??
              "";
          ChatMessage chatMessage = ChatMessage(
              user: geminiUser, createdAt: DateTime.now(), text: response);
          setState(() {
            messages = [chatMessage, ...messages];
          });
        }
      });
    } catch (e) {
      log(e.toString());
    }
  }

  void sendMediaMsg() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
          user: currentUser,
          createdAt: DateTime.now(),
          text: 'Describe this picture?',
          medias: [
            ChatMedia(url: file.path, fileName: "", type: MediaType.image)
          ]);
      _sendMessage(chatMessage);
    }
  }
}
