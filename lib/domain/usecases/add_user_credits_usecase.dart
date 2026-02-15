import '../../services/credit_service.dart';
import '../../utils/constants.dart';

/// Adds credits to a user's account after a successful bottle scan.
class AddUserCreditsUseCase {
  final CreditService _creditService = CreditService.instance;

  /// Awards [amount] credits to [userId]. Returns updated balance.
  Future<int> execute({
    required int userId,
    int amount = AppConstants.creditsPerBottle,
  }) async {
    return _creditService.addCredits(userId: userId, amount: amount);
  }

  /// Retrieves the current balance.
  Future<int> fetchBalance(int userId) async {
    return _creditService.fetchBalance(userId);
  }
}
