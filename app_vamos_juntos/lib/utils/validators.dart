// Validadores básicos reutilizables
class Validators {
  // Requerido con etiqueta opcional
  static String? requiredText(String? v, {String field = 'Campo'}) {
    if (v == null || v.trim().isEmpty) return '$field requerido';
    return null;
  }

  // Correo institucional INACAP
  static String? emailInacap(String? v) {
    if (v == null || v.isEmpty) return 'Email requerido';
    final email = v.trim().toLowerCase();
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!re.hasMatch(email)) return 'Ingresa un correo válido';
    if (!email.endsWith('@inacapmail.cl') && !email.endsWith('@inacap.cl')) {
      return 'Usa un correo @inacap.cl o @inacapmail.cl';
    }
    return null;
  }

  // Nombre solo letras y espacios, mínimo 2 y máximo 40 caracteres
  static String? nombre(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nombre requerido';
    final re = RegExp(r"^[A-Za-zÁáÉéÍíÓóÚúÑñüÜ' ]{2,40}$");
    if (!re.hasMatch(v.trim())) return 'Solo letras y 2–40 caracteres';
    return null;
  }

  // Teléfono chileno simple (empieza con 9, 8 o 7 y 9 dígitos en total), ajusta si necesitas otro formato
  static String? telefono(String? v) {
    if (v == null || v.trim().isEmpty) return 'Teléfono requerido';
    final re = RegExp(r'^[0-9]{8,12}$'); // rango genérico; cambia si tu formato es estricto
    if (!re.hasMatch(v.trim())) return 'Teléfono inválido';
    return null;
  }

  // Contraseña fuerte: mayúscula, número, símbolo y longitud mínima
  static String? passwordStrong(String? v, {int minLen = 12}) {
    if (v == null || v.isEmpty) return 'Contraseña requerida';
    final password = v.trim();

    final hasMinLen = password.length >= minLen;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    // Símbolo: cualquier carácter que NO sea alfanumérico ni espacio
    final hasSymbol = RegExp(r'[^\w\s]').hasMatch(password);

    final missing = <String>[];
    if (!hasMinLen) missing.add('al menos $minLen caracteres');
    if (!hasUpper) missing.add('una mayúscula');
    if (!hasDigit) missing.add('un número');
    if (!hasSymbol) missing.add('un símbolo');

    if (missing.isNotEmpty) {
      return 'La contraseña debe tener ${missing.join(', ')}.';
    }
    return null;
  }

  // Confirmación de contraseña
  static String? passwordConfirm(String? v, String original) {
    if (v == null || v.isEmpty) return 'Confirma tu contraseña';
    if (v != original) return 'Las contraseñas no coinciden';
    return null;
  }
}
