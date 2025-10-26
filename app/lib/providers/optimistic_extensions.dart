import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/messenger.dart';

/// Extension for safe optimistic mutations with rollback support
/// 
/// This pattern prevents race conditions by using a rollback function
/// that operates on the current state, rather than reverting to a 
/// previous snapshot.
extension OptimisticMutation<T> on AsyncNotifier<T> {
  /// Perform an optimistic mutation with automatic rollback on error
  /// 
  /// Example:
  /// ```dart
  /// await mutate<Player>(
  ///   optimisticUpdate: (current) => [...current, tempPlayer],
  ///   apiCall: () => api.createPlayer(name: name),
  ///   applyResult: (current, realPlayer) => current.map(
  ///     (p) => p.id == tempPlayer.id ? realPlayer : p
  ///   ).toList(),
  ///   rollback: (current) => current.where((p) => p.id != tempPlayer.id).toList(),
  ///   successMessage: 'Player added!',
  /// );
  /// ```
  Future<R?> mutate<R>({
    /// Function to apply the optimistic update to current state
    required T Function(T current) optimisticUpdate,
    
    /// The API call to execute
    required Future<R> Function() apiCall,
    
    /// Function to apply the real API result to current state
    required T Function(T current, R result) applyResult,
    
    /// Function to undo the optimistic update from current state
    /// This is critical for handling concurrent mutations safely
    required T Function(T current) rollback,
    
    /// Optional success message to show as toast
    String? successMessage,
    
    /// Optional error message builder
    String Function(dynamic error)? errorMessage,
  }) async {
    // Guard clause: Only mutate if state is data (not loading/error)
    if (state is! AsyncData<T>) {
      return null;
    }

    // 1. Apply optimistic update to current state
    state = AsyncValue.data(optimisticUpdate(state.requireValue));

    try {
      // 2. Execute API call
      final result = await apiCall();
      
      // 3. Apply real result to current state (may have changed since step 1)
      state = AsyncValue.data(applyResult(state.requireValue, result));
      
      // 4. Show success message
      if (successMessage != null) {
        showSuccessToast(successMessage);
      }
      
      return result;
    } catch (e) {
      // 5. Rollback from current state (not previous snapshot)
      state = AsyncValue.data(rollback(state.requireValue));
      
      // 6. Show error message
      final errorMsg = errorMessage?.call(e) ?? 'Operation failed';
      showErrorToast(errorMsg);
      
      // Don't rethrow - error is handled via toast
      return null;
    }
  }
}

/// Extension for FamilyAsyncNotifier (same implementation as AsyncNotifier)
extension OptimisticMutationFamily<T, Arg> on FamilyAsyncNotifier<T, Arg> {
  /// Perform an optimistic mutation with automatic rollback on error
  /// 
  /// Same as OptimisticMutation but for family notifiers.
  Future<R?> mutate<R>({
    required T Function(T current) optimisticUpdate,
    required Future<R> Function() apiCall,
    required T Function(T current, R result) applyResult,
    required T Function(T current) rollback,
    String? successMessage,
    String Function(dynamic error)? errorMessage,
  }) async {
    // Guard clause: Only mutate if state is data (not loading/error)
    if (state is! AsyncData<T>) {
      return null;
    }

    // 1. Apply optimistic update to current state
    state = AsyncValue.data(optimisticUpdate(state.requireValue));

    try {
      // 2. Execute API call
      final result = await apiCall();
      
      // 3. Apply real result to current state (may have changed since step 1)
      state = AsyncValue.data(applyResult(state.requireValue, result));
      
      // 4. Show success message
      if (successMessage != null) {
        showSuccessToast(successMessage);
      }
      
      return result;
    } catch (e) {
      // 5. Rollback from current state (not previous snapshot)
      state = AsyncValue.data(rollback(state.requireValue));
      
      // 6. Show error message
      final errorMsg = errorMessage?.call(e) ?? 'Operation failed';
      showErrorToast(errorMsg);
      
      // Don't rethrow - error is handled via toast
      return null;
    }
  }
}

