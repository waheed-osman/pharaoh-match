import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'progress.dart';
import 'theme.dart';
import 'ui/menu_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Progress.init();
  runApp(const EgyptApp());
}

class EgyptApp extends StatelessWidget {
  const EgyptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ألغاز الفراعنة',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // الواجهة عربية من اليمين إلى اليسار
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const MenuScreen(),
    );
  }
}
