import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Book_Add.dart'; // ✅ ADD THIS

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ijxixkrjiirfproppyqp.supabase.co',
    anonKey: 'sb_publishable_mN8KkS_WtjyipuOrawWhqw_d50Is3yT',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MeTyme',

      // ✅ default page
      initialRoute: '/',

      routes: {'/': (context) => const BookAddPage()},
    );
  }
}
