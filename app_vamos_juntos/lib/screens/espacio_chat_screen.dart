import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_model.dart';
import '../models/mensaje.model.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import 'lista_salidas_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatModel chat;

  const ChatRoomScreen({super.key, required this.chat});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _chatService = ChatService();
  final _authService = AuthService();
  final _mensajeController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<MensajeModel> _mensajes = [];
  bool _isLoading = true;
  bool _enviando = false;
  RealtimeChannel? _channel;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _authService.usuarioActual?.id;
    _inicializar();
  }

  Future<void> _inicializar() async {
    try {
      // Verificar que el chat esté disponible
      if (!widget.chat.estaDisponible) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Este chat ya no está disponible')),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Unirse al chat
      if (_currentUserId != null) {
        await _chatService.unirseAChat(widget.chat.id, _currentUserId!);
      }

      // Cargar mensajes
      await _cargarMensajes();

      // Suscribirse a nuevos mensajes
      _suscribirseAMensajes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _cargarMensajes() async {
    try {
      final mensajes = await _chatService.obtenerMensajes(widget.chat.id);
      setState(() {
        _mensajes = mensajes;
        _isLoading = false;
      });

      // Scroll al final
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _suscribirseAMensajes() {
    _channel = _chatService.suscribirseAMensajes(
      widget.chat.id,
      (mensaje) {
        setState(() {
          _mensajes.add(mensaje);
        });

        // Scroll al final
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      },
    );
  }

  Future<void> _enviarMensaje() async {
    if (_mensajeController.text.trim().isEmpty || _currentUserId == null) return;

    setState(() => _enviando = true);

    try {
      await _chatService.enviarMensaje(
        chatId: widget.chat.id,
        usuarioId: _currentUserId!,
        contenido: _mensajeController.text,
      );

      _mensajeController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar: $e')),
        );
      }
    } finally {
      setState(() => _enviando = false);
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _mensajeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat ${widget.chat.horarioFormateado}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              widget.chat.paradero,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SalidasListScreen(chat: widget.chat),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Salidas Grupales',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    
      body: Column(
        children: [
          // Banner de advertencia si está por cerrar
          if (widget.chat.proximoACerrar)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange,
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ Este chat cerrará pronto',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Lista de mensajes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _mensajes.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay mensajes aún.\n¡Sé el primero en escribir!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _mensajes.length,
                        itemBuilder: (context, index) {
                          final mensaje = _mensajes[index];
                          final esMio = mensaje.esMio(_currentUserId ?? '');

                          return Align(
                            alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: BoxDecoration(
                                color: esMio ? Colors.blue.shade800 : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!esMio)
                                    Text(
                                      mensaje.usuario?.nombreCompleto ?? 'Usuario',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  if (!esMio) const SizedBox(height: 4),
                                  Text(
                                    mensaje.contenido,
                                    style: TextStyle(
                                      color: esMio ? Colors.white : Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    mensaje.horaFormateada,
                                    style: TextStyle(
                                      color: esMio ? Colors.white70 : Colors.black54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Campo de entrada
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _enviarMensaje(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue.shade800,
                  child: IconButton(
                    icon: _enviando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _enviando ? null : _enviarMensaje,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}