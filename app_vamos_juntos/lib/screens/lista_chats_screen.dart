import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat_model.dart';
import '../widgets/barra_navegacion.dart';
import 'espacio_chat_screen.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final _chatService = ChatService();
  
  List<ChatModel> _chats = [];
  Map<String, int> _participantes = {}; // No puede ser final porque se modifica
  bool _isLoading = true;
  String? _paraderoSeleccionado;

  final List<String> _paraderos = [
    'PB1559 - Parada 1',
    'PB422 - Parada 2',
    'PB2025 - Parada 3',
    'PB1563 - Parada 4',
  ];

  @override
  void initState() {
    super.initState();
    _inicializarChats();
  }

  Future<void> _inicializarChats() async {
    try {
      // Generar chats del día y cerrar antiguos
      await _chatService.inicializarSistema();
      
      // Cargar chats
      await _cargarChats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _cargarChats() async {
    setState(() => _isLoading = true);
    
    try {
      final chats = await _chatService.obtenerChats(
        paradero: _paraderoSeleccionado,
        soloDisponibles: true,
      );

      // Obtener número de participantes para cada chat
      _participantes.clear();
      for (var chat in chats) {
        final numParticipantes = await _chatService.obtenerNumeroParticipantes(chat.id);
        _participantes[chat.id] = numParticipantes;
      }

      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar chats: $e')),
        );
      }
    }
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.purple,
      Colors.orange,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Chats Públicos',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Filtro de paradero
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona tu paradero',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue.shade800),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: _paraderoSeleccionado,
                    hint: const Text('Todos los paraderos'),
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos los paraderos'),
                      ),
                      ..._paraderos.map((paradero) {
                        return DropdownMenuItem(
                          value: paradero,
                          child: Text(paradero),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _paraderoSeleccionado = value);
                      _cargarChats();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Lista de chats
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _chats.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay chats disponibles',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarChats,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _chats.length,
                          itemBuilder: (context, index) {
                            final chat = _chats[index];
                            final numParticipantes = _participantes[chat.id] ?? 0;
                            final color = _getColorForIndex(index);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  // Validar antes de entrar
                                  if (!chat.estaDisponible) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Este chat ya no está disponible'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatRoomScreen(chat: chat),
                                    ),
                                  ).then((_) => _cargarChats());
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: chat.proximoACerrar ? Colors.orange : color,
                                    borderRadius: BorderRadius.circular(15),
                                    border: chat.proximoACerrar 
                                        ? Border.all(color: Colors.orangeAccent, width: 2)
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        chat.proximoACerrar ? Icons.access_time : Icons.groups,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Chat de ${chat.horarioFormateado}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              chat.paradero,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  'Miembros Unidos: $numParticipantes',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (chat.proximoACerrar) ...[
                                                  const SizedBox(width: 8),
                                                  const Text(
                                                    '⚠️ Por cerrar',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }
}