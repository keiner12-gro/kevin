import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:harvest/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Harvest Monitoring',
      theme: ThemeData(primarySwatch: Colors.green),
      home: HomeScreen(),
    );
  }
}

Map<String, String> users = {
  'recepcion': '2021',
  'conductor': '2022',
  'bascula': '2023',
  'tolva': '2024',
  'directivos': '2025',
};

List<Map<String, String>> vagones = [];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigateToLogin(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen(role: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Harvest Monitoring')),
      body: GridView.count(
        crossAxisCount: 2,
        children: [
          _buildOption(context, 'Recepción', Icons.add_location, 'recepcion'),
          _buildOption(context, 'Conductor', Icons.local_shipping, 'conductor'),
          _buildOption(context, 'Báscula', Icons.scale, 'bascula'),
          _buildOption(context, 'Tolva', Icons.factory, 'tolva'),
          _buildOption(context, 'Directivos', Icons.bar_chart, 'directivos'),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String title,
    IconData icon,
    String role,
  ) {
    return GestureDetector(
      onTap: () => _navigateToLogin(context, role),
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  String? errorMessage;

  void _login() {
    if (users[widget.role] == _passwordController.text) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => _getScreenForRole(widget.role)),
      );
    } else {
      setState(() {
        errorMessage = 'Contraseña incorrecta';
      });
    }
  }

  Widget _getScreenForRole(String role) {
    switch (role) {
      case 'recepcion':
        return RecepcionScreen();
      case 'conductor':
        return ConductorScreen();
      case 'bascula':
        return BasculaScreen();
      case 'tolva':
        return TolvaScreen();
      case 'directivos':
        return DirectivosScreen();
      default:
        return HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inicio de sesión - ${widget.role}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                errorText: errorMessage,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: Text('Ingresar')),
          ],
        ),
      ),
    );
  }
}

class RecepcionScreen extends StatefulWidget {
  const RecepcionScreen({super.key});

  @override
  _RecepcionScreenState createState() => _RecepcionScreenState();
}

class _RecepcionScreenState extends State<RecepcionScreen> {
  final TextEditingController _origenController = TextEditingController();
  final TextEditingController _destinoController = TextEditingController();

  void _agregarVagon() async {
    if (_origenController.text.isNotEmpty &&
        _destinoController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('vehiculos').add({
        'origen': _origenController.text,
        'destino': _destinoController.text,
        'estado': 'pendiente',
        'fechaAsignacion': FieldValue.serverTimestamp(),
      });

      _origenController.clear();
      _destinoController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recepción')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _origenController,
              decoration: InputDecoration(
                labelText: 'Recoger vagón en (origen)',
              ),
            ),
            TextField(
              controller: _destinoController,
              decoration: InputDecoration(
                labelText: 'Llevar vagón a (destino)',
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _agregarVagon,
              child: Text('Agregar Vagón'),
            ),
            SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('vehiculos')
                      .where('estado', isEqualTo: 'transito')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final enTransito = snapshot.data!.docs.length;

                return Text(
                  'Vagones en tránsito: $enTransito',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                );
              },
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('vehiculos')
                        .orderBy('fechaAsignacion', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();

                  final vagones = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: vagones.length,
                    itemBuilder: (context, index) {
                      final data =
                          vagones[index].data() as Map<String, dynamic>;

                      return ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "🛻 Llevar vagón a: ${data['destino']}",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text("🏗️ Recoger vagón en: ${data['origen']}"),
                          ],
                        ),
                        subtitle: Text("📦 Estado: ${data['estado']}"),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConductorScreen extends StatefulWidget {
  const ConductorScreen({super.key});

  @override
  _ConductorScreenState createState() => _ConductorScreenState();
}

class _ConductorScreenState extends State<ConductorScreen> {
  void _actualizarEstado(String docId, String nuevoEstado) async {
    try {
      await FirebaseFirestore.instance
          .collection('vehiculos')
          .doc(docId)
          .update({'estado': nuevoEstado});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado actualizado: $nuevoEstado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar el estado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conductor')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('vehiculos')
                .orderBy('fechaAsignacion', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No hay vagones disponibles",
                style: TextStyle(fontSize: 20),
              ),
            );
          }

          final vagones = snapshot.data!.docs;

          return ListView.builder(
            itemCount: vagones.length,
            itemBuilder: (context, index) {
              final doc = vagones[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text("🛻 ", style: TextStyle(fontSize: 18)),
                          Expanded(
                            child: Text(
                              "Llevar vagón a: ${data['destino'] ?? 'Sin destino'}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text("🏗️ ", style: TextStyle(fontSize: 18)),
                          Expanded(
                            child: Text(
                              "Recoger vagón en: ${data['origen'] ?? 'Sin origen'}",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text("📦 ", style: TextStyle(fontSize: 18)),
                          Text(
                            "Estado: ${data['estado']}",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.orange,
                              ),
                              tooltip: 'Indicar que va en camino',
                              onPressed:
                                  data['estado'] == "pendiente"
                                      ? () =>
                                          _actualizarEstado(doc.id, "En camino")
                                      : null,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.local_shipping,
                                color: Colors.green,
                              ),
                              tooltip: 'Marcar como recogido',
                              onPressed:
                                  data['estado'] == "En camino"
                                      ? () =>
                                          _actualizarEstado(doc.id, "transito")
                                      : null,
                            ),
                          ],
                        ),
                      ),
                    ],
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

class BasculaScreen extends StatefulWidget {
  const BasculaScreen({super.key});

  @override
  _BasculaScreenState createState() => _BasculaScreenState();
}

class _BasculaScreenState extends State<BasculaScreen> {
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _numeroVagonController = TextEditingController();
  String _tipoFruto = 'Híbrido';

  Future<void> _registrarNuevoVagon() async {
    final numero = _numeroVagonController.text.trim();
    final peso = _pesoController.text.trim();

    if (numero.isEmpty || peso.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('vehiculos').add({
        'numero': numero,
        'peso': peso,
        'tipo': _tipoFruto,
        'estado': 'Pesado',
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vagón registrado correctamente')),
      );

      _numeroVagonController.clear();
      _pesoController.clear();
      setState(() {
        _tipoFruto = 'Híbrido';
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al registrar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báscula')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _numeroVagonController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Número de vagón'),
            ),
            TextField(
              controller: _pesoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Peso en kilogramos',
              ),
            ),
            DropdownButton<String>(
              value: _tipoFruto,
              onChanged: (String? newValue) {
                setState(() {
                  _tipoFruto = newValue!;
                });
              },
              items:
                  ['Híbrido', 'Comercial', 'Mezcla']
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _registrarNuevoVagon,
              child: const Text('Registrar Peso'),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              'Vagones registrados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('vehiculos')
                      .where('estado', isEqualTo: 'Pesado')
                      .orderBy('fechaRegistro', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Text('No hay vagones registrados.');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        title: Text('Vagón: ${data['numero'] ?? 'Sin número'}'),
                        subtitle: Text(
                          'Peso: ${data['peso']} kg | Tipo: ${data['tipo'] ?? 'N/A'}',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TolvaScreen extends StatefulWidget {
  const TolvaScreen({super.key});

  @override
  _TolvaScreenState createState() => _TolvaScreenState();
}

class _TolvaScreenState extends State<TolvaScreen> {
  void _actualizarDestino(String docId, String destino) {
    FirebaseFirestore.instance
        .collection('vehiculos')
        .doc(docId)
        .update({'destino': destino, 'estado': 'Entregado'})
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Destino actualizado: $destino')),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tolva')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('vehiculos')
                .where('estado', whereIn: ['Pesado', 'Transito', 'Entregado'])
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay vagones disponibles."));
          }

          final documentos = snapshot.data!.docs;
          final enTransito =
              documentos
                  .where((doc) => doc.data()['estado'] == 'Transito')
                  .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Vagones en tránsito: ${enTransito.length}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: documentos.length,
                  itemBuilder: (context, index) {
                    final doc = documentos[index];
                    final data = doc.data();
                    final destinoActual = data['destino'] ?? 'Seleccionar';

                    final dropdownItems = [
                      'Seleccionar',
                      'Línea 1',
                      'Línea 2',
                      'Patio',
                    ];
                    final dropdownValue =
                        dropdownItems.contains(destinoActual)
                            ? destinoActual
                            : 'Seleccionar';

                    return Card(
                      child: ListTile(
                        title: Text("Vagón ${data['numero'] ?? 'Desconocido'}"),
                        subtitle: Text(
                          "Estado: ${data['estado']} - Peso: ${data['peso'] ?? 'No registrado'} kg - Tipo: ${data['tipo'] ?? 'No asignado'}",
                        ),
                        trailing: DropdownButton<String>(
                          value: dropdownValue,
                          onChanged: (String? newValue) {
                            if (newValue != null && newValue != 'Seleccionar') {
                              _actualizarDestino(doc.id, newValue);
                            }
                          },
                          items:
                              dropdownItems.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DirectivosScreen extends StatelessWidget {
  const DirectivosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directivos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('vehiculos').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final documentos = snapshot.data!.docs;

          int vagonesEnCamino = 0;
          int vagonesEnBascula = 0;
          Map<String, double> pesosPorDestino = {
            'Línea 1': 0,
            'Línea 2': 0,
            'Patio': 0,
          };

          for (var doc in documentos) {
            final data = doc.data();
            final estado = data['estado'];
            final destino = data['destino'];
            final pesoStr = data['peso'];

            if (estado == 'Vagón recogido') {
              vagonesEnCamino++;
            }
            if (estado == 'En Báscula') {
              vagonesEnBascula++;
            }

            if (destino != null && pesosPorDestino.containsKey(destino)) {
              double peso = double.tryParse(pesoStr.toString()) ?? 0;
              pesosPorDestino[destino] = (pesosPorDestino[destino] ?? 0) + peso;
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📦 Vagones en camino: $vagonesEnCamino',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '⚖️ Vagones en báscula: $vagonesEnBascula',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '🧮 Peso descargado por destino:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('Línea 1: ${pesosPorDestino['Línea 1']} kg'),
                Text('Línea 2: ${pesosPorDestino['Línea 2']} kg'),
                Text('Patio: ${pesosPorDestino['Patio']} kg'),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget _buildScreen(BuildContext context, String title, Widget content) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Padding(padding: const EdgeInsets.all(16.0), child: content),
    bottomNavigationBar: BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.add_location),
          label: 'Recepción',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping),
          label: 'Conductor',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.scale), label: 'Báscula'),
        BottomNavigationBarItem(icon: Icon(Icons.factory), label: 'Tolva'),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Directivos',
        ),
      ],
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => RecepcionScreen()),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ConductorScreen()),
            );
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => BasculaScreen()),
            );
            break;
          case 3:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => TolvaScreen()),
            );
            break;
          case 4:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DirectivosScreen()),
            );
            break;
        }
      },
    ),
  );
}
