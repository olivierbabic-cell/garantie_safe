// lib/features/premium/premium_exception.dart

/// Exception thrown when user tries to create more items than allowed in free tier
class FreemiumLimitReachedException implements Exception {
  final int currentCount;
  final int maxFreeItems;

  FreemiumLimitReachedException({
    required this.currentCount,
    required this.maxFreeItems,
  });

  @override
  String toString() =>
      'FreemiumLimitReachedException: Cannot create more than $maxFreeItems items in free version (current: $currentCount)';
}
