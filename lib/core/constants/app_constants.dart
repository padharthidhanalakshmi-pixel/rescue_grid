/// Branding and fixed text. College details verified from public lbrce.ac.in
/// documents: official name "Lakireddy Bali Reddy College of Engineering
/// (Autonomous)", L.B. Reddy Nagar, Mylavaram, NTR Dist., A.P. 521 230.
class Brand {
  Brand._();
  static const appName = 'RescueGrid';
  static const subtitle = 'LBRCE Campus Emergency Response System';
  static const collegeShort = 'LBRCE';
  static const collegeName = 'Lakireddy Bali Reddy College of Engineering';
  static const collegeAddress =
      'L.B. Reddy Nagar, Mylavaram, NTR District, Andhra Pradesh – 521 230';
  static const region = 'Andhra Pradesh, India';
  static const footer = 'RescueGrid • Lakireddy Bali Reddy College of Engineering';
  static const adminTitle = 'LBRCE Emergency Operations Administrator';
  static const commandCenter = 'LBRCE COMMAND CENTER';
}

class Env {
  Env._();
  static const backend = String.fromEnvironment('RG_BACKEND', defaultValue: 'demo');
  static const mapsKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static bool get firebaseRequested => backend == 'firebase';
}

class DemoAccount {
  const DemoAccount(this.label, this.email, this.password);
  final String label;
  final String email;
  final String password;
}

class DemoCredentials {
  DemoCredentials._();
  static const studentPassword = 'Student@123';
  static const responderPassword = 'Rescue@123';
  static const adminPassword = 'Admin@123';

  static const admin = DemoAccount('ADMIN', 'admin@rescuegrid.demo', adminPassword);
  static final responders = List<DemoAccount>.generate(
    5,
    (i) => DemoAccount('RESPONDER ${i + 1}', 'responder${i + 1}@rescuegrid.demo', responderPassword),
  );
  static final students = List<DemoAccount>.generate(10, (i) {
    final n = (i + 1).toString().padLeft(2, '0');
    return DemoAccount('STUDENT $n', 'student$n@rescuegrid.demo', studentPassword);
  });
}
