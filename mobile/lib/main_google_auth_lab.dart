import 'package:flutter/material.dart';

import 'screens/cardverse_account_lab_screen.dart';
import 'ui/zync_design.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GoogleAuthLabApp());
}

class GoogleAuthLabApp extends StatelessWidget {
  const GoogleAuthLabApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Zync Google Auth Lab',
        theme: ZyncTheme.light(),
        home: const CardverseAccountLabScreen(),
      );
}
