import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VerseOfDayScreen extends StatelessWidget {
  const VerseOfDayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Օրվա Խոսքը'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('verseOfDay')
            .doc('today')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Սխալ: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() ?? {};
          final text = data['text'] as String? ?? '';
          final reference = data['reference'] as String? ?? '';

          if (!snapshot.hasData ||
              snapshot.data?.exists != true ||
              text.isEmpty) {
            return const Center(
              child: Text('Դեռևս Օրվա Խոսք ավելացված չէ։'),
            );
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (reference.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      reference,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
