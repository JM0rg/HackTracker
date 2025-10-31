import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'providers/team_providers.dart';
import 'providers/user_providers.dart';
import 'utils/persistence.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check cache version and clear if outdated
  await Persistence.checkCacheVersion();
  
  // Warm up shared preferences for simple hydration cache
  await SharedPreferences.getInstance();
  
  runApp(const ProviderScope(child: HackTrackerApp()));
}

class AppLifecycleRefresher extends StatefulWidget {
  final Widget child;
  const AppLifecycleRefresher({super.key, required this.child});
  @override
  State<AppLifecycleRefresher> createState() => _AppLifecycleRefresherState();
}

class _AppLifecycleRefresherState extends State<AppLifecycleRefresher>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // On resume, refresh key providers silently
      final container = ProviderScope.containerOf(context, listen: false);
      container.read(teamsProvider.notifier).refresh();
      container.read(currentUserProvider.notifier).refreshUser();
      // Roster providers will refresh when team view opens and reads them
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

