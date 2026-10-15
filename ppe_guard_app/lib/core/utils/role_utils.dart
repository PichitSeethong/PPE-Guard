class RoleUtils {
  RoleUtils._();

  static bool canAcknowledge(String role) => role == 'admin' || role == 'supervisor';

  static String thai(String role) {
    switch (role) {
      case 'admin':
        return 'จป. / ผู้ดูแลระบบ';
      case 'supervisor':
        return 'หัวหน้างาน';
      default:
        return 'ผู้ดูข้อมูล';
    }
  }
}
