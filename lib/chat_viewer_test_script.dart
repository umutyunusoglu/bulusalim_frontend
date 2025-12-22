// Proje importları
import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/domain/entities/chat/message_entity.dart';
import 'package:bulusalim/domain/repositories/chat_repository.dart';
import 'package:bulusalim/domain/repositories/event_repository.dart';
import 'package:bulusalim/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Firebase importları
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() async {
  const eventID = String.fromEnvironment('EVENT_ID');

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Emülatör Ayarları (Web İçin)
  if (kDebugMode) {
    try {
      await FirebaseAuth.instance.setPersistence(Persistence.NONE);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
    } on Exception catch (e) {
      print('Emülatör bağlantı uyarısı: $e');
    }

    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  await getItSetup();

  runApp(const ChatMonitorApp(eventID: eventID));
}

class ChatMonitorApp extends StatelessWidget {
  const ChatMonitorApp({required this.eventID, super.key});
  final String eventID;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        cardColor: const Color(0xFF2C2C2C),
      ),
      home: ChatScreen(eventID: eventID),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({required this.eventID, super.key});
  final String eventID;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatRepository _chatRepo;
  String? _eventTitle;

  @override
  void initState() {
    super.initState();
    _chatRepo = getIt<ChatRepository>();
    _loadEventInfo();
  }

  Future<void> _loadEventInfo() async {
    final eventRepo = getIt<EventRepository>();
    final event = await eventRepo.getEvent(widget.eventID);
    setState(() {
      _eventTitle = event?.name ?? 'Bilinmeyen Event';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.eventID.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('❌ Event ID girilmedi!')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _eventTitle ?? 'Yükleniyor...',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'ID: ${widget.eventID}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        actions: const [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: Text(
                'Canlı İzleme Modu 🔴',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<MessageEntity>>(
        // İŞTE BURASI: Senin Repository'nin Stream'i UI'ya bağlanıyor
        stream: _chatRepo.getChatMessagesStream(widget.eventID),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final messages = snapshot.data ?? [];

          if (messages.isEmpty) {
            return const Center(
              child: Text(
                'Henüz mesaj yok.\nSimülasyon scriptini çalıştır!',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final msg = messages[index];
              return _buildMessageCard(msg);
            },
          );
        },
      ),
    );
  }

  Widget _buildMessageCard(MessageEntity msg) {
    // Repository descending getirdiği için en üstteki en yenidir.
    final timeStr =
        "${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}:${msg.createdAt.second.toString().padLeft(2, '0')}";

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueGrey,
          child: Text(
            msg.senderID.substring(0, 2).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              msg.senderID,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.blueAccent,
              ),
            ),
            Text(
              timeStr,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            msg.content,
            style: const TextStyle(fontSize: 15, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
