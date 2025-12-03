import 'dart:async';
import 'dart:math';

import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/domain/entities/chat/message_entity.dart';
import 'package:bulusalim/domain/repositories/chat_repository.dart';
import 'package:bulusalim/domain/repositories/event_repository.dart';
import 'package:bulusalim/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Botların kuracağı cümleler
const List<String> _botMessages = [
  "Web'den selamlar!",
  "ChatRepository test ediliyor.",
  "Hız testi 1-2-3.",
  "Chrome üzerinden bağlanıyorum.",
  "Event çok iyiymiş.",
  "Herkes burada mı?",
  "Veriler akıyor...",
];

void main() async {
  const eventID = String.fromEnvironment('EVENT_ID');

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Chrome (Web) Emülatör Ayarı
  if (kDebugMode) {
    try {
      // Auth cache sorununu önlemek için persistence kapatıyoruz
      await FirebaseAuth.instance.setPersistence(Persistence.NONE);

      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
    } catch (e) {
      print('Emülatör zaten aktif olabilir: $e');
    }

    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  await getItSetup();

  runApp(const BotApp());

  // Arayüz açıldıktan sonra saldırıyı başlat
  _startAttack(eventID);
}

class BotApp extends StatelessWidget {
  const BotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.android, color: Colors.green, size: 64),
              const SizedBox(height: 20),
              const Text(
                "BOT ÇALIŞIYOR",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Terminalden logları izle...",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              const CircularProgressIndicator(color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _startAttack(String eventID) async {
  if (eventID.isEmpty) {
    print('❌ HATA: Event ID girilmemiş!');
    return;
  }

  final eventRepo = getIt<EventRepository>();
  final chatRepo = getIt<ChatRepository>(); // Senin Repository'in

  // Eventi bul
  print('🔍 Event aranıyor: $eventID');
  final event = await eventRepo.getEvent(eventID);

  if (event == null) {
    print('❌ Event yok!');
    return;
  }

  final List<dynamic> participants = event.participants;
  if (participants.isEmpty) {
    print('❌ Katılımcı yok!');
    return;
  }

  print('✅ HEDEF BULUNDU. SALDIRI BAŞLIYOR...');
  print('-------------------------------------');

  final random = Random();

  // Sonsuz Saldırı Döngüsü
  while (true) {
    // 1 ile 3 saniye arası rastgele bekle
    await Future.delayed(Duration(milliseconds: 1000 + random.nextInt(2000)));

    final senderId = participants[random.nextInt(participants.length)];
    final content = _botMessages[random.nextInt(_botMessages.length)];

    try {
      final msg = MessageEntity(
        senderID: senderId.toString(),
        content: content,
        createdAt: DateTime.now(),
      );

      // Senin kodunla gönderim yapılıyor
      await chatRepo.sendMessage(eventID, msg);

      // Saat bilgisi
      final time =
          "${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}";
      print('[$time] 📤 Mesaj Atıldı ($senderId): $content');
    } catch (e) {
      print('❌ Hata oluştu: $e');
    }
  }
}
