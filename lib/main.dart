import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'screens/home_screen.dart';

void main() async {
  // Đảm bảo Flutter Binding được khởi tạo trước khi gọi async native code
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Supabase Client trước runApp
  await SupabaseService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
