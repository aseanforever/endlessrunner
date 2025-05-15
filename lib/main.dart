import 'package:endlessrunner/widgets/loginscreen.dart';
import 'package:endlessrunner/widgets/main_menu_wrapper.dart';
import 'package:endlessrunner/widgets/registerscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DinoRunApp());
}

class DinoRunApp extends StatelessWidget {
  const DinoRunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EndlessRunner',
      theme: ThemeData(
        fontFamily: 'Audio wide',
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final User? user = snapshot.data;
            if (user != null) {
              return const MainMenuWrapper();
            } else {
              return LoginScreen();
            }
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
      routes: {
        '/register': (context) => RegisterScreen(),
        '/main_menu': (context) => const MainMenuWrapper(),
        '/login': (context) => LoginScreen(),
      },
    );
  }
}
