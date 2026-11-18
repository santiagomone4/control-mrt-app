import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/project_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bloquear a orientación vertical preferente pero permitiendo rotación en tabletas
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Barra de estado de alto contraste
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: AppTheme.primaryDark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.primaryDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const MrtControlApp());
}

class MrtControlApp extends StatelessWidget {
  const MrtControlApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control MRT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.outdoorHighContrastTheme,
      home: const ProjectListScreen(),
    );
  }
}
