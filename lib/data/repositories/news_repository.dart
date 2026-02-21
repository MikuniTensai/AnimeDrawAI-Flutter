import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_model.dart';

class NewsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _newsCollection => _firestore.collection("news");

  Stream<List<NewsItem>> getNewsStream() {
    return _newsCollection.orderBy("date", descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return NewsItem.fromJson(data).copyWith(id: doc.id);
      }).toList();
    });
  }

  Future<void> seedSampleData() async {
    final snapshot = await _newsCollection.limit(1).get();
    if (snapshot.docs.isEmpty) {
      await _newsCollection.add({
        "type": "event",
        "title": "Generate Like Contest",
        "description":
            "Create the most liked generation and win \$1! Join the community contest now.",
        "date": FieldValue.serverTimestamp(),
        "imageUrl": "https://placehold.co/600x400/png",
        "actionUrl": "https://discord.gg/animedrawai",
      });

      await _newsCollection.add({
        "type": "update",
        "title": "Patch 2.0.0 (Flutter)",
        "description":
            "Welcome to our brand new Flutter version! Smoother, faster, and more features.",
        "date": FieldValue.serverTimestamp(),
        "version": "2.0.0",
      });
    }
  }
}
