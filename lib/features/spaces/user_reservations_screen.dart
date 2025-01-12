import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationsScreen extends StatefulWidget {
  final String userId; 
  final String userName; 

  const ReservationsScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;


  Future<void> cancelReservation(String reservationId, String spaceId, String horario) async {
    try {      await firestore.collection('reservations').doc(reservationId).delete();

      final spaceDoc = await firestore.collection('spaces').doc(spaceId).get();
      if (spaceDoc.exists) {
        final spaceData = spaceDoc.data() as Map<String, dynamic>;
        final ocupados = List<Map<String, dynamic>>.from(spaceData['availability']['ocupados']);
        final livres = List<Map<String, dynamic>>.from(spaceData['availability']['livres']);

        final horarioParts = horario.split(' - ');
        ocupados.removeWhere((h) => h['inicio'] == horarioParts[0] && h['fim'] == horarioParts[1]);
        livres.add({'inicio': horarioParts[0], 'fim': horarioParts[1]});

        await firestore.collection('spaces').doc(spaceId).update({
          'availability.ocupados': ocupados,
          'availability.livres': livres,
          'status': 'ativo',
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reserva cancelada com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao cancelar reserva.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Reservas'),
        backgroundColor: const Color(0xFF5F6F52),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('reservations')
            .where('userId', isEqualTo: widget.userId) 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Erro ao carregar as reservas.'),
            );
          }

          final reservations = snapshot.data?.docs ?? [];

          if (reservations.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma reserva encontrada.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservationData =
                  reservations[index].data() as Map<String, dynamic>;
              final reservationId = reservations[index].id;

              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListTile(
                  title: Text(
                    'Horário: ${reservationData['inicio'] ?? 'Indefinido'} - ${reservationData['fim'] ?? 'Indefinido'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Espaço: ${reservationData['spaceName'] ?? 'Indefinido'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Usuário: ${reservationData['userName'] ?? 'Desconhecido'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => cancelReservation(
                      reservationId,
                      reservationData['spaceId'],
                      '${reservationData['inicio']} - ${reservationData['fim']}',
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
