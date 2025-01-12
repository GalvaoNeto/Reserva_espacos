import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SpacesListScreen extends StatelessWidget {
  final Function(Map<String, dynamic>, String) onSpaceDetails;
  final VoidCallback onViewReservations;

  const SpacesListScreen({
    Key? key,
    required this.onSpaceDetails,
    required this.onViewReservations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Espaços'),
        backgroundColor: const Color(0xFF5F6F52),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: onViewReservations, 
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('spaces').snapshots(), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar os espaços.'));
          }

          final spaces = snapshot.data?.docs ?? [];

          if (spaces.isEmpty) {
            return const Center(child: Text('Nenhum espaço disponível.'));
          }

          return ListView.builder(
            itemCount: spaces.length,
            itemBuilder: (context, index) {
              final spaceData = spaces[index].data() as Map<String, dynamic>;
              final docId = spaces[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(
                    spaceData['name'] ?? 'Espaço sem nome',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Status: ${spaceData['status'] == 'ativo' ? 'Ativo' : 'Inativo'}\n'
                    'Capacidade: ${spaceData['capacity']} pessoas',
                    style: TextStyle(
                      color: spaceData['status'] == 'ativo' ? Colors.green : Colors.red,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: spaceData['status'] == 'ativo'
                      ? () {
                          onSpaceDetails(spaceData, docId);
                        }
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${spaceData['name']} está inativo no momento.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
