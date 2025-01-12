import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SpaceDetailsScreen extends StatefulWidget {
  final String spaceId;

  const SpaceDetailsScreen({
    Key? key,
    required this.spaceId,
  }) : super(key: key);

  @override
  State<SpaceDetailsScreen> createState() => _SpaceDetailsScreenState();
}

class _SpaceDetailsScreenState extends State<SpaceDetailsScreen> {
  String? selectedTime;
  final TextEditingController _peopleController = TextEditingController();
  Map<String, dynamic>? spaceData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSpaceData();
  }

  @override
  void dispose() {
    _peopleController.dispose();
    super.dispose();
  }

  Future<void> _fetchSpaceData() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('spaces')
          .doc(widget.spaceId)
          .get();

      if (snapshot.exists) {
        setState(() {
          spaceData = snapshot.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        _showError('Espaço não encontrado!');
      }
    } catch (e) {
      _showError('Erro ao buscar os dados: $e');
    }
  }

  void _reserveSpace() async {
    if (spaceData == null || !_validateInputs()) return;

    final String reservedTime = selectedTime!;
    final int enteredPeople = int.parse(_peopleController.text);
    final user = FirebaseAuth.instance.currentUser;

    _updateAvailability(reservedTime);

    try {
      await FirebaseFirestore.instance
          .collection('spaces')
          .doc(widget.spaceId)
          .update({
        'availability': spaceData!['availability'],
        'status': spaceData!['status']
      });

      await FirebaseFirestore.instance.collection('reservations').add({
        'spaceId': widget.spaceId,
        'spaceName': spaceData!['name'],
        'inicio': reservedTime.split(' - ')[0],
        'fim': reservedTime.split(' - ')[1],
        'userId': user?.uid,
        'userName': user?.displayName ?? 'Usuário',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _showReservationSuccess(reservedTime, enteredPeople);
    } catch (e) {
      _showError('Erro ao salvar a reserva: $e');
    }
  }

  bool _validateInputs() {
    final int capacity = spaceData!['capacity'];
    final int enteredPeople = int.tryParse(_peopleController.text) ?? 0;

    if (selectedTime == null) {
      _showSnackBar('Selecione um horário disponível!', Colors.red);
      return false;
    }

    if (enteredPeople <= 0) {
      _showSnackBar('Informe uma quantidade válida de pessoas!', Colors.red);
      return false;
    }

    if (enteredPeople > capacity) {
      _showSnackBar(
        'A capacidade máxima do espaço é $capacity pessoas. Reduza o número de pessoas.',
        Colors.red,
      );
      return false;
    }

    return true;
  }

  void _updateAvailability(String reservedTime) {
    setState(() {
      spaceData!['availability']['livres'] = spaceData!['availability']['livres']
          .where((time) => "${time['inicio']} - ${time['fim']}" != reservedTime)
          .toList();

      spaceData!['availability']['ocupados'].add({
        'inicio': reservedTime.split(' - ')[0],
        'fim': reservedTime.split(' - ')[1],
      });

      if (spaceData!['availability']['livres'].isEmpty) {
        spaceData!['status'] = 'inativo';
      }
    });
  }

  void _showReservationSuccess(String reservedTime, int enteredPeople) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reserva Confirmada'),
        content: Text(
          'Reserva feita com sucesso para $enteredPeople pessoa(s) no horário $reservedTime.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (spaceData == null) {
      return const Scaffold(
        body: Center(
          child: Text('Erro ao carregar os dados do espaço.'),
        ),
      );
    }

    final List<dynamic> availableTimes = spaceData!['availability']['livres'];
    final List<String> uniqueAvailableTimes = availableTimes
        .map((time) => "${time['inicio']} - ${time['fim']}")
        .toSet()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Detalhes do ${spaceData!['name']}"),
        backgroundColor: const Color(0xFF5F6F52),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              spaceData!['name'],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text("Horários Disponíveis Hoje:"),
            DropdownButtonFormField<String>(
              value: selectedTime,
              items: uniqueAvailableTimes
                  .map((time) => DropdownMenuItem(
                        value: time,
                        child: Text(time),
                      ))
                  .toList(),
              onChanged: (value) => setState(() {
                selectedTime = value;
              }),
            ),
            const SizedBox(height: 16),
            const Text("Quantidade de Pessoas:"),
            TextField(
              controller: _peopleController,
              decoration: const InputDecoration(
                hintText: 'Digite o número de pessoas',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _reserveSpace,
              child: const Text('Reservar'),
            ),
          ],
        ),
      ),
    );
  }
}
