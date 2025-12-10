import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat_model.dart';
import '../widgets/barra_navegacion.dart';
import 'espacio_chat_screen.dart';

class ChatsListScreen extends StatefulWidget {
  final String? paraderoFiltro;

  const ChatsListScreen({super.key, this.paraderoFiltro});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final _chatService = ChatService();
  
  final List<ChatModel> _chats = [];
  final Map<String, int> _participantes = {};
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
    // Si viene con un filtro desde el selector de paraderos, aplicarlo
    if (widget.paraderoFiltro != null) {
      _paraderoSeleccionado = widget.paraderoFiltro;
    }
    _inicializarChats();
  }

  Future<void> _inicializarChats() async {
    try {
      await _chatService.inicializarSistema();
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

      _participantes.clear();
      for (var chat in chats) {
        final numParticipantes = await _chatService.obtenerNumeroParticipantes(chat.id);
        _participantes[chat.id] = numParticipantes;
      }

      setState(() {
        _chats.clear();
        _chats.addAll(chats);
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
        automaticallyImplyLeading: true,
        leading: _paraderoSeleccionado != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtrar por paradero',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                // Mostrar selector con chips para mejor UX
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Chip "Todos"
                      FilterChip(
                        label: const Text('Todos'),
                        selected: _paraderoSeleccionado == null,
                        onSelected: (selected) {
                          setState(() => _paraderoSeleccionado = null);
                          _cargarChats();
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: Colors.blue,
                        labelStyle: TextStyle(
                          color: _paraderoSeleccionado == null
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Chips para cada paradero
                      ..._paraderos.map((paradero) {
                        final isSelected = _paraderoSeleccionado == paradero;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(paradero.split(' - ').last),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(
                                  () => _paraderoSeleccionado = selected ? paradero : null);
                              _cargarChats();
                            },
                            backgroundColor: Colors.grey[200],
                            selectedColor: Colors.blue,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                if (!_isLoading && _chats.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          '${_chats.length} chat${_chats.length != 1 ? 's' : ''} disponible${_chats.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _chats.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _paraderoSeleccionado != null
                                    ? 'No hay chats disponibles en ${_paraderoSeleccionado!.split(' - ').last}'
                                    : 'No hay chats disponibles en este momento',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Intenta más tarde',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
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
                                                  'Personas unidas a una salida: $numParticipantes',
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