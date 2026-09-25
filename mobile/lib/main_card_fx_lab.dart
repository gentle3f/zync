import 'package:flutter/material.dart';

import 'screens/card_fx_lab_screen.dart';
import 'ui/zync_design.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CardFxLabApp());
}

class CardFxLabApp extends StatelessWidget {
  const CardFxLabApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Zync Card FX Lab',
        theme: ZyncTheme.light(),
        home: const CardFxLabScreen(),
      );
}
