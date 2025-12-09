import 'package:supabase_flutter/supabase_flutter.dart';

class BlockService {
  final _sb = Supabase.instance.client;

  Future<int> _myUsuarioId() async {
    final email = _sb.auth.currentUser?.email;
    if (email == null) {
      throw Exception('No hay sesión');
    }
    final me = await _sb
        .from('usuarios')
        .select('id')
        .eq('email', email)
        .maybeSingle();
    if (me == null) {
      throw Exception('Usuario actual no encontrado en tabla usuarios');
    }
    return (me['id'] as num).toInt();
  }

  Future<void> blockUser({required int blockedUsuarioId}) async {
    final myId = await _myUsuarioId();
    try {
      await _sb.from('usuarios_bloqueados').insert({
        'usuario_fk': myId,
        'bloqueado_fk': blockedUsuarioId,
      }, defaultToNull: true);
    } on PostgrestException catch (e) {
      // Si el código de error es 23505 (unique constraint violation), el usuario ya está bloqueado
      if (e.code == '23505') {
        // Ignorar, el usuario ya está bloqueado
        return;
      }
      rethrow;
    }
  }

  Future<void> unblockUser({required int blockedUsuarioId}) async {
    final myId = await _myUsuarioId();
    await _sb.from('usuarios_bloqueados').delete().match({
      'usuario_fk': myId,
      'bloqueado_fk': blockedUsuarioId,
    });
  }
}
