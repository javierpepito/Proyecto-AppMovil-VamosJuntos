import 'package:flutter/foundation.dart';
import '../main.dart';
import '../models/paradero_model.dart';

class ParaderoService {
  static final ParaderoService _instance = ParaderoService._internal();
  factory ParaderoService() => _instance;
  ParaderoService._internal();

  /// Obtener paradero por código
  Future<ParaderoModel?> obtenerParaderoPorCodigo(String codigo) async {
    try {
      final response = await supabase
          .from('paraderos')
          .select()
          .eq('codigo', codigo)
          .maybeSingle();

      if (response == null) return null;
      return ParaderoModel.fromJson(response);
    } catch (e) {
      debugPrint('Error obteniendo paradero: $e');
      return null;
    }
  }

  /// Obtener micros disponibles para un paradero
  /// Recibe el nombre completo del paradero (ej: "PB1559 - Parada 1")
  Future<List<String>> obtenerMicrosPorParadero(String nombreParadero) async {
    try {
      // Extraer el código del paradero (ej: "PB1559 - Parada 1" -> "PB1559")
      final codigo = nombreParadero.split(' - ').first;
      
      debugPrint('🚏 Buscando micros para paradero: $codigo');
      
      final paradero = await obtenerParaderoPorCodigo(codigo);
      
      if (paradero == null) {
        debugPrint('⚠️ No se encontró el paradero $codigo');
        return [];
      }
      
      debugPrint('✅ Micros encontradas: ${paradero.micros}');
      return paradero.micros;
    } catch (e) {
      debugPrint('❌ Error obteniendo micros: $e');
      return [];
    }
  }

  /// Obtener todos los paraderos
  Future<List<ParaderoModel>> obtenerTodosLosParaderos() async {
    try {
      final response = await supabase
          .from('paraderos')
          .select()
          .order('codigo', ascending: true);

      return (response as List)
          .map((json) => ParaderoModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error obteniendo paraderos: $e');
      return [];
    }
  }
}