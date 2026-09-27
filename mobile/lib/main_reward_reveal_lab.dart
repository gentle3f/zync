import 'package:flutter/material.dart';

import 'screens/reward_reveal_test_screen.dart';
import 'ui/zync_design.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RewardRevealLabApp());
}

class RewardRevealLabApp extends StatelessWidget {
  const RewardRevealLabApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Zync Reward Reveal Test',
        theme: ZyncTheme.light(),
        home: const RewardRevealTestScreen(),
      );
}
