part of 'unlock_premium_category_cubit.dart';

sealed class UnlockPremiumCategoryState {
  const UnlockPremiumCategoryState();
}

final class UnlockPremiumCategoryInitial extends UnlockPremiumCategoryState {
  const UnlockPremiumCategoryInitial();
}

final class UnlockPremiumCategoryInProgress extends UnlockPremiumCategoryState {
  const UnlockPremiumCategoryInProgress();
}

final class UnlockPremiumCategorySuccess extends UnlockPremiumCategoryState {
  const UnlockPremiumCategorySuccess();
}

final class UnlockPremiumCategoryFailure extends UnlockPremiumCategoryState {
  const UnlockPremiumCategoryFailure(this.errorMessage);

  final String errorMessage;
}
