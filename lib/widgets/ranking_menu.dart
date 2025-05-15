import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RankingsMenu extends StatelessWidget {
  static const id = 'RankingsMenu';

  const RankingsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.black.withAlpha(100),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            height: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Rankings',
                  style: TextStyle(fontSize: 40, color: Colors.white),
                ),
                const Expanded(child: RankingsList()),
                ElevatedButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RankingsList extends StatelessWidget {
  const RankingsList({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PlayerRank>>(
      future: fetchRankings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(
              child: Text('Failed to load rankings', style: TextStyle(color: Colors.white)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('No rankings available', style: TextStyle(color: Colors.white)));
        } else {
          final ranks = snapshot.data!;
          return ListView.builder(
            itemCount: ranks.length,
            itemBuilder: (context, index) {
              final playerRank = ranks[index];
              final formattedDate =
              DateFormat('yyyy-MM-dd HH:mm').format(playerRank.datetime);

              return ListTile(
                title: Text(
                  '${playerRank.rank}. ${playerRank.name}',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Achieved on: $formattedDate',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: Text(
                  playerRank.highScore.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          );
        }
      },
    );
  }

  Future<List<PlayerRank>> fetchRankings() async {
    try {

      final playersQuery = await FirebaseFirestore.instance
          .collection('players')
          .orderBy('highScore', descending: true)
          .orderBy('datetime', descending: false)
          .limit(10)
          .get();

      List<PlayerRank> ranks = [];
      int rank = 1;

      for (var doc in playersQuery.docs) {
        final uid = doc['uid'];
        final highScore = doc['highScore'];
        final timestamp = (doc['datetime'] as Timestamp).toDate();

        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final displayName = userDoc.exists ? userDoc['display_name'] ?? 'Unknown' : 'Unknown';

        ranks.add(PlayerRank(
          rank: rank++,
          name: displayName,
          highScore: highScore,
          datetime: timestamp,
        ));
      }

      return ranks;
    } catch (e) {
      print('Error fetching rankings: $e');
      return [];
    }
  }
}

class PlayerRank {
  final int rank;
  final String name;
  final int highScore;
  final DateTime datetime;

  PlayerRank({
    required this.rank,
    required this.name,
    required this.highScore,
    required this.datetime,
  });
}