// Validadores básicos reutilizables
class Validators {
  static String? requiredText(String? v, {String field = 'Campo'}) {
    if (v == null || v.trim().isEmpty) return '$field requerido';
    return null;
  }

  static String? emailInacap(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email requerido';
    final re = RegExp(r'^[^@\s]+@inacap(mail)?\.cl$');
    if (!re.hasMatch(v.trim())) {
      return 'Usa un correo @inacap.cl o @inacapmail.cl';
    }
    return null;
  }

  static String? nombre(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nombre requerido';
    final re = RegExp(r'^[A-Za-zÁÉÍÓÚÑáéíóúñ ]{2,40}$');
    if (!re.hasMatch(v.trim())) return 'Solo letras, 2–40 caracteres';
    return null;
  }

  static String? telefono(String? v) {
    if (v == null || v.trim().isEmpty) return 'Teléfono requerido';
    final re = RegExp(r'^[0-9]{8,12}$');
    if (!re.hasMatch(v.trim())) return 'Teléfono inválido';
    return null;
  }
}
