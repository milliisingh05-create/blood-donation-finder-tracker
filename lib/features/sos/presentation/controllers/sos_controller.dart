import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/sos_repository.dart';
import '../../domain/models/sos_broadcast.dart';

final sosRepositoryProvider = Provider<SosRepository>((ref) {
  final repo = SosRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final activeSosBroadcastProvider = StreamProvider<SosBroadcast?>((ref) {
  final repo = ref.watch(sosRepositoryProvider);
  return repo.watchActiveBroadcast();
});
