class AppRoles {
  static const admin = 'admin';
  static const operador = 'operador';

  static String normalize(String role) {
    final value = role.trim().toLowerCase();
    if (value == 'administrador') return admin;
    if (value == admin) return admin;
    return operador;
  }

  static bool isAdmin(String role) => normalize(role) == admin;

  static bool isOperatorOrAdmin(String role) {
    final normalized = normalize(role);
    return normalized == operador || normalized == admin;
  }
}
