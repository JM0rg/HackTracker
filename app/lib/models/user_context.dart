/// User Context model for dynamic UI rendering
class UserContext {
  final bool hasPersonalContext;
  final bool hasManagedContext;

  UserContext({
    required this.hasPersonalContext,
    required this.hasManagedContext,
  });

  factory UserContext.fromJson(Map<String, dynamic> json) {
    return UserContext(
      hasPersonalContext: json['has_personal_context'] as bool,
      hasManagedContext: json['has_managed_context'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_personal_context': hasPersonalContext,
      'has_managed_context': hasManagedContext,
    };
  }

  /// Determine which view to show based on team context
  /// - Both contexts: Show both views (tabs visible)
  /// - Personal only: Show player view only (tabs hidden)
  /// - Managed only: Show team view only (tabs hidden)
  /// - Neither: Show welcome screen
  bool get shouldShowTabs => hasPersonalContext && hasManagedContext;
  bool get shouldShowPlayerViewOnly => hasPersonalContext && !hasManagedContext;
  bool get shouldShowTeamViewOnly => !hasPersonalContext && hasManagedContext;
  bool get shouldShowWelcome => !hasPersonalContext && !hasManagedContext;
}

