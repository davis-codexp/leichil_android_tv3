import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const LeichilTV());
}

class LeichilTV extends StatelessWidget {
  const LeichilTV({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leichil TV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      builder: (context, child) => FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: child ?? const SizedBox.shrink(),
      ),
      home: const LoginScreen(),
    );
  }
}
