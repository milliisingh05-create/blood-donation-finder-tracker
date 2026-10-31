import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/requests_repository.dart';
import '../../domain/models/donation_request.dart';

final requestsRepositoryProvider = Provider<RequestsRepository>((ref) {
  return RequestsRepository();
});

final openRequestsProvider = StreamProvider<List<DonationRequest>>((ref) {
  final repository = ref.watch(requestsRepositoryProvider);
  return repository.watchOpenRequests();
});

final receivedRequestsProvider = StreamProvider<List<DonationRequest>>((ref) {
  final repository = ref.watch(requestsRepositoryProvider);
  return repository.watchReceivedRequests('current_user');
});

final myRequestsProvider = StreamProvider<List<DonationRequest>>((ref) {
  final repository = ref.watch(requestsRepositoryProvider);
  return repository.watchMyRequests('current_user');
});

final singleRequestProvider = StreamProvider.family<DonationRequest?, String>((ref, requestId) {
  final repository = ref.watch(requestsRepositoryProvider);
  return repository.watchRequestById(requestId);
});
