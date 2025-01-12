import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'features/auth/login_screen.dart';
import 'features/spaces/spaces_list_screen.dart';
import 'features/spaces/spaces_details_screen.dart';
import 'features/spaces/user_reservations_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App de Aluguel de Espaços',
      theme: ThemeData(
        primaryColor: const Color(0xFF5F6F52),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            final user = snapshot.data!;
            final userId = user.uid;
            final userName = user.displayName ?? 'Usuário';

            return SpacesListScreen(
              onSpaceDetails: (spaceData, docId) {
                Navigator.pushNamed(
                  context,
                  '/spaceDetails',
                  arguments: {
                    'spaceData': spaceData,
                    'docId': docId,
                    'userId': userId,
                    'userName': userName,
                  },
                );
              },
              onViewReservations: () {
                Navigator.pushNamed(
                  context,
                  '/reservations',
                  arguments: {'userId': userId, 'userName': userName},
                );
              },
            );
          }

          return const AuthScreen();
        },
      ),
      routes: {
        '/login': (context) => const AuthScreen(),
        '/reservations': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ReservationsScreen(
            userId: args['userId'], 
            userName: args['userName'], 
          );
        },
        '/spaceDetails': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

          if (!args.containsKey('docId') || args['docId'] == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Erro')),
              body: const Center(
                child: Text('O ID do espaço não foi fornecido.'),
              ),
            );
          }

          return SpaceDetailsScreen(
            spaceId: args['docId'],
          );
        },
      },
    );
  }
}
