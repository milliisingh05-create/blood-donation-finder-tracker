import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../data/leaderboard_repository.dart';

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository();
});

class LeaderboardCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setCategory(String category) {
    state = category;
  }
}

final leaderboardCategoryProvider =
    NotifierProvider<LeaderboardCategoryNotifier, String>(() {
  return LeaderboardCategoryNotifier();
});

final leaderboardStreamProvider = StreamProvider.autoDispose<List<UserProfile>>((ref) {
  final repo = ref.watch(leaderboardRepositoryProvider);
  final category = ref.watch(leaderboardCategoryProvider);
  return repo.watchLeaderboard(category: category);
});
